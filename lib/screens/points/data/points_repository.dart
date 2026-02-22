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
    return summaryRef.snapshots().asyncMap((_) async {
      final profile = await _pointsService.streamUserProfile(uid).first;
      // Puan ekranı tek kaynaktan (points system) beslensin.
      final totalPoints = profile.totalPoints;
      final pointsThisWeek = profile.weeklyPoints;
      final streakDays = profile.streakDays;
      final levelName = profile.level;

      final nextLevelTarget = profile.nextLevel?.minPoints ?? (totalPoints + profile.remainingForNextLevel);
      final pointsToNextLevel = profile.remainingForNextLevel;
      final levelProgress = profile.progress.clamp(0.0, 1.0);

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
    final dayKey = DateFormat('yyyyMMdd').format(date);
    final goalsRef = _firestore.collection('users').doc(uid).collection('points_daily').doc(dayKey);
    return goalsRef.snapshots().map((doc) {
      final data = doc.data() ?? const <String, dynamic>{};
      final counts = Map<String, dynamic>.from(data['counts'] as Map? ?? const {});
      return DailyGoalsData(
        reportPriceDone: (counts['price_entry'] as num?)?.toInt() ?? 0,
        verifyPriceDone: (counts['price_verify'] as num?)?.toInt() ?? 0,
        commentDone: (counts['comment'] as num?)?.toInt() ?? 0,
        reportPriceTarget: 2,
        verifyPriceTarget: 5,
        commentTarget: 1,
      );
    });
  }

  Stream<List<DailyTask>> streamLeaderboardStub() {
    return const Stream<List<DailyTask>>.empty();
  }
}
