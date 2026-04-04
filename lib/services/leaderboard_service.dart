import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/leaderboard_item.dart';

class LeaderboardService {
  LeaderboardService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<UserLeaderboardItem>> streamLeaderboard({
    required bool cityOnly,
    required bool monthly,
    String? cityCode,
    String? cityName,
  }) {
    final orderField = monthly ? 'monthlyPoints' : 'weeklyPoints';

    int scoreFor(UserLeaderboardItem item) => monthly ? item.monthlyPoints : item.weeklyPoints;

    List<UserLeaderboardItem> parseDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
      final items = docs.map(UserLeaderboardItem.fromDoc).toList();
      items.sort((a, b) {
        final byScore = scoreFor(b).compareTo(scoreFor(a));
        if (byScore != 0) return byScore;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return items.where((item) => scoreFor(item) > 0).take(50).toList();
    }

    if (!cityOnly) {
      return _firestore.collection('users').orderBy(orderField, descending: true).limit(50).snapshots().map((snap) => parseDocs(snap.docs));
    }

    final normalizedCode = (cityCode ?? '').trim();
    final normalizedName = (cityName ?? '').trim();
    if (normalizedCode.isEmpty && normalizedName.isEmpty) {
      return Stream.value(const <UserLeaderboardItem>[]);
    }

    Stream<List<UserLeaderboardItem>> cityStream() async* {
      Query<Map<String, dynamic>> query;
      if (normalizedCode.isNotEmpty) {
        query = _firestore.collection('users').where('cityCode', isEqualTo: normalizedCode);
      } else {
        query = _firestore.collection('users').where('city', isEqualTo: normalizedName);
      }

      try {
        await for (final snap in query.orderBy(orderField, descending: true).limit(50).snapshots()) {
          yield parseDocs(snap.docs);
        }
      } catch (_) {
        await for (final snap in query.limit(120).snapshots()) {
          yield parseDocs(snap.docs);
        }
      }
    }

    return cityStream();
  }
}
