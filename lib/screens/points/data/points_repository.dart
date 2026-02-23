import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../services/points_service.dart';
import '../../../utils/elite_level_engine.dart';
import '../../../utils/trust_tier.dart';
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
    required this.trustScore,
    required this.trustTotalVotes,
    required this.requiredMinTrust,
    required this.isTrustGated,
    required this.finalLevelLabel,
    required this.trustLabel,
    required this.nextLevelName,
  });

  final int totalPoints;
  final String levelName;
  final int pointsThisWeek;
  final int streakDays;
  final int nextLevelTarget;
  final int pointsToNextLevel;
  final double levelProgress;
  final int trustScore;
  final int trustTotalVotes;
  final int requiredMinTrust;
  final bool isTrustGated;
  final String finalLevelLabel;
  final String trustLabel;
  final String nextLevelName;
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



class PointsActivityData {
  const PointsActivityData({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.createdAt,
  });

  final String type;
  final String title;
  final String subtitle;
  final int points;
  final DateTime createdAt;
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
      final trustScore = ((profile.trustScore as num?)?.toInt() ?? 0).clamp(0, 100);
      final trustTotalVotes = (profile.trustTotalVotes as num?)?.toInt() ?? 0;
      final levelEval = EliteLevelEngine.evaluate(
        totalPoints: totalPoints,
        trustPercent: trustScore,
        totalVotes: trustTotalVotes,
      );
      final trustTier = trustTierFromScore(trustScore);

      final nextLevelTarget = profile.nextLevel?.minPoints ?? (totalPoints + profile.remainingForNextLevel);
      final pointsToNextLevel = profile.remainingForNextLevel;
      final levelProgress = profile.progress.clamp(0.0, 1.0);

      return PointsSummaryData(
        totalPoints: totalPoints,
        levelName: EliteLevelEngine.getLevelStyle(levelEval.finalLevel).label,
        pointsThisWeek: pointsThisWeek,
        streakDays: streakDays,
        nextLevelTarget: nextLevelTarget,
        pointsToNextLevel: pointsToNextLevel,
        levelProgress: levelProgress,
        trustScore: trustScore,
        trustTotalVotes: trustTotalVotes,
        requiredMinTrust: levelEval.requiredMinTrust,
        isTrustGated: levelEval.isTrustGated,
        finalLevelLabel: EliteLevelEngine.getLevelStyle(levelEval.finalLevel).label,
        trustLabel: trustTier.label,
        nextLevelName: EliteLevelEngine.getLevelStyle(levelEval.nextPointsLevel).label,
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



  Stream<List<PointsActivityData>> streamActivities(String uid) {
    return _pointsService.streamActivity(uid).map((items) {
      return items.map((item) {
        final type = item.type;
        final map = _activityPresentation(type, item.meta);
        return PointsActivityData(
          type: type,
          title: map.$1,
          subtitle: map.$2,
          points: item.points,
          createdAt: item.createdAt,
        );
      }).toList();
    });
  }

  (String, String) _activityPresentation(String type, Map<String, dynamic> meta) {
    final market = (meta['marketName'] ?? meta['market'] ?? '').toString();
    final product = (meta['productName'] ?? meta['productTitle'] ?? '').toString();
    final pair = [market, product].where((e) => e.trim().isNotEmpty).join(' • ');

    switch (type) {
      case 'price_entry':
        return ('Fiyat bildirimi', pair.isEmpty ? 'Yeni fiyat eklendi' : pair);
      case 'price_verify':
        return ('Fiyat doğrulaması', pair.isEmpty ? 'Topluluk doğrulaması' : pair);
      case 'comment':
        return ('Yorum katkısı', pair.isEmpty ? 'Ürün yorumu paylaşıldı' : pair);
      case 'photo_bonus':
        return ('Foto bonusu', pair.isEmpty ? 'Fotoğraflı katkı' : pair);
      default:
        return ('Puan etkinliği', pair.isEmpty ? 'Topluluk katkısı' : pair);
    }
  }


  Stream<List<DailyTask>> streamLeaderboardStub() {
    return const Stream<List<DailyTask>>.empty();
  }
}
