import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String? authorRole;
  final String text;
  final DateTime createdAt;
  final int likes;
  final List<String> likedBy;

  CommentModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.authorRole,
    required this.text,
    required this.createdAt,
    this.likes = 0,
    this.likedBy = const [],
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonim',
      userPhotoUrl: data['userPhotoUrl'],
      authorRole: data['authorRole'],
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'authorRole': authorRole,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'likedBy': likedBy,
    };
  }

  CommentModel copyWith({
    String? id,
    String? productId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? authorRole,
    String? text,
    DateTime? createdAt,
    int? likes,
    List<String>? likedBy,
  }) {
    return CommentModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      authorRole: authorRole ?? this.authorRole,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
    );
  }
}
