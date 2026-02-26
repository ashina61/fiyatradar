import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/comment_model.dart';
import '../utils/safe_query_builder.dart';
import 'points_service.dart';

class CommentService {
  CommentService({
    FirebaseFirestore? firestore,
    PointsService? pointsService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _pointsService = pointsService ?? PointsService();

  final FirebaseFirestore _firestore;
  final PointsService _pointsService;

  CollectionReference<Map<String, dynamic>> get _commentsRef =>
      _firestore.collection('comments');

  Stream<List<CommentModel>> getComments(String productId) {
    final query = SafeQueryBuilder.safeWhere(
      _commentsRef,
      'productId',
      productId,
      expectedType: String,
    );
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<String> addComment(CommentModel comment) async {
    final doc = await _commentsRef.add(comment.toFirestore());
    if (comment.text.trim().length >= 12) {
      await _pointsService.awardEvent(
        uid: comment.userId,
        eventType: 'comment',
        meta: {'commentId': doc.id, 'productId': comment.productId},
      );
    }
    return doc.id;
  }

  Future<void> likeComment(String commentId, String userId) async {
    final doc = await _commentsRef.doc(commentId).get();
    if (doc.exists) {
      final raw = doc.data();
      final data = raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : null;
      final likedBy = List<String>.from(data?['likedBy'] ?? []);
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }
      await _commentsRef.doc(commentId).update({
        'likedBy': likedBy,
        'likes': likedBy.length,
      });
    }
  }

  Future<void> deleteComment(String commentId) async {
    await _commentsRef.doc(commentId).delete();
  }
}
