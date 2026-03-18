import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.createdAt,
    this.photoUrl,
    this.fcmToken,
    this.inviteCode,
    this.invitedBy,
    this.cityCode,
    this.cityName,
    this.city,
    this.neighborhood,
    this.firstName,
    this.lastName,
    required this.username,
    this.lastUsernameChange,
    this.passwordRenewalPeriod,
    this.points = 0,
    this.priceEntries = 0,
    this.validations = 0,
    this.inviteCount = 0,
    this.isAdmin = false,
    this.isBanned = false,
    this.banReason,
    this.role,
    this.savedProducts = const [],
    this.reliabilityScore = 0.0,
    this.trustScorePercent = 0,
    this.trustTotalVotes = 0,
    this.trustVerifiedTotal = 0,
    this.trustWrongTotal = 0,
    this.reliabilityVotesTotal = 0,
    this.reliabilityVotesUp = 0,
    this.reliabilityVotesDown = 0,
    this.lastLoginAt,
    this.alarmNotifications = true,
    this.campaignNotifications = true,
    this.badgeNotifications = false,
  });

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
  final String? neighborhood;
  final String? firstName;
  final String? lastName;
  final String username;
  final Timestamp? lastUsernameChange;
  final int? passwordRenewalPeriod;
  final int points;
  final int priceEntries;
  final int validations;
  final int inviteCount;
  final bool isAdmin;
  final bool isBanned;
  final String? banReason;
  final String? role;
  final List<String> savedProducts;
  final double reliabilityScore;
  final int trustScorePercent;
  final int trustTotalVotes;
  final int trustVerifiedTotal;
  final int trustWrongTotal;
  final int reliabilityVotesTotal;
  final int reliabilityVotesUp;
  final int reliabilityVotesDown;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool alarmNotifications;
  final bool campaignNotifications;
  final bool badgeNotifications;

  String? get displayName {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isNotEmpty) return normalizedUsername;
    return name.trim().isEmpty ? null : name;
  }
  String get id => uid;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic>
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    return UserModel.fromMap(data, doc.id);
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    final notificationPrefs = data['notificationPrefs'] is Map
        ? Map<String, dynamic>.from(data['notificationPrefs'] as Map)
        : <String, dynamic>{};

    final firstName = _asTrimmedString(data['firstName']);
    final lastName = _asTrimmedString(data['lastName'] ?? data['surname']);
    final fallbackName = [firstName, lastName]
        .whereType<String>()
        .where((part) => part.isNotEmpty)
        .join(' ')
        .trim();

    return UserModel(
      uid: documentId,
      email: _asTrimmedString(data['email']) ?? '',
      name: _asTrimmedString(data['name']) ??
          _asTrimmedString(data['displayName']) ??
          fallbackName,
      photoUrl: _asTrimmedString(data['photoUrl']),
      fcmToken: _asTrimmedString(data['fcmToken']),
      inviteCode: _asTrimmedString(data['inviteCode']),
      invitedBy: _asTrimmedString(data['invitedBy']),
      cityCode: _asTrimmedString(data['cityCode']),
      cityName: _asTrimmedString(data['cityName']),
      city: _asTrimmedString(data['city']) ?? _asTrimmedString(data['cityName']),
      neighborhood: _asTrimmedString(data['neighborhood']),
      firstName: firstName,
      lastName: lastName,
      username: _asTrimmedString(data['username'] ?? data['userName']) ??
          _asTrimmedString(data['name']) ??
          _asTrimmedString(data['displayName']) ??
          documentId,
      lastUsernameChange: data['lastUsernameChange'] as Timestamp?,
      passwordRenewalPeriod: (data['passwordRenewalPeriod'] as num?)?.toInt(),
      points: (data['points'] as num?)?.toInt() ?? 0,
      priceEntries: (data['priceEntries'] as num?)?.toInt() ?? 0,
      validations: (data['validations'] as num?)?.toInt() ?? 0,
      inviteCount: (data['inviteCount'] as num?)?.toInt() ?? 0,
      isAdmin: data['isAdmin'] == true,
      isBanned: data['isBanned'] == true,
      banReason: _asTrimmedString(data['banReason']),
      role: _asTrimmedString(data['role']),
      savedProducts: List<String>.from(data['savedProducts'] ?? const <String>[]),
      reliabilityScore: (data['reliabilityScore'] as num?)?.toDouble() ?? 0.0,
      trustScorePercent: (data['trustScorePercent'] as num?)?.toInt() ?? 0,
      trustTotalVotes: (data['trustTotalVotes'] as num?)?.toInt() ?? 0,
      trustVerifiedTotal: (data['trustVerifiedTotal'] as num?)?.toInt() ?? 0,
      trustWrongTotal: (data['trustWrongTotal'] as num?)?.toInt() ?? 0,
      reliabilityVotesTotal: (data['reliabilityVotesTotal'] as num?)?.toInt() ?? 0,
      reliabilityVotesUp: (data['reliabilityVotesUp'] as num?)?.toInt() ?? 0,
      reliabilityVotesDown: (data['reliabilityVotesDown'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      alarmNotifications: (data['alarmNotifications'] as bool?) ??
          (data['priceAlarm'] as bool?) ??
          (notificationPrefs['priceAlerts'] as bool?) ??
          true,
      campaignNotifications: (data['campaignNotifications'] as bool?) ??
          (data['campaignNotification'] as bool?) ??
          (notificationPrefs['campaignAlerts'] as bool?) ??
          true,
      badgeNotifications: (data['badgeNotifications'] as bool?) ??
          (data['badgeNotification'] as bool?) ??
          (notificationPrefs['badgeAlerts'] as bool?) ??
          false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'displayName': displayName ?? username,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'inviteCode': inviteCode,
      'invitedBy': invitedBy,
      'cityCode': cityCode,
      'cityName': cityName,
      'city': city,
      'neighborhood': neighborhood,
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'lastUsernameChange': lastUsernameChange,
      'passwordRenewalPeriod': passwordRenewalPeriod,
      'points': points,
      'priceEntries': priceEntries,
      'validations': validations,
      'inviteCount': inviteCount,
      'isAdmin': isAdmin,
      'isBanned': isBanned,
      'banReason': banReason,
      'role': role,
      'savedProducts': savedProducts,
      'reliabilityScore': reliabilityScore,
      'trustScorePercent': trustScorePercent,
      'trustTotalVotes': trustTotalVotes,
      'trustVerifiedTotal': trustVerifiedTotal,
      'trustWrongTotal': trustWrongTotal,
      'reliabilityVotesTotal': reliabilityVotesTotal,
      'reliabilityVotesUp': reliabilityVotesUp,
      'reliabilityVotesDown': reliabilityVotesDown,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'alarmNotifications': alarmNotifications,
      'campaignNotifications': campaignNotifications,
      'badgeNotifications': badgeNotifications,
      'notificationPrefs': {
        'priceAlerts': alarmNotifications,
        'campaignAlerts': campaignNotifications,
        'badgeAlerts': badgeNotifications,
      },
    };
  }

  Map<String, dynamic> toMap() => toFirestore();

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
    String? neighborhood,
    String? firstName,
    String? lastName,
    String? username,
    Timestamp? lastUsernameChange,
    int? passwordRenewalPeriod,
    int? points,
    int? priceEntries,
    int? validations,
    int? inviteCount,
    bool? isAdmin,
    bool? isBanned,
    String? banReason,
    String? role,
    List<String>? savedProducts,
    double? reliabilityScore,
    int? trustScorePercent,
    int? trustTotalVotes,
    int? trustVerifiedTotal,
    int? trustWrongTotal,
    int? reliabilityVotesTotal,
    int? reliabilityVotesUp,
    int? reliabilityVotesDown,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? alarmNotifications,
    bool? campaignNotifications,
    bool? badgeNotifications,
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
      neighborhood: neighborhood ?? this.neighborhood,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      lastUsernameChange: lastUsernameChange ?? this.lastUsernameChange,
      passwordRenewalPeriod: passwordRenewalPeriod ?? this.passwordRenewalPeriod,
      points: points ?? this.points,
      priceEntries: priceEntries ?? this.priceEntries,
      validations: validations ?? this.validations,
      inviteCount: inviteCount ?? this.inviteCount,
      isAdmin: isAdmin ?? this.isAdmin,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      role: role ?? this.role,
      savedProducts: savedProducts ?? this.savedProducts,
      reliabilityScore: reliabilityScore ?? this.reliabilityScore,
      trustScorePercent: trustScorePercent ?? this.trustScorePercent,
      trustTotalVotes: trustTotalVotes ?? this.trustTotalVotes,
      trustVerifiedTotal: trustVerifiedTotal ?? this.trustVerifiedTotal,
      trustWrongTotal: trustWrongTotal ?? this.trustWrongTotal,
      reliabilityVotesTotal: reliabilityVotesTotal ?? this.reliabilityVotesTotal,
      reliabilityVotesUp: reliabilityVotesUp ?? this.reliabilityVotesUp,
      reliabilityVotesDown: reliabilityVotesDown ?? this.reliabilityVotesDown,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      alarmNotifications: alarmNotifications ?? this.alarmNotifications,
      campaignNotifications:
          campaignNotifications ?? this.campaignNotifications,
      badgeNotifications: badgeNotifications ?? this.badgeNotifications,
    );
  }

  static String? _asTrimmedString(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }
}
