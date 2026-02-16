import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

enum LeaderboardFilter { global, city }

class UserLeaderboardItem {
  const UserLeaderboardItem({
    required this.uid,
    required this.name,
    required this.photoUrl,
    required this.weeklyPoints,
    required this.reliabilityScore,
    required this.cityCode,
    required this.cityName,
  });

  final String uid;
  final String name;
  final String photoUrl;
  final int weeklyPoints;
  final int reliabilityScore;
  final String cityCode;
  final String cityName;

  factory UserLeaderboardItem.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return UserLeaderboardItem(
      uid: doc.id,
      name: (data['name'] ?? data['displayName'] ?? 'Kullanıcı').toString(),
      photoUrl: (data['photoUrl'] ?? '').toString(),
      weeklyPoints: (data['weeklyPoints'] as num?)?.toInt() ?? 0,
      reliabilityScore: (data['reliabilityScore'] as num?)?.toInt() ?? (data['trustScore'] as num?)?.toInt() ?? 0,
      cityCode: (data['cityCode'] ?? '').toString(),
      cityName: (data['cityName'] ?? '').toString(),
    );
  }
}

final leaderboardFilterProvider = StateProvider<LeaderboardFilter>((ref) => LeaderboardFilter.global);

final _currentUserCityCodeProvider = StreamProvider<String?>((ref) {
  final authAsync = ref.watch(authStateProvider);
  return authAsync.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().map((doc) {
        return (doc.data()?['cityCode'] ?? '').toString().trim().isEmpty
            ? null
            : (doc.data()?['cityCode'] ?? '').toString();
      });
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

final leaderboardStreamProvider = StreamProvider.family<List<UserLeaderboardItem>, LeaderboardFilter>((ref, filter) {
  final firestore = FirebaseFirestore.instance;

  List<UserLeaderboardItem> parseDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final items = docs.map(UserLeaderboardItem.fromDoc).toList();
    items.sort((a, b) {
      final byWeekly = b.weeklyPoints.compareTo(a.weeklyPoints);
      if (byWeekly != 0) return byWeekly;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return items.take(50).toList();
  }

  if (filter == LeaderboardFilter.global) {
    return firestore
        .collection('users')
        .orderBy('weeklyPoints', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => parseDocs(snap.docs));
  }

  final cityCode = ref.watch(_currentUserCityCodeProvider).valueOrNull;
  if (cityCode == null || cityCode.isEmpty) {
    return Stream.value(const <UserLeaderboardItem>[]);
  }

  Stream<List<UserLeaderboardItem>> cityStream() async* {
    final primaryQuery = firestore
        .collection('users')
        .where('cityCode', isEqualTo: cityCode)
        .orderBy('weeklyPoints', descending: true)
        .limit(50)
        .snapshots();

    try {
      await for (final snap in primaryQuery) {
        yield parseDocs(snap.docs);
      }
    } catch (_) {
      final fallbackQuery = firestore.collection('users').where('cityCode', isEqualTo: cityCode).limit(100).snapshots();
      await for (final snap in fallbackQuery) {
        yield parseDocs(snap.docs);
      }
    }
  }

  return cityStream();
});
