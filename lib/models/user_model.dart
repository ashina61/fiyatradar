import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl;
  final String? fcmToken;
  final String? inviteCode;
  final String? invitedBy;
  final int points;
  final int priceEntries;
  final int validations;
  final int inviteCount;
  final bool isAdmin;
  final List<String> savedProducts;
  final double reliabilityScore;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    this.fcmToken,
    this.inviteCode,
    this.invitedBy,
    this.points = 0,
    this.priceEntries = 0,
    this.validations = 0,
    this.inviteCount = 0,
    this.isAdmin = false,
    this.savedProducts = const [],
    this.reliabilityScore = 100.0,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      fcmToken: data['fcmToken'],
      inviteCode: data['inviteCode'],
      invitedBy: data['invitedBy'],
      points: data['points'] ?? 0,
      priceEntries: data['priceEntries'] ?? 0,
      validations: data['validations'] ?? 0,
      inviteCount: data['inviteCount'] ?? 0,
      isAdmin: data['isAdmin'] ?? false,
      savedProducts: List<String>.from(data['savedProducts'] ?? []),
      reliabilityScore: (data['reliabilityScore'] ?? 100.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'inviteCode': inviteCode,
      'invitedBy': invitedBy,
      'points': points,
      'priceEntries': priceEntries,
      'validations': validations,
      'inviteCount': inviteCount,
      'isAdmin': isAdmin,
      'savedProducts': savedProducts,
      'reliabilityScore': reliabilityScore,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? photoUrl,
    String? fcmToken,
    String? inviteCode,
    String? invitedBy,
    int? points,
    int? priceEntries,
    int? validations,
    int? inviteCount,
    bool? isAdmin,
    List<String>? savedProducts,
    double? reliabilityScore,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      inviteCode: inviteCode ?? this.inviteCode,
      invitedBy: invitedBy ?? this.invitedBy,
      points: points ?? this.points,
      priceEntries: priceEntries ?? this.priceEntries,
      validations: validations ?? this.validations,
      inviteCount: inviteCount ?? this.inviteCount,
      isAdmin: isAdmin ?? this.isAdmin,
      savedProducts: savedProducts ?? this.savedProducts,
      reliabilityScore: reliabilityScore ?? this.reliabilityScore,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
