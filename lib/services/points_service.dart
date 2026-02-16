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
    this.unlockedAt,
    this.seenAt,
  });

  final String id;
  final String title;
  final String description;
  final String iconKey;
  final String unlockCondition;
  final bool isActive;
  final bool isUnlocked;
  final int progress;
  final DateTime? unlockedAt;
  final DateTime? seenAt;
}

class PendingBadgeUnlock {
  const PendingBadgeUnlock({
    required this.badgeId,
    required this.badgeTitle,
    required this.unlockedAt,
  });

  final String badgeId;
  final String badgeTitle;
  final DateTime unlockedAt;
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

  static const Map<String, Map<String, String>> _badgeDefinitions = {
    'badge_admin': {
      'title': 'Admin',
      'description': 'Yönetici hesabı rozeti.',
      'iconKey': 'crown',
      'unlockCondition': 'user.role == "admin"',
    },
    'badge_first_price': {
      'title': 'İlk Katkı',
      'description': 'İlk fiyatını ekledin.',
      'iconKey': 'spark',
      'unlockCondition': 'user price_add count >= 1',
    },
    'badge_verifier_10': {
      'title': 'Doğrulayıcı',
      'description': '10 fiyat doğruladın.',
      'iconKey': 'shield_check',
      'unlockCondition': 'verification count >= 10',
    },
    'badge_streak_7': {
      'title': 'Seri Ustası',
      'description': '7 gün üst üste katkı yaptın.',
      'iconKey': 'flame',
      'unlockCondition': 'streakDays >= 7',
    },
    'badge_points_500': {
      'title': '500 Puan',
      'description': '500 puana ulaştın.',
      'iconKey': 'star',
      'unlockCondition': 'totalPoints >= 500',
    },
  };

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
    final batch = _firestore.batch();
    for (final entry in _badgeDefinitions.entries) {
      batch.set(badgeCol.doc(entry.key), {
        'id': entry.key,
        'title': entry.value['title'],
        'description': entry.value['description'],
        'iconKey': entry.value['iconKey'],
        'unlockCondition': entry.value['unlockCondition'],
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Stream<List<PointsRule>> streamPointsRules() {
    return _firestore.collection('points_rules').doc('default').snapshots().map((doc) {
      final rules = (doc.data()?['rules'] as List?) ?? const [];
      final parsed = rules
          .whereType<Map>()
          .map((e) => PointsRule.fromMap(Map<String, dynamic>.from(e)))
          .where((e) => e.active)
          .toList();
      if (parsed.isNotEmpty) return parsed;
      return const [
        PointsRule(id: 'price_add', title: 'Fiyat Ekleme', description: 'Onaylanan her fiyat gönderimi için +5 puan.', points: 5, dailyCap: 10, active: true, eventType: 'price_add'),
        PointsRule(id: 'verification', title: 'Fiyat Doğrulama', description: 'Fiyat doğrulama başına +2 puan. Günlük en fazla 30 doğrulama puanlanır.', points: 2, dailyCap: 30, active: true, eventType: 'verification'),
      ];
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
      final orderedDefs = defs.docs
          .where((doc) => _badgeDefinitions.containsKey(doc.id))
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      return orderedDefs.map((doc) {
        final data = doc.data();
        final userBadge = unlocked[doc.id] ?? const <String, dynamic>{};
        return PointsBadge(
          id: doc.id,
          title: (data['title'] ?? '').toString(),
          description: (data['description'] ?? '').toString(),
          iconKey: (data['iconKey'] ?? 'star').toString(),
          unlockCondition: (data['unlockCondition'] ?? '').toString(),
          isActive: (data['isActive'] as bool?) ?? true,
          isUnlocked: (userBadge['isUnlocked'] as bool?) ?? false,
          progress: (userBadge['progress'] as num?)?.toInt() ?? 0,
          unlockedAt: (userBadge['unlockedAt'] as Timestamp?)?.toDate(),
          seenAt: (userBadge['seenAt'] as Timestamp?)?.toDate(),
        );
      }).where((e) => e.isActive).toList();
    });
  }

  Stream<PendingBadgeUnlock?> streamLatestUnseenUnlockedBadge(String uid) {
    return _firestore.collection('user_badges').doc(uid).collection('items').snapshots().asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return null;

      final defs = await _firestore.collection('badges').doc('default').collection('badges').get();
      final defsMap = {for (final doc in defs.docs) doc.id: doc.data()};

      final candidates = <PendingBadgeUnlock>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final isUnlocked = (data['isUnlocked'] as bool?) ?? false;
        final seenAt = data['seenAt'] as Timestamp?;
        if (!isUnlocked || seenAt != null) continue;

        final def = defsMap[doc.id];
        if (def == null) continue;
        final unlockedAt = (data['unlockedAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        candidates.add(PendingBadgeUnlock(
          badgeId: doc.id,
          badgeTitle: (def['title'] ?? doc.id).toString(),
          unlockedAt: unlockedAt,
        ));
      }

      if (candidates.isEmpty) return null;
      candidates.sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
      return candidates.first;
    });
  }

  Future<void> acknowledgeBadgeUnlock({required String uid, required String badgeId}) async {
    await _firestore.collection('user_badges').doc(uid).collection('items').doc(badgeId).set({
      'seenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
    await recomputeUserGamification(uid);
  }

  Future<void> recomputeUserGamification(String uid) async {
    await ensurePointsDefaultsSeeded();

    final userRef = _users.doc(uid);
    final userDoc = await userRef.get();
    if (!userDoc.exists) return;

    final userData = userDoc.data() ?? const <String, dynamic>{};
    final totalPoints = (userData['totalPoints'] as num?)?.toInt() ??
        (userData['pointsTotal'] as num?)?.toInt() ??
        (userData['points'] as num?)?.toInt() ??
        0;
    final streakDays = (userData['streakDays'] as num?)?.toInt() ?? 0;
    final role = (userData['role'] ?? '').toString();
    final isAdmin = (userData['isAdmin'] as bool?) ?? role == 'admin';

    final level = await _levelForPoints(totalPoints);
    await userRef.set({
      'totalPoints': totalPoints,
      'pointsTotal': totalPoints,
      'points': totalPoints,
      'level': level?.title ?? 'Standart',
      'levelName': level?.title ?? 'Standart',
      'tierName': level?.title ?? 'Standart',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final activitySnap = await _firestore.collection('points_activity').doc(uid).collection('items').get();
    final activityDocs = activitySnap.docs;
    final activityPriceCount = activityDocs.where((d) => (d.data()['type'] ?? '') == 'price_add').length;
    final activityVerificationCount = activityDocs.where((d) => (d.data()['type'] ?? '') == 'verification').length;
    final priceCount = math.max((userData['priceEntries'] as num?)?.toInt() ?? 0, activityPriceCount);
    final verificationCount = math.max((userData['validations'] as num?)?.toInt() ?? 0, activityVerificationCount);

    final unlockMap = <String, bool>{
      'badge_admin': isAdmin || role == 'admin',
      'badge_first_price': priceCount >= 1,
      'badge_verifier_10': verificationCount >= 10,
      'badge_streak_7': streakDays >= 7,
      'badge_points_500': totalPoints >= 500,
    };

    final userBadgesRef = _firestore.collection('user_badges').doc(uid).collection('items');
    for (final entry in unlockMap.entries) {
      final ref = userBadgesRef.doc(entry.key);
      final snap = await ref.get();
      final wasUnlocked = (snap.data()?['isUnlocked'] as bool?) ?? false;
      final payload = <String, dynamic>{
        'isUnlocked': entry.value,
        'progress': entry.value ? 100 : 0,
      };
      if (entry.value && !wasUnlocked) {
        payload['unlockedAt'] = FieldValue.serverTimestamp();
        payload['seenAt'] = null;
      }
      await ref.set(payload, SetOptions(merge: true));
    }
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
