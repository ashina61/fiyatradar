import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/leaderboard_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/leaderboard_service.dart';
import 'auth_provider.dart';

enum LeaderboardFilter { global, city }
enum LeaderboardPeriod { week, month }

final leaderboardFilterProvider = StateProvider<LeaderboardFilter>((ref) => LeaderboardFilter.global);
final leaderboardPeriodProvider = StateProvider<LeaderboardPeriod>((ref) => LeaderboardPeriod.week);

class _CurrentUserCity {
  const _CurrentUserCity({required this.code, required this.name});

  final String? code;
  final String? name;
}

final _currentUserCityProvider = StreamProvider<_CurrentUserCity?>((ref) {
  final authAsync = ref.watch(authStateProvider);
  return authAsync.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().map((doc) {
        final data = doc.data() ?? <String, dynamic>{};
        final cityCode = (data['cityCode'] ?? '').toString().trim();
        final cityName = (data['cityName'] ?? data['city'] ?? '').toString().trim();
        if (cityCode.isEmpty && cityName.isEmpty) return null;
        return _CurrentUserCity(
          code: cityCode.isEmpty ? null : cityCode,
          name: cityName.isEmpty ? null : cityName,
        );
      });
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

final _leaderboardServiceProvider = Provider<LeaderboardService>((ref) => LeaderboardService());

final leaderboardStreamProvider = StreamProvider.family<List<UserLeaderboardItem>, LeaderboardFilter>((ref, filter) {
  final city = ref.watch(_currentUserCityProvider).valueOrNull;
  final period = ref.watch(leaderboardPeriodProvider);

  return ref.read(_leaderboardServiceProvider).streamLeaderboard(
        cityOnly: filter == LeaderboardFilter.city,
        monthly: period == LeaderboardPeriod.month,
        cityCode: city?.code,
        cityName: city?.name,
      );
});
