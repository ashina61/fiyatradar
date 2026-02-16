import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

enum LeaderboardFilter { global, city }
enum LeaderboardPeriod { week, month }

class UserLeaderboardItem {
  const UserLeaderboardItem({
    required this.uid,
    required this.name,
    required this.photoUrl,
    required this.weeklyPoints,
    required this.monthlyPoints,
    required this.reliabilityScore,
    required this.cityCode,
    required this.cityName,
  });

  final String uid;
  final String name;
  final String photoUrl;
  final int weeklyPoints;
  final int monthlyPoints;
  final int reliabilityScore;
  final String cityCode;
  final String cityName;

  factory UserLeaderboardItem.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final cityName = (data['cityName'] ?? data['city'] ?? '').toString();
    final cityCode = (data['cityCode'] ?? cityName).toString();
    return UserLeaderboardItem(
      uid: doc.id,
      name: (data['name'] ?? data['displayName'] ?? 'Kullanıcı').toString(),
      photoUrl: (data['photoUrl'] ?? '').toString(),
      weeklyPoints: (data['weeklyPoints'] as num?)?.toInt() ?? 0,
      monthlyPoints: (data['monthlyPoints'] as num?)?.toInt() ?? 0,
      reliabilityScore: (data['reliabilityScore'] as num?)?.toInt() ?? (data['trustScore'] as num?)?.toInt() ?? 0,
      cityCode: cityCode,
      cityName: cityName,
    );
  }
}

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

final leaderboardStreamProvider = StreamProvider.family<List<UserLeaderboardItem>, LeaderboardFilter>((ref, filter) {
  final firestore = FirebaseFirestore.instance;
  final period = ref.watch(leaderboardPeriodProvider);

  int scoreFor(UserLeaderboardItem item) {
    return period == LeaderboardPeriod.week ? item.weeklyPoints : item.monthlyPoints;
  }

  List<UserLeaderboardItem> parseDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final items = docs.map(UserLeaderboardItem.fromDoc).toList();
    items.sort((a, b) {
      final byScore = scoreFor(b).compareTo(scoreFor(a));
      if (byScore != 0) return byScore;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return items.take(50).toList();
  }

  if (filter == LeaderboardFilter.global) {
    final orderField = period == LeaderboardPeriod.week ? 'weeklyPoints' : 'monthlyPoints';
    return firestore
        .collection('users')
        .orderBy(orderField, descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => parseDocs(snap.docs));
  }

  final city = ref.watch(_currentUserCityProvider).valueOrNull;
  final cityCode = city?.code?.trim() ?? '';
  final cityName = city?.name?.trim() ?? '';
  if (cityCode.isEmpty && cityName.isEmpty) {
    return Stream.value(const <UserLeaderboardItem>[]);
  }

  final orderField = period == LeaderboardPeriod.week ? 'weeklyPoints' : 'monthlyPoints';

  Stream<List<UserLeaderboardItem>> cityStream() async* {
    Query<Map<String, dynamic>> query;
    if (cityCode.isNotEmpty) {
      query = firestore.collection('users').where('cityCode', isEqualTo: cityCode);
    } else {
      query = firestore.collection('users').where('cityName', isEqualTo: cityName);
    }

    final primaryQuery = query.orderBy(orderField, descending: true).limit(50).snapshots();

    try {
      await for (final snap in primaryQuery) {
        yield parseDocs(snap.docs);
      }
    } catch (_) {
      final fallbackQuery = query.limit(100).snapshots();
      await for (final snap in fallbackQuery) {
        yield parseDocs(snap.docs);
      }
    }
  }

  return cityStream();
});
