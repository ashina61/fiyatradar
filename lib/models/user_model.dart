import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl;
  final String? fcmToken;
  final String? inviteCode;
  final String? invitedBy;
  final String? cityCode;
  final String? cityName;
  final String? city;
  final int points;
  final int priceEntries;
  final int validations;
  final int inviteCount;
  final bool isAdmin;
  final String? role;
  final List<String> savedProducts;
  final double reliabilityScore;
  final int reliabilityVotesTotal;
  final int reliabilityVotesUp;
  final int reliabilityVotesDown;
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
    this.cityCode,
    this.cityName,
    this.city,
    this.points = 0,
    this.priceEntries = 0,
    this.validations = 0,
    this.inviteCount = 0,
    this.isAdmin = false,
    this.role,
    this.savedProducts = const [],
    this.reliabilityScore = 0.0,
    this.reliabilityVotesTotal = 0,
    this.reliabilityVotesUp = 0,
    this.reliabilityVotesDown = 0,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      fcmToken: data['fcmToken'],
      inviteCode: data['inviteCode'],
      invitedBy: data['invitedBy'],
      cityCode: data['cityCode'],
      cityName: data['cityName'],
      city: data['city'] ?? data['cityName'],
      points: data['points'] ?? 0,
      priceEntries: data['priceEntries'] ?? 0,
      validations: data['validations'] ?? 0,
      inviteCount: data['inviteCount'] ?? 0,
      isAdmin: data['isAdmin'] ?? false,
      role: data['role'],
      savedProducts: List<String>.from(data['savedProducts'] ?? []),
      reliabilityScore: (data['reliabilityScore'] ?? 0.0).toDouble(),
      reliabilityVotesTotal: (data['reliabilityVotesTotal'] as num?)?.toInt() ?? 0,
      reliabilityVotesUp: (data['reliabilityVotesUp'] as num?)?.toInt() ?? 0,
      reliabilityVotesDown: (data['reliabilityVotesDown'] as num?)?.toInt() ?? 0,
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
      'cityCode': cityCode,
      'cityName': cityName,
      'city': city,
      'points': points,
      'priceEntries': priceEntries,
      'validations': validations,
      'inviteCount': inviteCount,
      'isAdmin': isAdmin,
      'role': role,
      'savedProducts': savedProducts,
      'reliabilityScore': reliabilityScore,
      'reliabilityVotesTotal': reliabilityVotesTotal,
      'reliabilityVotesUp': reliabilityVotesUp,
      'reliabilityVotesDown': reliabilityVotesDown,
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
    String? cityCode,
    String? cityName,
    String? city,
    int? points,
    int? priceEntries,
    int? validations,
    int? inviteCount,
    bool? isAdmin,
    String? role,
    List<String>? savedProducts,
    double? reliabilityScore,
    int? reliabilityVotesTotal,
    int? reliabilityVotesUp,
    int? reliabilityVotesDown,
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
      cityCode: cityCode ?? this.cityCode,
      cityName: cityName ?? this.cityName,
      city: city ?? this.city,
      points: points ?? this.points,
      priceEntries: priceEntries ?? this.priceEntries,
      validations: validations ?? this.validations,
      inviteCount: inviteCount ?? this.inviteCount,
      isAdmin: isAdmin ?? this.isAdmin,
      role: role ?? this.role,
      savedProducts: savedProducts ?? this.savedProducts,
      reliabilityScore: reliabilityScore ?? this.reliabilityScore,
      reliabilityVotesTotal: reliabilityVotesTotal ?? this.reliabilityVotesTotal,
      reliabilityVotesUp: reliabilityVotesUp ?? this.reliabilityVotesUp,
      reliabilityVotesDown: reliabilityVotesDown ?? this.reliabilityVotesDown,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
