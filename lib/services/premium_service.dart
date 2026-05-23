import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'firebase_service.dart';

/// FiyatRadar Pro abonelik / IAP yönetimi.
///
/// Sorumluluk:
///   • Play Billing / StoreKit'ten ürün listesini çek (`queryProductDetails`).
///   • Kullanıcı satın alır → purchase stream üzerinden `pendingPurchases`
///     değerini Firestore'a yaz: `purchaseQueue/{uid}_{purchaseId}`. Cloud
///     Function tarafı Google Play Developer API ile doğrular ve
///     `users/{uid}.isPremium = true`, `premiumUntil = expiry` yazar.
///   • Restore akışı: kullanıcı yeni cihaz / yeniden kurulum durumunda
///     `restorePurchases()` çağırır; aynı queue'ya restore record yazılır.
///
/// İstemci ASLA `users/{uid}.isPremium`'u kendisi yazmaz — Firestore rules
/// `immutable('isPremium')` ile bunu zorlar (firestore.rules:147+). Tek
/// otorite Cloud Function (admin SDK).
///
/// `ChangeNotifier` — paywall ekranı ürün yükleme durumu değiştikçe
/// (loading → loaded / error) reactive olarak rebuild eder.
class PremiumService extends ChangeNotifier {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  /// Play Console + App Store Connect'te oluşturulan SKU id'leri.
  /// `fr_pro_monthly` aylık, `fr_pro_yearly` yıllık. Üretimde Console'da
  /// aynı id'lerle ürünleri tanımlamak gerek; SKU değişirse buradaki
  /// constant da güncellenmeli.
  static const String monthlySku = 'fr_pro_monthly';
  static const String yearlySku = 'fr_pro_yearly';
  static const Set<String> kProductIds = {monthlySku, yearlySku};

  final InAppPurchase _iap = InAppPurchase.instance;
  final FirebaseService _svc = FirebaseService.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  bool _initialized = false;
  List<ProductDetails> _availableProducts = const [];
  List<ProductDetails> get availableProducts => _availableProducts;

  /// `available` durumu app açılışından sonra `init()` döndürür. Üretimde
  /// Play Billing ile bağlanılamadığında (örn. iOS'ta cihaz, ya da Play
  /// Store yok edilmiş cihaz) UI Pro CTA'sını gizleyebilir.
  bool _available = false;
  bool get available => _available;

  /// Ürün listesi şu an Play Billing'ten yükleniyor mu.
  bool _loadingProducts = false;
  bool get loadingProducts => _loadingProducts;

  /// Sonuncu ürün yükleme denemesi tamamlandı mı (başarılı veya başarısız).
  /// `false` → daha hiç denenmedi (init henüz çağrılmadı / çalışıyor).
  bool _productsQueried = false;
  bool get productsQueried => _productsQueried;

  /// Ürün yükleme hatası (kullanıcıya gösterilebilir Türkçe mesaj). `null`
  /// → hata yok. Mağaza mevcut değilse de bu set edilir.
  String? _productsError;
  String? get productsError => _productsError;

  /// Aylık plan için Play Console'dan dönen ProductDetails, varsa.
  ProductDetails? get monthlyProduct {
    for (final p in _availableProducts) {
      if (p.id == monthlySku) return p;
    }
    return null;
  }

  /// Yıllık plan için Play Console'dan dönen ProductDetails, varsa.
  ProductDetails? get yearlyProduct {
    for (final p in _availableProducts) {
      if (p.id == yearlySku) return p;
    }
    return null;
  }

  /// Satın alınabilir en az bir SKU var mı (CTA enable/disable için).
  bool get hasPurchasableProducts =>
      _available && _availableProducts.isNotEmpty;

  /// IAP altyapısını ayağa kaldır + ürün listesini çek + purchase stream'i
  /// dinle. Idempotent — birden fazla `init()` çağrısı no-op.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _loadingProducts = true;
    notifyListeners();
    try {
      _available = await _iap.isAvailable();
    } catch (e) {
      debugPrint('PremiumService.isAvailable failed: $e');
      _available = false;
    }
    if (!_available) {
      _loadingProducts = false;
      _productsQueried = true;
      _productsError =
          'Mağaza bağlantısı kullanılamıyor. Play Store hesabını kontrol et.';
      notifyListeners();
      return;
    }

    await _queryProducts();

    _purchaseSub = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _purchaseSub?.cancel(),
      onError: (Object e) =>
          debugPrint('PremiumService purchaseStream error: $e'),
    );
  }

  /// Ürün listesini yeniden Play Billing'ten çeker. Paywall ekranındaki
  /// "Tekrar dene" butonu bunu çağırır.
  Future<void> reloadProducts() async {
    if (!_initialized) {
      await init();
      return;
    }
    if (_loadingProducts) return;
    try {
      _available = await _iap.isAvailable();
    } catch (e) {
      debugPrint('PremiumService.isAvailable failed: $e');
      _available = false;
    }
    if (!_available) {
      _productsQueried = true;
      _productsError =
          'Mağaza bağlantısı kullanılamıyor. Play Store hesabını kontrol et.';
      notifyListeners();
      return;
    }
    await _queryProducts();
  }

  Future<void> _queryProducts() async {
    _loadingProducts = true;
    _productsError = null;
    notifyListeners();
    try {
      final resp = await _iap.queryProductDetails(kProductIds);
      _availableProducts = resp.productDetails;
      if (resp.error != null) {
        debugPrint('PremiumService queryProductDetails error: ${resp.error}');
        _productsError =
            'Ürünler yüklenemedi: ${resp.error!.message}. İnternet bağlantını kontrol et.';
      } else if (resp.notFoundIDs.isNotEmpty &&
          _availableProducts.isEmpty) {
        debugPrint('Premium SKU bulunamadı: ${resp.notFoundIDs}');
        _productsError =
            'Abonelik ürünleri Play Store\'da henüz yayında değil. Birkaç dakika sonra tekrar dene.';
      } else if (resp.notFoundIDs.isNotEmpty) {
        debugPrint('Premium SKU kısmen bulunamadı: ${resp.notFoundIDs}');
      }
    } catch (e) {
      debugPrint('PremiumService.queryProductDetails failed: $e');
      _productsError =
          'Ürünler yüklenemedi, internet bağlantını kontrol et.';
    } finally {
      _loadingProducts = false;
      _productsQueried = true;
      notifyListeners();
    }
  }

  /// Aylık veya yıllık satın alma başlat. Auto-renewing subscription olarak
  /// yapılandırıldığı için `buyNonConsumable` kullanıyoruz; consumable
  /// olsaydı Play Billing acknowledge yapmazdı.
  Future<bool> purchase(ProductDetails product) async {
    if (!_available) return false;
    final purchaseParam = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Yeni cihaz / yeniden kurulum sonrası kullanıcının var olan
  /// abonelik geçmişini geri yükler. Cloud Function aynı doğrulama
  /// pipeline'ında çalışacağı için sonuç user doc'a yansır.
  Future<void> restore() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          // Pending → kullanıcıya UI'da "doğrulanıyor" gösterilebilir.
          // Veri yine queue'ya yazılmaz; finalize'e kadar bekleyelim.
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _enqueueForServerVerification(uid, p);
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;
        case PurchaseStatus.error:
          debugPrint('Premium purchase error: ${p.error}');
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;
        case PurchaseStatus.canceled:
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
          break;
      }
    }
  }

  /// Cloud Function tarafına doğrulanması için pending kuyruğa yazıyoruz.
  /// Function Play Developer API ile token doğrular, sonra
  /// `users/{uid}.isPremium = true` yazar. Doc id deterministik:
  /// `${uid}_${productId}_${purchaseId}` — aynı transaction tekrar gelirse
  /// idempotent kalsın.
  Future<void> _enqueueForServerVerification(
    String uid,
    PurchaseDetails p,
  ) async {
    final productId = p.productID;
    final purchaseId = p.purchaseID ?? '';
    final docId = '${uid}_${productId}_${purchaseId.isNotEmpty ? purchaseId : DateTime.now().millisecondsSinceEpoch}';
    try {
      await _svc.db
          .collection('purchaseQueue')
          .doc(docId)
          .set({
        'userId': uid,
        'productId': productId,
        'purchaseId': purchaseId,
        'platform': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
        // Play Billing için verificationData.serverVerificationData purchase
        // token'ını içeriyor; iOS için receipt data. Function tarafı
        // platforma göre farklı doğrulama yapar.
        'verificationData': p.verificationData.serverVerificationData,
        'transactionDate': p.transactionDate,
        'status': p.status.name,
        'createdAt': FieldValue.serverTimestamp(),
        'consumed': false,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('purchaseQueue write failed: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    _purchaseSub = null;
    _initialized = false;
    super.dispose();
  }
}

/// Premium snapshot — `AppState.premium` getter'ından dönen value type.
class PremiumStatus {
  final bool isActive;
  final DateTime? until;
  final String? plan;

  const PremiumStatus({
    required this.isActive,
    required this.until,
    required this.plan,
  });

  static const inactive =
      PremiumStatus(isActive: false, until: null, plan: null);

  String get planLabel {
    if (!isActive) return 'Ücretsiz';
    if (plan == PremiumService.yearlySku) return 'Pro · Yıllık';
    if (plan == PremiumService.monthlySku) return 'Pro · Aylık';
    return 'Pro';
  }

  Duration? get remaining {
    if (!isActive || until == null) return null;
    final now = DateTime.now();
    final diff = until!.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }
}
