import 'package:cloud_firestore/cloud_firestore.dart';

class UserLeaderboardItem {
  const UserLeaderboardItem({
    required this.uid,
    required this.name,
    required this.photoUrl,
    required this.weeklyPoints,
    required this.monthlyPoints,
    required this.totalPoints,
    required this.cityCode,
    required this.cityName,
  });

  final String uid;
  final String name;
  final String photoUrl;
  final int weeklyPoints;
  final int monthlyPoints;
  final int totalPoints;
  final String cityCode;
  final String cityName;

  factory UserLeaderboardItem.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final cityName = (data['cityName'] ?? data['city'] ?? '').toString();
    final cityCode = (data['cityCode'] ?? cityName).toString();
    return UserLeaderboardItem(
      uid: doc.id,
      name: (data['displayName'] ?? data['name'] ?? 'Kullanıcı').toString(),
      photoUrl: (data['photoURL'] ?? data['photoUrl'] ?? '').toString(),
      weeklyPoints: (data['weeklyPoints'] as num?)?.toInt() ?? 0,
      monthlyPoints: (data['monthlyPoints'] as num?)?.toInt() ?? 0,
      totalPoints: (data['totalPoints'] as num?)?.toInt() ?? (data['pointsTotal'] as num?)?.toInt() ?? 0,
      cityCode: cityCode,
      cityName: cityName,
    );
  }
}
