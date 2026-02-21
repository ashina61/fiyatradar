import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/comment_model.dart';
import '../models/price_model.dart';
import '../models/product_detail_api_model.dart';
import '../models/product_model.dart';
import 'firestore_service.dart';

class ProductDetailApiService {
  ProductDetailApiService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirestoreService? firestoreService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirestoreService _firestoreService;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');
  CollectionReference<Map<String, dynamic>> get _pricesRef =>
      _firestore.collection('priceReports');
  CollectionReference<Map<String, dynamic>> get _commentsRef =>
      _firestore.collection('comments');

  Future<ProductDetailResponse> fetchProductDetails(String productId) async {
    final productDoc = await _productsRef.doc(productId).get();
    if (!productDoc.exists) {
      throw Exception('Ürün bulunamadı.');
    }

    final product = ProductModel.fromFirestore(productDoc);

    final pricesSnapshot = await _pricesRef
        .where('productId', isEqualTo: productId)
        .where('status', isEqualTo: 'active')
        .get();
    final prices = pricesSnapshot.docs.map(PriceModel.fromFirestore).toList();
    prices.sort((a, b) => a.price.compareTo(b.price));

    final commentsSnapshot = await _commentsRef
        .where('productId', isEqualTo: productId)
        .get();
    final comments = commentsSnapshot.docs
        .map(CommentModel.fromFirestore)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final bestPriceModel = prices.isNotEmpty ? prices.first : null;
    final stats = _buildStats(prices);
    final trust = _buildTrust(prices);

    return ProductDetailResponse(
      id: product.id,
      title: product.name,
      imageUrl: product.effectiveImage ?? '',
      categories: product.categories,
      viewCount: product.viewCount,
      priceEntryCount: prices.length,
      bestPrice: _toBestPrice(bestPriceModel),
      stats: stats,
      trust: trust,
      comments: comments.map(_toProductComment).toList(growable: false),
    );
  }

  Future<List<PriceHistoryPoint>> fetchPriceHistory(String productId) async {
    final now = DateTime.now();
    final since = now.subtract(const Duration(days: 30));

    final snapshot = await _pricesRef
        .where('productId', isEqualTo: productId)
        .where('status', isEqualTo: 'active')
        .where('reportedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .get();

    final points = snapshot.docs
        .map(PriceModel.fromFirestore)
        .toList()
      ..sort((a, b) => a.reportedAt.compareTo(b.reportedAt));

    final formatter = DateFormat('dd MMM', 'tr_TR');
    return points
        .map(
          (price) => PriceHistoryPoint(
            dateLabel: formatter.format(price.reportedAt),
            price: price.price,
          ),
        )
        .toList(growable: false);
  }

  Future<void> postComment(String productId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw Exception('Yorum boş olamaz.');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Yorum yapmak için giriş yapmalısın.');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};

    final comment = CommentModel(
      id: '',
      productId: productId,
      userId: user.uid,
      userName: (userData['name'] ?? userData['displayName'] ?? user.displayName ?? 'Anonim').toString(),
      userPhotoUrl: (userData['photoUrl'] ?? user.photoURL)?.toString(),
      authorRole: (userData['role'] ?? 'member').toString(),
      text: trimmed,
      createdAt: DateTime.now(),
    );

    await _firestoreService.addComment(comment);
  }

  Future<void> votePrice(String priceId, bool isApproved) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Oy vermek için giriş yapmalısın.');
    }

    await _firestoreService.verifyPrice(priceId, user.uid, isApproved);
  }

  BestPrice _toBestPrice(PriceModel? price) {
    if (price == null) {
      return BestPrice(
        id: '',
        price: 0,
        store: '',
        userName: 'Topluluk',
        userTier: 'Yeni',
        createdAtLabel: '-',
        storeUrl: '',
        upVotes: 0,
        downVotes: 0,
      );
    }

    return BestPrice(
      id: price.id,
      price: price.price,
      store: price.storeName ?? 'Bilinmeyen mağaza',
      userName: (price.userName ?? 'Anonim').trim().isEmpty ? 'Anonim' : price.userName!,
      userTier: (price.addedByLevelSnapshot ?? price.createdByBadgeSnapshot ?? 'Topluluk').toString(),
      createdAtLabel: DateFormat('dd.MM.yyyy').format(price.reportedAt),
      storeUrl: '',
      upVotes: price.upVotes,
      downVotes: price.downVotes,
    );
  }

  PriceStats _buildStats(List<PriceModel> prices) {
    if (prices.isEmpty) {
      return PriceStats(lowest: 0, average: 0, highest: 0);
    }
    final values = prices.map((e) => e.price).toList(growable: false);
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    return PriceStats(lowest: min, average: avg, highest: max);
  }

  TrustStats _buildTrust(List<PriceModel> prices) {
    final approveCount = prices.fold<int>(0, (sum, p) => sum + p.upVotes);
    final rejectCount = prices.fold<int>(0, (sum, p) => sum + p.downVotes);
    final total = approveCount + rejectCount;
    final scorePercent = total == 0 ? 0 : ((approveCount / total) * 100).round();
    return TrustStats(
      scorePercent: scorePercent,
      approveCount: approveCount,
      rejectCount: rejectCount,
    );
  }

  ProductComment _toProductComment(CommentModel comment) {
    return ProductComment(
      id: comment.id,
      author: comment.userName,
      avatarBgHex: '#C8956C',
      text: comment.text,
      timeAgo: _formatTimeAgo(comment.createdAt),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'şimdi';
    if (diff.inHours < 1) return '${diff.inMinutes} dk önce';
    if (diff.inDays < 1) return '${diff.inHours} sa önce';
    if (diff.inDays < 30) return '${diff.inDays} gün önce';
    final months = (diff.inDays / 30).floor();
    return '$months ay önce';
  }
}
