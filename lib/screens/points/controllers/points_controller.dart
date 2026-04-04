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

  static const Map<String, String> _taskTitles = {
    'price_entry': 'Fiyat Bildir',
    'price_verify': 'Doğrula',
    'comment': 'Yorum Yap',
    'photo_bonus': 'Fotoğraf Ekle',
  };

  static const Map<String, String> _taskDescriptions = {
    'price_entry': 'Fiyat bildirimi yap',
    'price_verify': 'Fiyat doğrulaması yap',
    'comment': 'Ürüne yorum bırak',
    'photo_bonus': 'Fotoğraflı katkı yap',
  };

  static const Map<String, IconData> _taskIcons = {
    'price_entry': Icons.sell_rounded,
    'price_verify': Icons.verified_rounded,
    'comment': Icons.chat_bubble_rounded,
    'photo_bonus': Icons.photo_camera_rounded,
  };

  static const Map<String, Color> _taskIconBackgrounds = {
    'price_entry': Color(0xFFFFE7D1),
    'price_verify': Color(0xFFDFF3FF),
    'comment': Color(0xFFEAE7FF),
    'photo_bonus': Color(0xFFE5F7E8),
  };

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

          final dailyGoals = goals.rules.map((rule) {
            final eventType = rule.eventType;
            final target = rule.dailyCap ?? 0;
            final current = goals.counts[eventType] ?? 0;
            return DailyTask(
              title: _taskTitles[eventType] ?? rule.title,
              description: _taskDescriptions[eventType] ?? rule.description,
              reward: rule.points,
              current: current,
              target: target,
              icon: _taskIcons[eventType] ?? Icons.bolt_rounded,
              iconBackground: _taskIconBackgrounds[eventType] ?? const Color(0xFFECEFF1),
            );
          }).toList();

          return PointsState(
            totalPoints: summary.totalPoints,
            currentLevelName: summary.finalLevelLabel,
            pointsThisWeek: summary.pointsThisWeek,
            nextLevelTargetPoints: summary.nextLevelTarget,
            streakDays: summary.streakDays,
            levelProgressPercent: summary.levelProgress,
            pointsRemainingToNextLevel: summary.pointsToNextLevel,
            dailyGoals: dailyGoals,
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
      if (user == null) return Stream.error(StateError('unauthenticated'));
      return ref.watch(pointsControllerProvider).streamState(user.uid).handleError((error, stackTrace) {
        if (kDebugMode) debugPrint('pointsStateProvider error: $error');
      });
    },
    loading: () => const Stream.empty(),
    error: (error, stackTrace) {
      if (kDebugMode) debugPrint('pointsStateProvider auth error: $error');
      return Stream.error(error, stackTrace);
    },
  );
});
