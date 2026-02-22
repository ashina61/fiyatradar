import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../services/points_service.dart';
import '../models/points_models.dart';

class PointsSummaryData {
  const PointsSummaryData({
    required this.totalPoints,
    required this.levelName,
    required this.pointsThisWeek,
    required this.streakDays,
    required this.nextLevelTarget,
    required this.pointsToNextLevel,
    required this.levelProgress,
  });

  final int totalPoints;
  final String levelName;
  final int pointsThisWeek;
  final int streakDays;
  final int nextLevelTarget;
  final int pointsToNextLevel;
  final double levelProgress;
}

class DailyGoalsData {
  const DailyGoalsData({
    required this.reportPriceDone,
    required this.verifyPriceDone,
    required this.commentDone,
    required this.reportPriceTarget,
    required this.verifyPriceTarget,
    required this.commentTarget,
  });

  final int reportPriceDone;
  final int verifyPriceDone;
  final int commentDone;
  final int reportPriceTarget;
  final int verifyPriceTarget;
  final int commentTarget;
}

class PointsRepository {
  PointsRepository({FirebaseFirestore? firestore, PointsService? pointsService})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _pointsService = pointsService ?? PointsService();

  final FirebaseFirestore _firestore;
  final PointsService _pointsService;

  Stream<PointsSummaryData> streamPointsSummary(String uid) {
    final summaryRef = _firestore.collection('users').doc(uid).collection('points_summary').doc('current');
    return summaryRef.snapshots().asyncMap((summaryDoc) async {
      final profile = await _pointsService.streamUserProfile(uid).first;
      final summaryData = summaryDoc.data() ?? const <String, dynamic>{};

      final totalPoints = (summaryData['totalPoints'] as num?)?.toInt() ?? profile.totalPoints;
      final pointsThisWeek = (summaryData['pointsThisWeek'] as num?)?.toInt() ?? profile.weeklyPoints;
      final streakDays = (summaryData['streakDays'] as num?)?.toInt() ?? profile.streakDays;
      final levelName = (summaryData['levelName'] ?? summaryData['level'] ?? profile.level).toString();

      final nextLevelTarget = (summaryData['nextLevelTarget'] as num?)?.toInt() ??
          (profile.nextLevel?.minPoints ?? (totalPoints + profile.remainingForNextLevel));
      final pointsToNextLevel =
          (summaryData['pointsToNextLevel'] as num?)?.toInt() ?? profile.remainingForNextLevel;
      final levelProgress = ((summaryData['levelProgress'] as num?)?.toDouble() ?? profile.progress).clamp(0.0, 1.0);

      return PointsSummaryData(
        totalPoints: totalPoints,
        levelName: levelName,
        pointsThisWeek: pointsThisWeek,
        streakDays: streakDays,
        nextLevelTarget: nextLevelTarget,
        pointsToNextLevel: pointsToNextLevel,
        levelProgress: levelProgress,
      );
    });
  }

  Stream<DailyGoalsData> streamDailyGoals(String uid, DateTime date) {
    final dayKey = DateFormat('yyyy-MM-dd').format(date);
    final goalsRef = _firestore.collection('users').doc(uid).collection('daily_goals').doc(dayKey);
    return goalsRef.snapshots().map((doc) {
      final data = doc.data() ?? const <String, dynamic>{};
      return DailyGoalsData(
        reportPriceDone: (data['reportPriceDone'] as num?)?.toInt() ?? 0,
        verifyPriceDone: (data['verifyPriceDone'] as num?)?.toInt() ?? 0,
        commentDone: (data['commentDone'] as num?)?.toInt() ?? 0,
        reportPriceTarget: (data['reportPriceTarget'] as num?)?.toInt() ?? 2,
        verifyPriceTarget: (data['verifyPriceTarget'] as num?)?.toInt() ?? 5,
        commentTarget: (data['commentTarget'] as num?)?.toInt() ?? 1,
      );
    });
  }

  Stream<List<DailyTask>> streamLeaderboardStub() {
    return const Stream<List<DailyTask>>.empty();
  }
}
