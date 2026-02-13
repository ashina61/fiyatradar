import 'package:cloud_firestore/cloud_firestore.dart';

enum BrandType { chain, online, local }

class BrandModel {
  final String id;
  final String name;
  final BrandType type;
  final String? logoUrl;
  final DateTime createdAt;

  BrandModel({
    required this.id,
    required this.name,
    required this.type,
    this.logoUrl,
    required this.createdAt,
  });

  factory BrandModel.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return BrandModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: _parseBrandType(data['type']),
      logoUrl: data['logoUrl'],
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type.name,
      'logoUrl': logoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static BrandType _parseBrandType(String? value) {
    switch (value) {
      case 'chain':
        return BrandType.chain;
      case 'online':
        return BrandType.online;
      case 'local':
        return BrandType.local;
      default:
        return BrandType.chain;
    }
  }

  String get typeLabel {
    switch (type) {
      case BrandType.chain:
        return 'Zincir';
      case BrandType.online:
        return 'Online';
      case BrandType.local:
        return 'Yerel';
    }
  }

  BrandModel copyWith({
    String? id,
    String? name,
    BrandType? type,
    String? logoUrl,
    DateTime? createdAt,
  }) {
    return BrandModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
