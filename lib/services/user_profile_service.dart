import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/level_style.dart';
import '../utils/level_system.dart';

class UserProfileSummary {
  const UserProfileSummary({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.city,
    required this.totalPoints,
    required this.weeklyPoints,
    required this.monthlyPoints,
    required this.trustScorePercent,
    required this.trustTotalVotes,
    required this.level,
  });

  final String uid;
  final String displayName;
  final String photoUrl;
  final String city;
  final int totalPoints;
  final int weeklyPoints;
  final int monthlyPoints;
  final int trustScorePercent;
  final int trustTotalVotes;
  final UserLevel level;
}

class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<UserProfileSummary?> streamUserSummary(String uid) {
    if (uid.trim().isEmpty) return Stream.value(null);

    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data() ?? const <String, dynamic>{};
      final totalPoints = (data['totalPoints'] as num?)?.toInt() ?? (data['pointsTotal'] as num?)?.toInt() ?? (data['points'] as num?)?.toInt() ?? 0;
      final weeklyPoints = (data['weeklyPoints'] as num?)?.toInt() ?? 0;
      final monthlyPoints = (data['monthlyPoints'] as num?)?.toInt() ?? 0;
      final trustScorePercent = ((data['trustScorePercent'] as num?)?.toDouble() ?? (data['reliabilityScore'] as num?)?.toDouble() ?? ((data['trustScore'] as num?)?.toDouble() ?? 0) * 100)
          .round()
          .clamp(0, 100);
      final trustMap = Map<String, dynamic>.from(data['trust'] as Map? ?? const {});
      final trustUpTotal = (data['trustVerifiedTotal'] as num?)?.toInt() ?? (trustMap['upTotal'] as num?)?.toInt() ?? 0;
      final trustDownTotal = (data['trustWrongTotal'] as num?)?.toInt() ?? (trustMap['downTotal'] as num?)?.toInt() ?? 0;
      final trustTotalVotes = (data['trustTotalVotes'] as num?)?.toInt() ?? (trustUpTotal + trustDownTotal);
      final finalLevel = LevelStyle.fromFinalLevel(
        totalPoints: totalPoints,
        trustPercent: trustScorePercent,
        totalVotes: trustTotalVotes,
      );

      return UserProfileSummary(
        uid: doc.id,
        displayName: ((data['username'] ?? data['displayName'] ?? data['name'] ?? 'Kullanıcı').toString()).trim().isEmpty
            ? 'Kullanıcı'
            : (data['username'] ?? data['displayName'] ?? data['name']).toString().trim(),
        photoUrl: (data['photoURL'] ?? data['photoUrl'] ?? '').toString(),
        city: (data['city'] ?? data['cityName'] ?? '').toString(),
        totalPoints: totalPoints,
        weeklyPoints: weeklyPoints,
        monthlyPoints: monthlyPoints,
        trustScorePercent: trustScorePercent,
        trustTotalVotes: trustTotalVotes,
        level: finalLevel,
      );
    });
  }
}
