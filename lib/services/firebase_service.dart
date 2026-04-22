import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Central Firebase access and one-time bootstrap of required collections.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get products =>
      db.collection('products');
  CollectionReference<Map<String, dynamic>> get banners =>
      db.collection('banners');
  CollectionReference<Map<String, dynamic>> get users =>
      db.collection('users');

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
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (displayName != null && displayName.trim().isNotEmpty) {
      await cred.user?.updateDisplayName(displayName.trim());
    }
    return cred;
  }

  Future<void> sendPasswordReset(String email) {
    return auth.sendPasswordResetEmail(email: email);
  }

  /// Seeds Firestore collections on first launch so the app is never empty.
  /// After first run, all data is sourced from Firestore.
  Future<void> bootstrap() async {
    await _seedProducts();
    await _seedBanners();
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
