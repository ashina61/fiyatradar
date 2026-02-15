import 'package:cloud_firestore/cloud_firestore.dart';

class UserPointsProfile {
  const UserPointsProfile({
    required this.uid,
    required this.totalPoints,
    required this.tier,
    required this.trustScorePercent,
    required this.thresholds,
  });

  final String uid;
  final int totalPoints;
  final String tier;
  final int? trustScorePercent;
  final Map<String, int> thresholds;

  String get nextTier {
    final sorted = thresholds.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    for (final entry in sorted) {
      if (entry.value > totalPoints) return entry.key;
    }
    return sorted.isNotEmpty ? sorted.last.key : 'Elmas';
  }

  int get nextTierTarget {
    final sorted = thresholds.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    for (final entry in sorted) {
      if (entry.value > totalPoints) return entry.value;
    }
    return sorted.isNotEmpty ? sorted.last.value : 1000;
  }

  int get currentTierFloor {
    final sorted = thresholds.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    var floor = 0;
    for (final entry in sorted) {
      if (entry.value <= totalPoints) {
        floor = entry.value;
      }
    }
    return floor;
  }

  int get remainingPoints => (nextTierTarget - totalPoints).clamp(0, nextTierTarget);

  double get ringProgress {
    final denominator = (nextTierTarget - currentTierFloor);
    if (denominator <= 0) return 1;
    final p = (totalPoints - currentTierFloor) / denominator;
    return p.clamp(0, 1);
  }
}

class PointsRule {
  const PointsRule({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.isActive,
    this.dailyLimit,
  });

  final String id;
  final String title;
  final String description;
  final int points;
  final bool isActive;
  final int? dailyLimit;
}

class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.requirementType,
    required this.requirementTarget,
    required this.isActive,
    this.tier,
    this.order = 0,
  });

  final String id;
  final String title;
  final String description;
  final String iconKey;
  final String requirementType;
  final int requirementTarget;
  final bool isActive;
  final String? tier;
  final int order;
}

class UserBadge {
  const UserBadge({
    required this.badgeId,
    required this.isEarned,
    this.earnedAt,
    this.progress,
  });

  final String badgeId;
  final bool isEarned;
  final DateTime? earnedAt;
  final int? progress;
}

class PointsBadgeView {
  const PointsBadgeView({
    required this.definition,
    required this.userBadge,
  });

  final BadgeDefinition definition;
  final UserBadge? userBadge;

  bool get isEarned => userBadge?.isEarned ?? false;
}

class PointsActivityItem {
  const PointsActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.points,
    required this.createdAt,
    required this.meta,
  });

  final String id;
  final String type;
  final String title;
  final int points;
  final DateTime createdAt;
  final Map<String, dynamic> meta;
}


class PointsActivityPage {
  const PointsActivityPage({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<PointsActivityItem> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
}

class PointsService {
  PointsService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const Map<String, int> _defaultThresholds = {
    'Standart': 0,
    'Gümüş': 200,
    'Altın': 500,
    'Elmas': 1000,
  };

  Stream<UserPointsProfile> getUserPointsProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data() ?? <String, dynamic>{};
      final rawThresholds = data['tierThresholds'] as Map<String, dynamic>?;
      final thresholds = <String, int>{
        ..._defaultThresholds,
        if (rawThresholds != null)
          ...rawThresholds.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0)),
      };
      return UserPointsProfile(
        uid: uid,
        totalPoints: (data['totalPoints'] as num?)?.toInt() ?? (data['points'] as num?)?.toInt() ?? 0,
        tier: (data['tier'] as String?) ?? 'Standart',
        trustScorePercent: (data['trustScorePercent'] as num?)?.toInt(),
        thresholds: thresholds,
      );
    });
  }

  Stream<List<PointsBadgeView>> streamBadges(String uid) {
    return _firestore.collection('user_badges').doc(uid).collection('items').snapshots().asyncMap((userSnapshot) async {
      final badgesSnapshot = await _firestore
          .collection('badges')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      final userBadges = {
        for (final doc in userSnapshot.docs)
          doc.id: UserBadge(
            badgeId: (doc.data()['badgeId'] as String?) ?? doc.id,
            isEarned: (doc.data()['isEarned'] as bool?) ?? true,
            earnedAt: (doc.data()['earnedAt'] as Timestamp?)?.toDate(),
            progress: (doc.data()['progress'] as num?)?.toInt(),
          ),
      };

      return badgesSnapshot.docs.map((doc) {
        final data = doc.data();
        final definition = BadgeDefinition(
          id: doc.id,
          title: (data['title'] as String?) ?? 'Rozet',
          description: (data['description'] as String?) ?? '',
          iconKey: (data['iconKey'] as String?) ?? 'bolt',
          requirementType: (data['requirementType'] as String?) ?? 'prices_added',
          requirementTarget: (data['requirementTarget'] as num?)?.toInt() ?? 1,
          tier: data['tier'] as String?,
          order: (data['order'] as num?)?.toInt() ?? 0,
          isActive: (data['isActive'] as bool?) ?? true,
        );
        return PointsBadgeView(definition: definition, userBadge: userBadges[doc.id]);
      }).toList();
    });
  }

  Stream<List<PointsRule>> streamPointsRules() {
    final defaultDocStream = _firestore.collection('points_rules').doc('default').snapshots();

    return defaultDocStream.map((doc) {
      final data = doc.data();
      if (data != null && data['rules'] is List) {
        return (data['rules'] as List)
            .map((item) => item as Map<String, dynamic>)
            .map(
              (rule) => PointsRule(
                id: (rule['id'] as String?) ?? '',
                title: (rule['title'] as String?) ?? 'Katkı',
                description: (rule['description'] as String?) ?? '',
                points: (rule['points'] as num?)?.toInt() ?? 0,
                dailyLimit: (rule['dailyLimit'] as num?)?.toInt(),
                isActive: (rule['isActive'] as bool?) ?? true,
              ),
            )
            .where((rule) => rule.isActive)
            .toList();
      }
      throw StateError('Kurallar bulunamadı');
    });
  }

  Future<PointsActivityPage> streamPointsActivity(
    String uid, {
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('points_activity')
        .doc(uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();

    final items = snapshot.docs
        .map(
          (doc) => PointsActivityItem(
            id: doc.id,
            type: (doc.data()['type'] as String?) ?? 'other',
            title: (doc.data()['title'] as String?) ?? 'Aktivite',
            points: (doc.data()['points'] as num?)?.toInt() ?? 0,
            createdAt: (doc.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            meta: (doc.data()['meta'] as Map<String, dynamic>?) ?? <String, dynamic>{},
          ),
        )
        .toList();

    return PointsActivityPage(
      items: items,
      lastDocument: snapshot.docs.isEmpty ? null : snapshot.docs.last,
      hasMore: snapshot.docs.length >= limit,
    );
  }

  Query<Map<String, dynamic>> pointsActivityQuery(String uid, {int limit = 20}) {
    return _firestore
        .collection('points_activity')
        .doc(uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(limit);
  }
}
