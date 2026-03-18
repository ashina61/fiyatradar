import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.metaData = const <String, dynamic>{},
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final Timestamp createdAt;
  final Map<String, dynamic> metaData;

  factory NotificationItem.fromFirestoreDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return NotificationItem(
      id: (data['id'] ?? doc.id).toString(),
      type: _normalizeType((data['type'] ?? 'system').toString()),
      title: (data['title'] ?? 'Bildirim').toString(),
      message: (data['message'] ?? data['body'] ?? '').toString(),
      isRead: (data['isRead'] ?? data['read']) == true,
      createdAt: _parseTimestamp(data['createdAt'] ?? data['timestamp'] ?? data['created_at']),
      metaData: _parseMeta(data),
    );
  }

  static Timestamp _parseTimestamp(dynamic raw) {
    if (raw is Timestamp) return raw;
    if (raw is DateTime) return Timestamp.fromDate(raw);
    return Timestamp.fromMillisecondsSinceEpoch(0);
  }

  static Map<String, dynamic> _parseMeta(Map<String, dynamic> data) {
    final rawMeta = data['metaData'] ?? data['meta'] ?? data['data'];
    final meta = rawMeta is Map ? Map<String, dynamic>.from(rawMeta) : <String, dynamic>{};
    for (final entry in data.entries) {
      if (const {
        'userId',
        'eventId',
        'priceId',
        'productId',
        'productName',
        'storeId',
        'imageUrl',
      }.contains(entry.key)) {
        meta.putIfAbsent(entry.key, () => entry.value);
      }
    }
    return meta;
  }

  static String _normalizeType(String value) {
    switch (value) {
      case 'price_drop':
      case 'alarm':
        return 'alarm';
      case 'new_price':
      case 'level_up':
        return 'level_up';
      default:
        return 'system';
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'type': _normalizeType(type),
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt,
      'metaData': metaData,
      if (metaData['userId'] != null) 'userId': metaData['userId'],
      if (metaData['productId'] != null) 'productId': metaData['productId'],
      if (metaData['productName'] != null) 'productName': metaData['productName'],
      if (metaData['imageUrl'] != null) 'imageUrl': metaData['imageUrl'],
    };
  }

  NotificationItem copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    bool? isRead,
    Timestamp? createdAt,
    Map<String, dynamic>? metaData,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      metaData: metaData ?? this.metaData,
    );
  }

  DateTime get createdAtDate => createdAt.toDate();
  bool get read => isRead;
  String get body => message;
  Map<String, dynamic> get meta => metaData;
  String get userId => (metaData['userId'] ?? '').toString();
  String? get productId => metaData['productId']?.toString();
  String? get productName => metaData['productName']?.toString();
  String? get imageUrl => metaData['imageUrl']?.toString();
}

typedef NotificationModel = NotificationItem;
