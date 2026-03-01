import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  priceDrop,
  newPrice,
  system,
}

enum NotificationSource {
  primary,
  legacy,
}

class NotificationItem {
  final String id;
  final NotificationSource source;
  final NotificationType type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic> meta;

  NotificationItem({
    required this.id,
    required this.source,
    required this.type,
    required this.title,
    required this.body,
    this.read = false,
    required this.createdAt,
    this.meta = const <String, dynamic>{},
  });

  factory NotificationItem.fromPrimaryDoc(DocumentSnapshot doc) {
    return _fromFirestoreDoc(doc, source: NotificationSource.primary);
  }

  factory NotificationItem.fromLegacyDoc(DocumentSnapshot doc) {
    return _fromFirestoreDoc(doc, source: NotificationSource.legacy);
  }

  static NotificationItem _fromFirestoreDoc(
    DocumentSnapshot doc, {
    required NotificationSource source,
  }) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic>
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    final rawType = (data['type'] ?? '').toString();

    return NotificationItem(
      id: doc.id,
      source: source,
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
      title: (data['title'] ?? '').toString(),
      body: (data['body'] ?? '').toString(),
      read: (data['read'] ?? data['isRead']) == true,
      createdAt: _parseCreatedAt(data),
      meta: _normalizedMeta(data),
    );
  }

  static DateTime _parseCreatedAt(Map<String, dynamic> data) {
    final dynamic createdAtRaw =
        data['createdAt'] ?? data['timestamp'] ?? data['created_at'];
    if (createdAtRaw is Timestamp) return createdAtRaw.toDate();
    if (createdAtRaw is DateTime) return createdAtRaw;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static Map<String, dynamic> _normalizedMeta(Map<String, dynamic> data) {
    final rawMeta = data['meta'] ?? data['data'];
    final meta = rawMeta is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawMeta)
        : <String, dynamic>{};

    for (final key in [
      'userId',
      'eventId',
      'priceId',
      'productId',
      'productName',
      'storeId',
      'imageUrl',
    ]) {
      if (data[key] != null && !meta.containsKey(key)) {
        meta[key] = data[key];
      }
    }

    return meta;
  }

  Map<String, dynamic> toFirestore() {
    final typeValue = switch (type) {
      NotificationType.priceDrop => 'price_drop',
      NotificationType.newPrice => 'new_price',
      NotificationType.system => 'system',
    };

    return {
      'userId': meta['userId'] ?? '',
      'type': typeValue,
      'title': title,
      'body': body,
      'productId': meta['productId'],
      'productName': meta['productName'],
      'imageUrl': meta['imageUrl'],
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
      'meta': meta,
    };
  }

  NotificationItem copyWith({
    String? id,
    NotificationSource? source,
    NotificationType? type,
    String? title,
    String? body,
    bool? read,
    DateTime? createdAt,
    Map<String, dynamic>? meta,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      source: source ?? this.source,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
      meta: meta ?? this.meta,
    );
  }

  bool get isRead => read;
  String get userId => (meta['userId'] ?? '').toString();
  String? get productId => meta['productId']?.toString();
  String? get productName => meta['productName']?.toString();
  String? get imageUrl => meta['imageUrl']?.toString();
  Map<String, dynamic> get data => meta;

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

typedef NotificationModel = NotificationItem;
