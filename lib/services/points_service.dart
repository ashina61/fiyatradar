import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

class PointsRule {
  const PointsRule({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.dailyCap,
    required this.active,
    required this.eventType,
  });

  final String id;
  final String title;
  final String description;
  final int points;
  final int? dailyCap;
  final bool active;
  final String eventType;

  factory PointsRule.fromMap(Map<String, dynamic> map) => PointsRule(
        id: (map['id'] ?? '').toString(),
        title: (map['title'] ?? '').toString(),
        description: (map['description'] ?? '').toString(),
        points: (map['points'] as num?)?.toInt() ?? 0,
        dailyCap: (map['dailyCap'] as num?)?.toInt(),
        active: (map['active'] as bool?) ?? true,
        eventType: (map['eventType'] ?? '').toString(),
      );
}

class PointsLevel {
  const PointsLevel({
    required this.id,
    required this.title,
    required this.minPoints,
    required this.maxPoints,
    required this.colorKey,
  });

  final String id;
  final String title;
  final int minPoints;
  final int? maxPoints;
  final String colorKey;

  bool includes(int points) => points >= minPoints && (maxPoints == null || points <= maxPoints!);

  factory PointsLevel.fromMap(Map<String, dynamic> map) => PointsLevel(
        id: (map['id'] ?? '').toString(),
        title: (map['title'] ?? '').toString(),
        minPoints: (map['minPoints'] as num?)?.toInt() ?? 0,
        maxPoints: (map['maxPointsOrNull'] as num?)?.toInt(),
        colorKey: (map['colorKey'] ?? 'standard').toString(),
      );
}

class UserPointsProfile {
  const UserPointsProfile({
    required this.uid,
    required this.totalPoints,
    required this.level,
    required this.streakDays,
    required this.trustScore,
    required this.levels,
  });

  final String uid;
  final int totalPoints;
  final String level;
  final int streakDays;
  final int trustScore;
  final List<PointsLevel> levels;

  PointsLevel? get currentLevel => levels.firstWhere((e) => e.includes(totalPoints), orElse: () => levels.first);

  PointsLevel? get nextLevel {
    final sorted = [...levels]..sort((a, b) => a.minPoints.compareTo(b.minPoints));
    for (final level in sorted) {
      if (level.minPoints > totalPoints) return level;
    }
    return null;
  }

  int get remainingForNextLevel => math.max(0, (nextLevel?.minPoints ?? totalPoints) - totalPoints);

  double get progress {
    final current = currentLevel;
    if (current == null) return 0;
    final next = nextLevel;
    if (next == null) return 1;
    final range = next.minPoints - current.minPoints;
    if (range <= 0) return 1;
    return ((totalPoints - current.minPoints) / range).clamp(0, 1);
  }
}

class PointsBadge {
  const PointsBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.unlockCondition,
    required this.isActive,
    this.isUnlocked = false,
    this.progress = 0,
  });

  final String id;
  final String title;
  final String description;
  final String iconKey;
  final String unlockCondition;
  final bool isActive;
  final bool isUnlocked;
  final int progress;
}

class PointsActivityItem {
  const PointsActivityItem({
    required this.id,
    required this.type,
    required this.points,
    required this.createdAt,
    required this.meta,
  });

  final String id;
  final String type;
  final int points;
  final DateTime createdAt;
  final Map<String, dynamic> meta;
}

class PointsService {
  PointsService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');

  Future<void> ensurePointsDefaultsSeeded() async {
    await _firestore.collection('points_rules').doc('default').set({
      'title': 'Default Points Rules',
      'updatedAt': FieldValue.serverTimestamp(),
      'rules': [
        {
          'id': 'price_add',
          'title': 'Fiyat Ekleme',
          'description': 'Onaylanan her fiyat gönderimi için +5 puan. Günlük en fazla 10 gönderim puanlanır.',
          'points': 5,
          'dailyCap': 10,
          'active': true,
          'eventType': 'price_add',
        },
        {
          'id': 'verification',
          'title': 'Fiyat Doğrulama',
          'description': 'Başkalarının fiyatlarını doğruladığında +2 puan. Günlük en fazla 30 doğrulama puanlanır.',
          'points': 2,
          'dailyCap': 30,
          'active': true,
          'eventType': 'verification',
        },
        {
          'id': 'comment',
          'title': 'Yorum',
          'description': '12+ karakter yorum başına +1 puan. Günlük en fazla 20 yorum puanlanır.',
          'points': 1,
          'dailyCap': 20,
          'active': true,
          'eventType': 'comment',
        },
        {
          'id': 'report_confirmed',
          'title': 'Yanlış Fiyat Bildirme',
          'description': 'Bildirimin onaylandığında +3 puan kazanırsın.',
          'points': 3,
          'dailyCap': null,
          'active': true,
          'eventType': 'report_confirmed',
        },
        {
          'id': 'invite_reward',
          'title': 'Arkadaş Daveti',
          'description': 'Davet ettiğin kullanıcı ilk katkısını yaptığında +50 puan.',
          'points': 50,
          'dailyCap': null,
          'active': true,
          'eventType': 'invite_reward',
        },
        {
          'id': 'streak_bonus',
          'title': 'Seri Bonusu',
          'description': 'Günün ilk anlamlı katkısında +2 seri bonusu.',
          'points': 2,
          'dailyCap': 1,
          'active': true,
          'eventType': 'streak_bonus',
        },
      ],
    }, SetOptions(merge: true));

    await _firestore.collection('points_levels').doc('default').set({
      'levels': [
        {'id': 'standard', 'title': 'Standart', 'minPoints': 0, 'maxPointsOrNull': 499, 'colorKey': 'standard'},
        {'id': 'silver', 'title': 'Gümüş', 'minPoints': 500, 'maxPointsOrNull': 1499, 'colorKey': 'silver'},
        {'id': 'gold', 'title': 'Altın', 'minPoints': 1500, 'maxPointsOrNull': 3999, 'colorKey': 'gold'},
        {'id': 'diamond', 'title': 'Elmas', 'minPoints': 4000, 'maxPointsOrNull': null, 'colorKey': 'diamond'},
      ],
    }, SetOptions(merge: true));

    final badgeCol = _firestore.collection('badges').doc('default').collection('badges');
    final badgeSnap = await badgeCol.limit(1).get();
    if (badgeSnap.docs.isEmpty) {
      final batch = _firestore.batch();
      final seed = [
        {
          'id': 'badge_first_price',
          'title': 'İlk Katkı',
          'description': 'İlk fiyatını ekledin.',
          'iconKey': 'spark',
          'unlockCondition': 'total price_add count >= 1',
          'isActive': true,
        },
        {
          'id': 'badge_verifier_10',
          'title': 'Doğrulayıcı',
          'description': '10 fiyat doğruladın.',
          'iconKey': 'shield_check',
          'unlockCondition': 'total verification count >= 10',
          'isActive': true,
        },
        {
          'id': 'badge_streak_7',
          'title': 'Seri Ustası',
          'description': '7 gün üst üste katkı yaptın.',
          'iconKey': 'flame',
          'unlockCondition': 'streakDays >= 7',
          'isActive': true,
        },
        {
          'id': 'badge_points_100',
          'title': '100 Puan',
          'description': '100 puana ulaştın.',
          'iconKey': 'star',
          'unlockCondition': 'totalPoints >= 100',
          'isActive': true,
        },
        {
          'id': 'badge_trust_50',
          'title': 'Güvenilir Katılımcı',
          'description': 'Güven puanın %50 üzerine çıktı.',
          'iconKey': 'verified',
          'unlockCondition': 'trustScore >= 50',
          'isActive': true,
        },
      ];
      for (final badge in seed) {
        batch.set(badgeCol.doc(badge['id'] as String), badge);
      }
      await batch.commit();
    }
  }

  Stream<List<PointsRule>> streamPointsRules() {
    return _firestore.collection('points_rules').doc('default').snapshots().map((doc) {
      final rules = (doc.data()?['rules'] as List?) ?? const [];
      return rules
          .whereType<Map>()
          .map((e) => PointsRule.fromMap(Map<String, dynamic>.from(e)))
          .where((e) => e.active)
          .toList();
    });
  }

  Stream<List<PointsLevel>> streamLevels() {
    return _firestore.collection('points_levels').doc('default').snapshots().map((doc) {
      final levels = (doc.data()?['levels'] as List?) ?? const [];
      return levels.whereType<Map>().map((e) => PointsLevel.fromMap(Map<String, dynamic>.from(e))).toList()
        ..sort((a, b) => a.minPoints.compareTo(b.minPoints));
    });
  }

  Stream<UserPointsProfile> streamUserProfile(String uid) {
    return _users.doc(uid).snapshots().asyncMap((doc) async {
      final levels = await streamLevels().first;
      final data = doc.data() ?? <String, dynamic>{};
      return UserPointsProfile(
        uid: uid,
        totalPoints: (data['totalPoints'] as num?)?.toInt() ?? 0,
        level: (data['level'] ?? 'Standart').toString(),
        streakDays: (data['streakDays'] as num?)?.toInt() ?? 0,
        trustScore: (data['trustScore'] as num?)?.toInt() ?? 0,
        levels: levels,
      );
    });
  }

  Stream<List<PointsBadge>> streamBadges(String uid) {
    final defsStream = _firestore.collection('badges').doc('default').collection('badges').snapshots();
    final userStream = _firestore.collection('user_badges').doc(uid).collection('items').snapshots();
    return defsStream.asyncMap((defs) async {
      final user = await userStream.first;
      final unlocked = {for (final doc in user.docs) doc.id: doc.data()};
      return defs.docs.map((doc) {
        final data = doc.data();
        final userBadge = unlocked[doc.id];
        return PointsBadge(
          id: doc.id,
          title: (data['title'] ?? '').toString(),
          description: (data['description'] ?? '').toString(),
          iconKey: (data['iconKey'] ?? 'star').toString(),
          unlockCondition: (data['unlockCondition'] ?? '').toString(),
          isActive: (data['isActive'] as bool?) ?? true,
          isUnlocked: (userBadge?['isUnlocked'] as bool?) ?? false,
          progress: (userBadge?['progress'] as num?)?.toInt() ?? 0,
        );
      }).where((e) => e.isActive).toList();
    });
  }

  Stream<List<PointsActivityItem>> streamActivity(String uid) {
    return _firestore
        .collection('points_activity')
        .doc(uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs
            .map(
              (doc) => PointsActivityItem(
                id: doc.id,
                type: (doc.data()['type'] ?? '').toString(),
                points: (doc.data()['points'] as num?)?.toInt() ?? 0,
                createdAt: (doc.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                meta: Map<String, dynamic>.from(doc.data()['meta'] as Map? ?? const {}),
              ),
            )
            .toList());
  }

  Future<bool> awardEvent({
    required String uid,
    required String eventType,
    required Map<String, dynamic> meta,
    bool checkDailyCap = true,
    bool ensureUniqueByMeta = false,
  }) async {
    await ensurePointsDefaultsSeeded();
    final rule = await _ruleFor(eventType);
    if (rule == null || !rule.active || rule.points <= 0) return false;

    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    if (checkDailyCap && rule.dailyCap != null) {
      final todayCount = await _firestore
          .collection('points_activity')
          .doc(uid)
          .collection('items')
          .where('type', isEqualTo: eventType)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .count()
          .get();
      if ((todayCount.count ?? 0) >= rule.dailyCap!) return false;
    }

    if (ensureUniqueByMeta && meta['priceEntryId'] != null) {
      final existing = await _firestore
          .collection('points_activity')
          .doc(uid)
          .collection('items')
          .where('type', isEqualTo: eventType)
          .where('meta.priceEntryId', isEqualTo: meta['priceEntryId'])
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return false;
    }

    await _firestore.runTransaction((txn) async {
      final userRef = _users.doc(uid);
      final userSnap = await txn.get(userRef);
      final userData = userSnap.data() ?? <String, dynamic>{};
      final currentPoints = (userData['totalPoints'] as num?)?.toInt() ?? 0;
      final newTotal = currentPoints + rule.points;
      final activityRef = _firestore.collection('points_activity').doc(uid).collection('items').doc();
      txn.set(activityRef, {
        'type': eventType,
        'points': rule.points,
        'createdAt': FieldValue.serverTimestamp(),
        'meta': meta,
      });

      final currentLevel = await _levelForPoints(newTotal);
      txn.set(userRef, {
        'totalPoints': FieldValue.increment(rule.points),
        'level': currentLevel?.title ?? 'Standart',
      }, SetOptions(merge: true));
    });

    await _updateStreak(uid, eventType: eventType);
    await _evaluateBadges(uid);
    return true;
  }

  Future<void> markReferralFirstContribution(String uid) async {
    final userDoc = await _users.doc(uid).get();
    final code = (userDoc.data()?['referredBy'] ?? '').toString();
    if (code.isEmpty) return;

    final inviteRef = _firestore.collection('referrals').doc(code).collection('invites').doc(uid);
    await _firestore.runTransaction((txn) async {
      final inviteSnap = await txn.get(inviteRef);
      if (!inviteSnap.exists) return;
      final data = inviteSnap.data() ?? <String, dynamic>{};
      if (data['status'] == 'rewarded') return;
      txn.set(inviteRef, {'status': 'first_contribution_done'}, SetOptions(merge: true));
    });

    final inviteDoc = await inviteRef.get();
    final inviterUid = (inviteDoc.data()?['inviterUid'] ?? '').toString();
    if (inviterUid.isEmpty) return;
    final rewarded = await awardEvent(uid: inviterUid, eventType: 'invite_reward', meta: {'invitedUid': uid});
    if (rewarded) {
      await inviteRef.set({'status': 'rewarded'}, SetOptions(merge: true));
    }
  }

  Future<void> handleReportConfirmed(String reportId) async {
    final report = await _firestore.collection('reports').doc(reportId).get();
    final data = report.data() ?? <String, dynamic>{};
    final reporterUid = (data['reporterUid'] ?? data['reporterUserId'] ?? '').toString();
    if (reporterUid.isEmpty) return;
    await awardEvent(
      uid: reporterUid,
      eventType: 'report_confirmed',
      meta: {'reportId': reportId, 'priceEntryId': data['priceEntryId'] ?? data['targetId']},
      ensureUniqueByMeta: true,
    );
  }

  Future<PointsRule?> _ruleFor(String eventType) async {
    final rules = await streamPointsRules().first;
    for (final rule in rules) {
      if (rule.eventType == eventType) return rule;
    }
    return null;
  }

  Future<List<PointsLevel>> _levels() async => streamLevels().first;

  Future<PointsLevel?> _levelForPoints(int points) async {
    final levels = await _levels();
    for (final level in levels) {
      if (level.includes(points)) return level;
    }
    return levels.isEmpty ? null : levels.first;
  }

  Future<void> _updateStreak(String uid, {required String eventType}) async {
    if (eventType != 'price_add' && eventType != 'verification') return;
    final now = DateTime.now();
    final today = _dateKey(now);
    final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
    final userRef = _users.doc(uid);

    var shouldAwardStreakBonus = false;
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(userRef);
      final data = snap.data() ?? <String, dynamic>{};
      final lastActiveDate = (data['lastActiveDate'] ?? '').toString();
      var streak = (data['streakDays'] as num?)?.toInt() ?? 0;
      if (lastActiveDate == today) {
        return;
      } else if (lastActiveDate == yesterday) {
        streak += 1;
      } else {
        streak = 1;
      }
      shouldAwardStreakBonus = true;
      txn.set(userRef, {'lastActiveDate': today, 'streakDays': streak}, SetOptions(merge: true));
    });

    if (shouldAwardStreakBonus) {
      await awardEvent(uid: uid, eventType: 'streak_bonus', meta: {'day': today}, checkDailyCap: true);
    }
  }

  Future<void> _evaluateBadges(String uid) async {
    final profile = await streamUserProfile(uid).first;
    final activity = await streamActivity(uid).first;
    final allActivity = await _firestore.collection('points_activity').doc(uid).collection('items').get();
    final priceCount = allActivity.docs.where((d) => d.data()['type'] == 'price_add').length;
    final verificationCount = allActivity.docs.where((d) => d.data()['type'] == 'verification').length;

    final defs = await _firestore.collection('badges').doc('default').collection('badges').where('isActive', isEqualTo: true).get();
    for (final doc in defs.docs) {
      var unlock = false;
      switch (doc.id) {
        case 'badge_first_price':
          unlock = priceCount >= 1;
          break;
        case 'badge_verifier_10':
          unlock = verificationCount >= 10;
          break;
        case 'badge_streak_7':
          unlock = profile.streakDays >= 7;
          break;
        case 'badge_points_100':
          unlock = profile.totalPoints >= 100;
          break;
        case 'badge_trust_50':
          unlock = profile.trustScore >= 50;
          break;
      }
      final userBadgeRef = _firestore.collection('user_badges').doc(uid).collection('items').doc(doc.id);
      final current = await userBadgeRef.get();
      if (unlock && !current.exists) {
        await userBadgeRef.set({'isUnlocked': true, 'unlockedAt': FieldValue.serverTimestamp(), 'progress': 100});
      } else if (!unlock && !current.exists) {
        await userBadgeRef.set({'isUnlocked': false, 'progress': activity.length});
      }
    }
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
