import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  priceDrop,
  newPrice,
  system,
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? productId;
  final String? productName;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.productId,
    this.productName,
    this.imageUrl,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final rawType = (data['type'] ?? '').toString();
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == rawType,
        orElse: () {
          switch (rawType) {
            case 'price_drop':
              return NotificationType.priceDrop;
            case 'new_price':
              return NotificationType.newPrice;
            default:
              return NotificationType.system;
          }
        },
      ),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      productId: data['productId'],
      productName: data['productName'],
      imageUrl: data['imageUrl'],
      isRead: data['isRead'] == true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      data: data['meta'] as Map<String, dynamic>? ?? data['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    final typeValue = switch (type) {
      NotificationType.priceDrop => 'price_drop',
      NotificationType.newPrice => 'new_price',
      NotificationType.system => 'system',
    };

    return {
      'userId': userId,
      'type': typeValue,
      'title': title,
      'body': body,
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'meta': data,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    String? productId,
    String? productName,
    String? imageUrl,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
    );
  }

  String get icon {
    switch (type) {
      case NotificationType.priceDrop:
        return '📉';
      case NotificationType.newPrice:
        return '💸';
      case NotificationType.system:
        return '📢';
    }
  }
}
