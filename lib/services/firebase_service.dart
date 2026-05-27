import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/price_v1.dart';

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class LegacyStoreMigrationResult {
  final int processed;
  final int migrated;
  final int updated;
  final int skippedMissingRegion;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> missingRegionDocs;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;

  const LegacyStoreMigrationResult({
    required this.processed,
    required this.migrated,
    required this.updated,
    required this.skippedMissingRegion,
    required this.missingRegionDocs,
    required this.lastDoc,
    required this.hasMore,
  });
}

/// Central Firebase access and one-time bootstrap of required collections.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  /// Upload a product image to Storage under `product_images/{productId}/…`.
  /// Returns `(downloadUrl, storagePath)` so the product doc can store both
  /// (URL for display, path for future replacement / cleanup).
  Future<({String url, String path})> uploadProductImage({
    required String productId,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final detected = _detectImageType(bytes, fallback: contentType);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = 'product_images/$productId/$ts.${detected.extension}';
    final ref = storage.ref(path);
    final snap = await ref.putData(
      bytes,
      SettableMetadata(
        contentType: detected.contentType,
        cacheControl: 'public, max-age=86400',
      ),
    );
    final url = await snap.ref.getDownloadURL();
    return (url: url, path: path);
  }

  /// Upload a user profile image under `user_profiles/{uid}/…`.
  ///
  /// The image bytes can be JPEG / PNG / WEBP — the actual format is detected
  /// from the magic bytes so the wrong `Content-Type` (which used to break
  /// uploads on iOS HEIC pickers) doesn't reach Storage. The auth token is
  /// refreshed first so a stale anonymous-→-Google upgrade doesn't surface
  /// as `[firebase_storage/unknown]`.
  Future<({String url, String path})> uploadUserProfileImage({
    required String uid,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final current = auth.currentUser;
    if (current == null || current.uid != uid) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'unauthenticated',
        message: 'Yükleme için tekrar giriş yapman gerekiyor.',
      );
    }
    try {
      await current.getIdToken(true);
    } catch (_) {
      // Token refresh is best-effort; upload will surface a clearer error.
    }
    if (bytes.length > 5 * 1024 * 1024) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'image-too-large',
        message: 'Profil fotoğrafı 5 MB üstünde, daha küçük bir dosya seç.',
      );
    }
    final detected = _detectImageType(bytes, fallback: contentType);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = 'user_profiles/$uid/$ts.${detected.extension}';
    final ref = storage.ref(path);
    debugPrint(
      '[profile-image-upload] storage path=$path bucket=${storage.bucket} '
      'contentType=${detected.contentType} bytes=${bytes.length} '
      'authUid=${current.uid} authEmail=${current.email}',
    );
    try {
      final snap = await ref.putData(
        bytes,
        SettableMetadata(
          contentType: detected.contentType,
          cacheControl: 'public, max-age=86400',
        ),
      );
      final url = await snap.ref.getDownloadURL();
      return (url: url, path: path);
    } on FirebaseException catch (e, st) {
      debugPrint(
        '[profile-image-upload] FirebaseException plugin=${e.plugin} '
        'code=${e.code} message=${e.message} stackTrace=$st',
      );
      debugPrintStack(label: '[profile-image-upload]', stackTrace: st);
      rethrow;
    }
  }

  /// Upload a community-submitted product photo under
  /// `product_image_submissions/{uid}/{ts}.{ext}`. Storage rules restrict
  /// writes to the owning user (matching uid path segment) so only that
  /// user can add files into their own pending submissions folder. Admin
  /// approval copies the bytes into the canonical `product_images/...`
  /// path before flipping the doc status to `approved`.
  Future<({String url, String path})> uploadProductImageSubmission({
    required String uid,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final current = auth.currentUser;
    if (current == null || current.uid != uid) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'unauthenticated',
        message: 'Fotoğraf yüklemek için tekrar giriş yapman gerekiyor.',
      );
    }
    if (bytes.length > 6 * 1024 * 1024) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'image-too-large',
        message: 'Fotoğraf 6 MB üstünde, daha küçük bir dosya seç.',
      );
    }
    final detected = _detectImageType(bytes, fallback: contentType);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path =
        'product_image_submissions/$uid/$ts.${detected.extension}';
    final ref = storage.ref(path);
    final snap = await ref.putData(
      bytes,
      SettableMetadata(
        contentType: detected.contentType,
        cacheControl: 'public, max-age=86400',
      ),
    );
    final url = await snap.ref.getDownloadURL();
    return (url: url, path: path);
  }

  /// Upload a banner hero image under `banner_images/{bannerId}/…`.
  Future<({String url, String path})> uploadBannerImage({
    required String bannerId,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final detected = _detectImageType(bytes, fallback: contentType);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = 'banner_images/$bannerId/$ts.${detected.extension}';
    final ref = storage.ref(path);
    final snap = await ref.putData(
      bytes,
      SettableMetadata(
        contentType: detected.contentType,
        cacheControl: 'public, max-age=86400',
      ),
    );
    final url = await snap.ref.getDownloadURL();
    return (url: url, path: path);
  }

  /// Upload a price-proof photo under `price_proofs/{uid}/…`.
  ///
  /// Storage rules (`storage.rules` `match /price_proofs/{uid}/{file=**}`)
  /// only allow the owner to write — so the uid path segment must equal
  /// `auth.currentUser.uid`. Returns the public download URL + storage path
  /// so the price report can stash both for inline rendering and admin
  /// cleanup later.
  Future<({String url, String path})> uploadPriceProofImage({
    required String uid,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final current = auth.currentUser;
    if (current == null || current.uid != uid) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'unauthenticated',
        message: 'Fotoğraf yüklemek için tekrar giriş yapman gerekiyor.',
      );
    }
    if (bytes.length > 5 * 1024 * 1024) {
      throw FirebaseException(
        plugin: 'firebase_storage',
        code: 'image-too-large',
        message: 'Fotoğraf 5 MB üstünde, daha küçük bir dosya seç.',
      );
    }
    final detected = _detectImageType(bytes, fallback: contentType);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = 'price_proofs/$uid/$ts.${detected.extension}';
    final ref = storage.ref(path);
    final snap = await ref.putData(
      bytes,
      SettableMetadata(
        contentType: detected.contentType,
        cacheControl: 'public, max-age=86400',
      ),
    );
    final url = await snap.ref.getDownloadURL();
    return (url: url, path: path);
  }

  ({String contentType, String extension}) _detectImageType(
    Uint8List bytes, {
    String? fallback,
  }) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return (contentType: 'image/jpeg', extension: 'jpg');
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return (contentType: 'image/png', extension: 'png');
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return (contentType: 'image/webp', extension: 'webp');
    }
    if (fallback == 'image/png') return (contentType: 'image/png', extension: 'png');
    if (fallback == 'image/webp') return (contentType: 'image/webp', extension: 'webp');
    return (contentType: 'image/jpeg', extension: 'jpg');
  }

  Future<void> deleteStorageFile(String path) async {
    if (path.isEmpty) return;
    try {
      await storage.ref(path).delete();
    } catch (_) {
      // Swallow — image may already be gone or unreadable; not critical.
    }
  }

  @Deprecated('Use deleteStorageFile(path) instead.')
  Future<void> deleteProductImage(String path) => deleteStorageFile(path);

  CollectionReference<Map<String, dynamic>> get products =>
      db.collection('products');
  CollectionReference<Map<String, dynamic>> get banners =>
      db.collection('banners');

  CollectionReference<Map<String, dynamic>> get stores =>
      db.collection('stores');
  CollectionReference<Map<String, dynamic>> get storeChains =>
      db.collection('store_chains');
  CollectionReference<Map<String, dynamic>> get storePlaces =>
      db.collection('store_places');
  CollectionReference<Map<String, dynamic>> get priceEntries =>
      db.collection('price_entries');
  CollectionReference<Map<String, dynamic>> get priceSummaries =>
      db.collection('price_summaries');
  CollectionReference<Map<String, dynamic>> get priceReports =>
      db.collection('priceReports');
  CollectionReference<Map<String, dynamic>> get priceGroups =>
      db.collection('priceGroups');
  CollectionReference<Map<String, dynamic>> get priceDedupes =>
      db.collection('priceReportDedupes');

  CollectionReference<Map<String, dynamic>> get categories =>
      db.collection('categories');
  CollectionReference<Map<String, dynamic>> get users =>
      db.collection('users');
  CollectionReference<Map<String, dynamic>> get comments =>
      db.collection('comments');

  /// Benzersiz kullanıcı adı rezervasyon collection'ı. Doc id'si normalize
  /// edilmiş takma ad (lowercase, @ ve boşluk yok), payload `{ uid }`.
  /// Rules: aynı uid'li olan kullanıcı kendi rezervasyonunu silebilir;
  /// yeni rezervasyon yalnız doc yoksa ve `request.resource.data.uid ==
  /// request.auth.uid` ise oluşturulabilir.
  CollectionReference<Map<String, dynamic>> get usernames =>
      db.collection('usernames');

  /// `@user_handle` veya `user_handle` formatını rezervasyon doc id'sine
  /// dönüştürür. Trim + lowercase + `@` ön ekinin temizlenmesi.
  static String normalizeUsername(String raw) {
    final trimmed = raw.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    return trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
  }

  /// Sadece harf/rakam/altçizgi + 3-20 karakter, başı/sonu altçizgi değil.
  static bool isValidUsernameHandle(String raw) {
    final handle = normalizeUsername(raw);
    if (handle.length < 3 || handle.length > 20) return false;
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(handle)) return false;
    if (handle.startsWith('_') || handle.endsWith('_')) return false;
    return true;
  }

  /// Username uygun ve müsaitse rezerve eder. Müsait değilse [StateError]
  /// fırlatır. Kullanıcı önceki bir handle tutuyorsa [previousHandle]
  /// verilirse rezervasyon transaction sonunda eski doc silinir.
  Future<void> reserveUsername({
    required String uid,
    required String desiredHandle,
    String? previousHandle,
  }) async {
    final normalized = normalizeUsername(desiredHandle);
    if (!isValidUsernameHandle(normalized)) {
      throw StateError(
        'Kullanıcı adı 3-20 karakter, sadece harf/rakam/_, başı/sonu _ olamaz.',
      );
    }
    final prevNormalized = normalizeUsername(previousHandle ?? '');
    if (prevNormalized == normalized) return;
    final newRef = usernames.doc(normalized);
    final prevRef =
        prevNormalized.isEmpty ? null : usernames.doc(prevNormalized);
    await db.runTransaction((tx) async {
      final newSnap = await tx.get(newRef);
      if (newSnap.exists) {
        final existingUid = (newSnap.data()?['uid'] as String?) ?? '';
        if (existingUid != uid) {
          throw StateError('Bu kullanıcı adı zaten alınmış.');
        }
        // Aynı kullanıcı tekrar reserve ediyorsa no-op.
        return;
      }
      tx.set(newRef, {
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (prevRef != null) {
        final prevSnap = await tx.get(prevRef);
        if (prevSnap.exists &&
            (prevSnap.data()?['uid'] as String?) == uid) {
          tx.delete(prevRef);
        }
      }
    });
  }

  /// Hesap silme akışında veya logout sonrası temizlik için.
  Future<void> releaseUsername({
    required String uid,
    required String handle,
  }) async {
    final normalized = normalizeUsername(handle);
    if (normalized.isEmpty) return;
    final ref = usernames.doc(normalized);
    try {
      final snap = await ref.get();
      if (!snap.exists) return;
      if ((snap.data()?['uid'] as String?) != uid) return;
      await ref.delete();
    } catch (_) {
      // Best-effort: silinemezse rules zaten korur.
    }
  }

  /// Community-sourced product additions awaiting admin approval.
  CollectionReference<Map<String, dynamic>> get productRequests =>
      db.collection('product_requests');

  /// Community-sourced product photos awaiting admin approval. On approval
  /// the admin promotes the submitted Storage object to the canonical
  /// `product_images/{productId}/...` path and points `products.imageUrl`
  /// at it.
  CollectionReference<Map<String, dynamic>> get productImageSubmissions =>
      db.collection('product_image_submissions');

  DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      users.doc(uid);

  CollectionReference<Map<String, dynamic>> userNotifications(String uid) =>
      users.doc(uid).collection('notifications');

  CollectionReference<Map<String, dynamic>> userProductAlerts(String uid) =>
      users.doc(uid).collection('productAlerts');

  Future<User> ensureSignedIn() async {
    final cur = auth.currentUser;
    if (cur != null) return cur;
    final cred = await auth.signInAnonymously();
    return cred.user!;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
    String? username,
  }) async {
    final cleanUsername = (username ?? '').trim();
    final normalizedHandle = normalizeUsername(cleanUsername);
    if (normalizedHandle.isNotEmpty &&
        !isValidUsernameHandle(normalizedHandle)) {
      throw FirebaseAuthException(
        code: 'invalid-username',
        message: 'Kullanıcı adı 3-20 karakter, sadece harf/rakam/_ olabilir.',
      );
    }
    final cred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final trimmedName = displayName?.trim() ?? '';
    if (trimmedName.isNotEmpty) {
      await cred.user?.updateDisplayName(trimmedName);
    }
    final uid = cred.user?.uid;
    if (uid != null && uid.isNotEmpty && normalizedHandle.isNotEmpty) {
      try {
        await reserveUsername(uid: uid, desiredHandle: normalizedHandle);
      } on StateError catch (e) {
        // Rezervasyon başarısızsa az önce yarattığımız auth account'ı geri
        // alalım, aksi halde kullanıcı orphan oluyor.
        try {
          await cred.user?.delete();
        } catch (_) {}
        throw FirebaseAuthException(
          code: 'username-taken',
          message: e.message,
        );
      }
    }
    if (uid != null && uid.isNotEmpty) {
      await userDoc(uid).set({
        if (trimmedName.isNotEmpty) 'displayName': trimmedName,
        if (normalizedHandle.isNotEmpty) 'username': '@$normalizedHandle',
        if (normalizedHandle.isNotEmpty) 'usernameHandle': normalizedHandle,
        // Yeni e-posta/şifre hesabı doğrulanmamış halde başlar — Cloud
        // Function / başka istemciden geç senkronizasyon gelene kadar bu
        // alan false kalır.
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    // Kayıt akışının son adımı: doğrulama maili — SADECE BİR KEZ burada
    // gönderilir. Uygulama açılışında otomatik tekrar gönderilmez; kullanıcı
    // `VerifyEmailScreen`'den cooldown'lu "tekrar gönder" ile tetikler.
    // Network hatası kaydı iptal etmesin.
    try {
      // Mail dilini Türkçe'ye zorla (Firebase default şablonu; gövde
      // özelleştirilemez ama dil mümkünse Türkçe gelir).
      await auth.setLanguageCode('tr');
      await cred.user?.sendEmailVerification();
    } catch (e, st) {
      debugPrint('[register] sendEmailVerification failed: $e\n$st');
    }
    return cred;
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google girişi iptal edildi.',
      );
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await auth.signInWithCredential(credential);
    final uid = cred.user?.uid;
    if (uid != null && uid.isNotEmpty) {
      final displayName = cred.user?.displayName?.trim() ?? '';
      final email = cred.user?.email?.trim() ?? '';
      // Sadece YENİ kullanıcılarda username seed et — mevcut hesabın elle
      // değiştirdiği username'i ezmeyelim.
      final existing = await userDoc(uid).get();
      final hasUsername =
          (existing.data()?['username'] as String?)?.trim().isNotEmpty == true;
      if (!hasUsername) {
        final base = (email.contains('@')
                ? email.split('@').first
                : (displayName.isNotEmpty ? displayName : 'fiyatradar_user'))
            .replaceAll(RegExp(r'\s+'), '_')
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9_]'), '');
        final reservedHandle = await _findAvailableUsernameHandle(
          uid: uid,
          base: base.isEmpty ? 'fiyatradar_user' : base,
        );
        await userDoc(uid).set({
          if (displayName.isNotEmpty) 'displayName': displayName,
          'username': '@$reservedHandle',
          'usernameHandle': reservedHandle,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else if (displayName.isNotEmpty) {
        await userDoc(uid).set({
          'displayName': displayName,
        }, SetOptions(merge: true));
      }
    }
    return cred;
  }

  /// Google ile ilk girişte boş bir handle için çakışmasız bir varyant bul ve
  /// rezerve et. `base`, `base_2`, `base_3` ... şeklinde dener.
  Future<String> _findAvailableUsernameHandle({
    required String uid,
    required String base,
  }) async {
    var candidate = base;
    if (!isValidUsernameHandle(candidate)) candidate = 'fiyatradar_user';
    for (var i = 0; i < 50; i++) {
      final tryHandle = i == 0 ? candidate : '${candidate}_${i + 1}';
      try {
        await reserveUsername(uid: uid, desiredHandle: tryHandle);
        return tryHandle;
      } on StateError {
        continue;
      }
    }
    // Son çare: uid suffix ile garanti unique handle.
    final fallback = '${candidate.substring(0, candidate.length.clamp(0, 12))}'
        '_${uid.substring(0, uid.length.clamp(0, 6))}';
    await reserveUsername(uid: uid, desiredHandle: fallback);
    return fallback;
  }

  Future<void> sendPasswordReset(String email) async {
    // Şifre sıfırlama mailini Türkçe diliyle gönder (Firebase default şablonu).
    await auth.setLanguageCode('tr');
    await auth.sendPasswordResetEmail(email: email);
  }

  /// Seeds Firestore collections on first launch so the app is never empty.
  /// After first run, all data is sourced from Firestore. Each seed runs
  /// independently so a permission-denied (non-admin) write on one collection
  /// doesn't block the rest of the bootstrap.
  Future<void> bootstrap() async {
    await _runSeed(_seedProducts);
    await _runSeed(_seedBanners);
    await _runSeed(_seedStores);
    await _runSeed(_seedCategories);
  }

  Future<void> _runSeed(Future<void> Function() seed) async {
    try {
      await seed();
    } catch (_) {
      // Non-admin sessions can't seed; swallow so bootstrap finishes.
    }
  }

  Future<void> _seedStores() async {
    final coll = db.collection('stores');
    final snap = await coll.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final batch = db.batch();
    const items = [
      {'name': 'A101', 'order': 1},
      {'name': 'BİM', 'order': 2},
      {'name': 'ŞOK', 'order': 3},
      {'name': 'Migros', 'order': 4},
      {'name': 'CarrefourSA', 'order': 5},
      {'name': 'Tarım Kredi', 'order': 6},
    ];
    for (final it in items) {
      batch.set(coll.doc(), {
        'name': it['name'],
        'order': it['order'],
        'isActive': true,
      });
    }
    await batch.commit();
  }


  Future<void> seedDefaultOnlinePlaces() async {
    const names = [
      'Migros Online',
      'CarrefourSA Online',
      'Getir',
      'Trendyol Market',
      'Yemeksepeti Market',
    ];
    final coll = storePlaces;
    final existing = await coll
        .where('type', isEqualTo: 'online_market')
        .where('isActive', isEqualTo: true)
        .limit(10)
        .get();
    if (existing.docs.isNotEmpty) return;
    final batch = db.batch();
    for (final name in names) {
      final norm = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final ref = coll.doc();
      batch.set(ref, {
        'chainId': null,
        'chainName': null,
        'type': 'online_market',
        'sourceType': 'online',
        'channel': 'online',
        'displayName': name,
        'normalizedName': norm,
        'city': '',
        'district': '',
        'status': 'verified',
        'isActive': true,
        'usageCount': 0,
        'createdByUid': 'system_bootstrap',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  String normalizePlaceName(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Future<LegacyStoreMigrationResult> migrateLegacyStoresToStorePlaces({
    int limit = 50,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    var q = stores.orderBy(FieldPath.documentId).limit(limit);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    final snap = await q.get();
    var migrated = 0;
    var updated = 0;
    var skippedMissingRegion = 0;
    final missingRegionDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final name = ((data['name'] ?? data['displayName']) as String? ?? '')
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ');
      if (name.isEmpty) continue;
      final city = (data['city'] as String? ?? '').trim();
      final district = (data['district'] as String? ?? '').trim();
      if (city.isEmpty || district.isEmpty) {
        skippedMissingRegion++;
        missingRegionDocs.add(doc);
        continue;
      }
      final rawType = (data['type'] as String? ?? 'local_market').trim();
      final type = switch (rawType) {
        'chain_market' || 'local_market' || 'online_market' || 'bazaar' => rawType,
        _ => 'local_market',
      };
      final normalized = ((data['nameNormalized'] ?? data['normalizedName']) as String? ?? '')
              .trim()
              .toLowerCase()
              .replaceAll(RegExp(r'\s+'), ' ')
          .ifEmpty(normalizePlaceName(name));
      final existing = await storePlaces
          .where('type', isEqualTo: type)
          .where('city', isEqualTo: city)
          .where('district', isEqualTo: district)
          .where('normalizedName', isEqualTo: normalized)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        updated++;
        await existing.docs.first.reference.set({
          'displayName': name,
          'isActive': true,
          'updatedAt': FieldValue.serverTimestamp(),
          'legacyStoreId': doc.id,
        }, SetOptions(merge: true));
        continue;
      }
      await storePlaces.add({
        'chainId': null,
        'chainName': null,
        'type': type,
        'sourceType': type == 'online_market' ? 'online' : 'physical',
        'channel': type == 'online_market' ? 'online' : 'physical',
        'displayName': name,
        'normalizedName': normalized,
        'city': city,
        'district': district,
        'status': 'pending',
        'isActive': true,
        'usageCount': 0,
        'legacyStoreId': doc.id,
        'createdByUid': 'legacy_migration',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      migrated++;
    }
    return LegacyStoreMigrationResult(
      processed: snap.docs.length,
      migrated: migrated,
      updated: updated,
      skippedMissingRegion: skippedMissingRegion,
      missingRegionDocs: missingRegionDocs,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
      hasMore: snap.docs.length == limit,
    );
  }

  Future<StorePlace?> migrateSingleLegacyStoreToStorePlace({
    required QueryDocumentSnapshot<Map<String, dynamic>> legacyStoreDoc,
    required String city,
    required String district,
    required String type,
    required String createdByUid,
  }) async {
    final data = legacyStoreDoc.data();
    final name = ((data['name'] ?? data['displayName']) as String? ?? '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty) return null;
    final normalized = ((data['nameNormalized'] ?? data['normalizedName']) as String? ?? '')
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'\s+'), ' ')
        .ifEmpty(normalizePlaceName(name));
    final existing = await storePlaces
        .where('type', isEqualTo: type)
        .where('city', isEqualTo: city)
        .where('district', isEqualTo: district)
        .where('normalizedName', isEqualTo: normalized)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return StorePlace.fromDoc(existing.docs.first);
    }
    final ref = await storePlaces.add({
      'chainId': null,
      'chainName': null,
      'type': type,
      'sourceType': type == 'online_market' ? 'online' : 'physical',
      'channel': type == 'online_market' ? 'online' : 'physical',
      'displayName': name,
      'normalizedName': normalized,
      'city': city,
      'district': district,
      'status': 'pending',
      'isActive': true,
      'usageCount': 0,
      'legacyStoreId': legacyStoreDoc.id,
      'createdByUid': createdByUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return StorePlace.fromDoc(await ref.get());
  }
  Future<void> _seedCategories() async {
    final coll = db.collection('categories');
    final snap = await coll.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final batch = db.batch();
    const items = [
      {'name': 'Tümü', 'order': 0},
      {'name': 'Kahvaltılık', 'order': 1},
      {'name': 'Meyve & Sebze', 'order': 2},
      {'name': 'İçecek', 'order': 3},
      {'name': 'Atıştırmalık', 'order': 4},
      {'name': 'Süt Ürünleri', 'order': 5},
      {'name': 'Temizlik', 'order': 6},
    ];
    for (final it in items) {
      batch.set(coll.doc(), {
        'name': it['name'],
        'order': it['order'],
        'isActive': true,
      });
    }
    await batch.commit();
  }

  Future<void> _seedProducts() async {
    final snap = await products.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final now = DateTime.now();
    var seq = 0;
    Map<String, dynamic> entry(String store, double price, int daysAgo,
        {String by = 'Topluluk',
        int up = 0,
        int down = 0,
        String status = 'pending'}) {
      seq++;
      final createdAt = now.subtract(Duration(days: daysAgo));
      return {
        'id': 'seed_${seq}_${createdAt.millisecondsSinceEpoch}',
        'store': store,
        'price': price,
        'date': Timestamp.fromDate(createdAt),
        'reportedBy': by,
        'reportedByUid': '',
        'note': '',
        'upvotes': up,
        'downvotes': down,
        'verifiedByCount': up,
        'rejectedByCount': down,
        'trustWeightedScore': (up - down).toDouble(),
        'status': status,
        'statusUpdatedAt': Timestamp.fromDate(createdAt),
        'voters': <String, String>{},
      };
    }

    final items = <Map<String, dynamic>>[
      {
        'id': 'p1',
        'name': 'Tam Yağlı Süt 1L',
        'brand': 'Sütaş',
        'category': 'Süt Ürünleri',
        'emoji': '🥛',
        'unit': '1 L',
        'priceHistory': [
          entry('BİM', 32.50, 6, up: 4, status: 'community_verified'),
          entry('A101', 33.90, 3, up: 2, down: 1),
          entry('Migros', 35.50, 1, up: 1),
        ],
      },
      {
        'id': 'p2',
        'name': 'Türk Kahvesi 250g',
        'brand': 'Kurukahveci',
        'category': 'İçecek',
        'emoji': '☕',
        'unit': '250 g',
        'priceHistory': [
          entry('Migros', 145.00, 5, up: 3, status: 'community_verified'),
          entry('A101', 139.50, 2, up: 2),
        ],
      },
      {
        'id': 'p3',
        'name': 'Zeytinyağı 1L',
        'brand': 'Komili',
        'category': 'Kahvaltılık',
        'emoji': '🫒',
        'unit': '1 L',
        'priceHistory': [
          entry('ŞOK', 289.00, 4, up: 3, status: 'community_verified'),
          entry('CarrefourSA', 305.00, 1, up: 1),
        ],
      },
      {
        'id': 'p4',
        'name': 'Yumurta 30\'lu',
        'brand': 'Köy',
        'category': 'Kahvaltılık',
        'emoji': '🥚',
        'unit': '30 adet',
        'priceHistory': [entry('A101', 159.00, 2, up: 2)],
      },
      {
        'id': 'p5',
        'name': 'Domates 1kg',
        'brand': 'Yerli',
        'category': 'Meyve & Sebze',
        'emoji': '🍅',
        'unit': '1 kg',
        'priceHistory': [
          entry('Tarım Kredi', 24.90, 1, up: 2),
          entry('Migros', 32.50, 0, up: 1),
        ],
      },
      {
        'id': 'p6',
        'name': 'Çikolata 80g',
        'brand': 'Eti',
        'category': 'Atıştırmalık',
        'emoji': '🍫',
        'unit': '80 g',
        'priceHistory': [entry('BİM', 22.50, 3, up: 1)],
      },
    ];

    final batch = db.batch();
    for (final it in items) {
      final id = it.remove('id') as String;
      batch.set(products.doc(id), it);
    }
    await batch.commit();
  }

  Future<void> _seedBanners() async {
    final snap = await banners.limit(1).get();
    if (snap.docs.isNotEmpty) return;
    final batch = db.batch();
    final list = [
      {
        'title': 'Markette gördüğünü\npaylaş, herkes kazansın',
        'subtitle': 'Her paylaşım +10 puan',
        'actionLabel': 'Fiyat Ekle',
        'order': 1,
        'isActive': true,
      },
      {
        'title': 'Kahveye özel\nhafta indirimleri',
        'subtitle': 'Kahve kategorisinde en düşük fiyatlar',
        'actionLabel': 'Keşfet',
        'order': 2,
        'isActive': true,
      },
      {
        'title': 'Favorilerine ekle,\nfiyat düşünce haber al',
        'subtitle': 'Kalp simgesine dokun',
        'actionLabel': 'Dene',
        'order': 3,
        'isActive': true,
      },
    ];
    for (final b in list) {
      batch.set(banners.doc(), b);
    }
    await batch.commit();
  }
}
