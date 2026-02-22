import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers/auth_provider.dart';
import '../data/points_repository.dart';
import '../models/points_models.dart';

class PointsController {
  const PointsController(this._repository);

  final PointsRepository _repository;

  Stream<PointsState> streamState(String uid, {DateTime? date}) {
    final today = date ?? DateTime.now();
    return _repository.streamPointsSummary(uid).asyncExpand((summary) {
      return _repository.streamDailyGoals(uid, today).asyncExpand((goals) {
        return _repository.streamActivities(uid).map((activities) {
          final formattedActivities = activities
              .map((item) => PointsActivity(
                    type: item.type,
                    title: item.title,
                    subtitle: item.subtitle,
                    points: item.points,
                    createdAt: DateFormat('dd.MM.yyyy HH:mm').format(item.createdAt.toLocal()),
                  ))
              .toList();

          return PointsState(
            totalPoints: summary.totalPoints,
            currentLevelName: summary.levelName,
            pointsThisWeek: summary.pointsThisWeek,
            nextLevelTargetPoints: summary.nextLevelTarget,
            streakDays: summary.streakDays,
            levelProgressPercent: summary.levelProgress,
            pointsRemainingToNextLevel: summary.pointsToNextLevel,
            dailyGoals: [
              DailyTask(
                title: 'Fiyat Bildir',
                description: '2 fiyat bildirimi yap',
                reward: 20,
                current: goals.reportPriceDone,
                target: goals.reportPriceTarget,
                icon: Icons.sell_rounded,
                iconBackground: const Color(0xFFFFE7D1),
              ),
              DailyTask(
                title: 'Doğrula',
                description: '5 fiyatı doğrula',
                reward: 10,
                current: goals.verifyPriceDone,
                target: goals.verifyPriceTarget,
                icon: Icons.verified_rounded,
                iconBackground: const Color(0xFFDFF3FF),
              ),
              DailyTask(
                title: 'Yorum Yap',
                description: '1 ürüne yorum bırak',
                reward: 5,
                current: goals.commentDone,
                target: goals.commentTarget,
                icon: Icons.chat_bubble_rounded,
                iconBackground: const Color(0xFFEAE7FF),
              ),
            ],
            activities: formattedActivities,
            trustScore: summary.trustScore,
            trustTotalVotes: summary.trustTotalVotes,
            requiredMinTrust: summary.requiredMinTrust,
            isTrustGated: summary.isTrustGated,
            finalLevelLabel: summary.finalLevelLabel,
            trustLabel: summary.trustLabel,
            nextLevelName: summary.nextLevelName,
          );
        });
      });
    });
  }
}

final pointsRepositoryProvider = Provider<PointsRepository>((ref) {
  return PointsRepository();
});

final pointsControllerProvider = Provider<PointsController>((ref) {
  final repository = ref.watch(pointsRepositoryProvider);
  return PointsController(repository);
});

final pointsStateProvider = StreamProvider<PointsState>((ref) {
  final authAsync = ref.watch(authStateProvider);
  return authAsync.when(
    data: (user) {
      if (user == null) return Stream.value(PointsState.placeholder);
      return ref.watch(pointsControllerProvider).streamState(user.uid).handleError((error, stackTrace) {
        debugPrint('pointsStateProvider error: $error');
      });
    },
    loading: () => Stream.value(PointsState.placeholder),
    error: (error, stackTrace) {
      debugPrint('pointsStateProvider auth error: $error');
      return Stream.value(PointsState.placeholder);
    },
  );
});
