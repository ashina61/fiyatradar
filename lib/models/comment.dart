import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored in the top-level `comments` collection. Firestore rules
/// (see `firestore.rules → match /comments/{commentId}`) guard:
///   • create: signedIn(), payload-shape, userId == auth.uid, likes/likedBy
///     start at zero/empty
///   • update: owner can change `text` and `updatedAt` only; admin override
///   • delete: owner or admin
///   • read: public
class ProductComment {
  final String id;
  final String productId;
  final String userId;
  final String text;
  final int likes;
  final List<String> likedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Denormalized author profile, written at create time so listing a
  /// product's comments doesn't require N user-doc fetches. Owner can also
  /// refresh these fields on edit (e.g. after a new profile photo). Firestore
  /// rules whitelist them in `hasSafeCommentCreatePayload`.
  final String? authorName;
  final String? authorAvatar;
  final bool authorIsPro;
  final int? authorTrustPercent;

  const ProductComment({
    required this.id,
    required this.productId,
    required this.userId,
    required this.text,
    required this.likes,
    required this.likedBy,
    required this.createdAt,
    this.updatedAt,
    this.authorName,
    this.authorAvatar,
    this.authorIsPro = false,
    this.authorTrustPercent,
  });

  bool get isEdited => updatedAt != null && updatedAt!.isAfter(createdAt);

  bool isLikedBy(String uid) => likedBy.contains(uid);
  bool isOwnedBy(String uid) => uid.isNotEmpty && uid == userId;

  factory ProductComment.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    final created = m['createdAt'];
    final updated = m['updatedAt'];
    final likedByRaw = (m['likedBy'] as List?) ?? const [];
    return ProductComment(
      id: d.id,
      productId: (m['productId'] ?? '') as String,
      userId: (m['userId'] ?? '') as String,
      text: (m['text'] ?? '') as String,
      likes: (m['likes'] as num?)?.toInt() ?? 0,
      likedBy: likedByRaw.map((e) => e.toString()).toList(growable: false),
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      updatedAt: updated is Timestamp ? updated.toDate() : null,
      authorName: (m['authorName'] as String?)?.trim().isNotEmpty == true
          ? (m['authorName'] as String).trim()
          : null,
      authorAvatar: (m['authorAvatar'] as String?)?.trim().isNotEmpty == true
          ? (m['authorAvatar'] as String).trim()
          : null,
      authorIsPro: (m['authorIsPro'] as bool?) == true,
      authorTrustPercent: (m['authorTrustPercent'] as num?)?.toInt(),
    );
  }
}
