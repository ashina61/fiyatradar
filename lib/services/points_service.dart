import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../utils/elite_level_engine.dart';
import '../utils/level_config.dart';
import 'notification_service.dart';

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
    required this.trustTotalVotes,
    required this.weeklyPoints,
    required this.monthlyPoints,
    required this.levels,
  });

  final String uid;
  final int totalPoints;
  final String level;
  final int streakDays;
  final int trustScore;
  final int trustTotalVotes;
  final int weeklyPoints;
  final int monthlyPoints;
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
    required this.badgeDescription,
    required this.unlockedAt,
  });

  final String badgeId;
  final String badgeTitle;
  final String badgeDescription;
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

class WeeklyLeaderboardEntry {
  const WeeklyLeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.level,
    required this.weeklyPoints,
    required this.totalPoints,
  });

  final String uid;
  final String displayName;
  final String photoUrl;
  final String level;
  final int weeklyPoints;
  final int totalPoints;
}

class PointsService {
  PointsService({FirebaseFirestore? firestore, NotificationService? notificationService})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationService = notificationService ??
            NotificationService(firestore: firestore ?? FirebaseFirestore.instance);

  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');

  static const Map<String, Map<String, String>> _badgeDefinitions = {
    'first_price': {
      'title': 'İlk Fiyat',
      'description': 'İlk fiyat katkını yaptın.',
      'iconKey': 'spark',
      'unlockCondition': 'price_entry >= 1',
    },
    'price_hunter': {
      'title': 'Fiyat Avcısı',
      'description': '25 fiyat katkısı yaptın.',
      'iconKey': 'search',
      'unlockCondition': 'price_entry >= 25',
    },
    'price_master': {
      'title': 'Fiyat Ustası',
      'description': '100 fiyat katkısına ulaştın.',
      'iconKey': 'star',
      'unlockCondition': 'price_entry >= 100',
    },
    'trusted_contributor': {
      'title': 'Güvenilir Üye',
      'description': 'Güven puanın 40 ve üstüne çıktı.',
      'iconKey': 'shield_check',
      'unlockCondition': 'trustScore >= 40',
    },
    'elite_contributor': {
      'title': 'Elit Katkıcı',
      'description': 'Güven puanın 70 ve üstüne çıktı.',
      'iconKey': 'diamond',
      'unlockCondition': 'trustScore >= 70',
    },
    'admin_badge': {
      'title': 'Admin',
      'description': 'Yönetici hesabı rozeti.',
      'iconKey': 'crown',
      'unlockCondition': 'isAdmin == true',
    },
  };

  static const Map<String, int> _dailyCaps = {
    'price_entry': 20,
    'price_verify': 30,
    'photo_bonus': 10,
  };

  static const Map<String, int> _pointValues = {
    'price_entry': 10,
    'price_verify': 2,
    'photo_bonus': 5,
    'admin_bonus': 10,
    'comment': 3,
    'report_confirmed': 3,
    'invite_reward': 50,
    'daily_streak': 5,
    'alarm_set': 5,
    'stock_report': 2,
  };

  static Map<String, int> get pointValues => Map.unmodifiable(_pointValues);


  static const Map<String, String> _eventAliases = {
    'price_add': 'price_entry',
    'verification': 'price_verify',
    'verify_vote': 'price_verify',
    'streak_bonus': 'daily_streak',
  };

  Future<void> ensurePointsDefaultsSeeded() async {
    await _firestore.collection('points_rules').doc('default').set({
      'title': 'Default Points Rules',
      'updatedAt': FieldValue.serverTimestamp(),
      'rules': [
        {
          'id': 'price_entry',
          'title': 'Fiyat Girişi',
          'description': 'Fiyat ekleme başına +10 puan. Günlük en fazla 20 kez puanlanır.',
          'points': 10,
          'dailyCap': 20,
          'active': true,
          'eventType': 'price_entry',
        },
        {
          'id': 'price_verify',
          'title': 'Fiyat Doğrulama',
          'description': 'Doğrulama başına +2 puan. Günlük en fazla 30 kez puanlanır.',
          'points': 2,
          'dailyCap': 30,
          'active': true,
          'eventType': 'price_verify',
        },
        {
          'id': 'photo_bonus',
          'title': 'Foto Bonusu',
          'description': 'Fotoğraflı katkıda +5 bonus puan. Günlük en fazla 10 kez puanlanır.',
          'points': 5,
          'dailyCap': 10,
          'active': true,
          'eventType': 'photo_bonus',
        },
        {
          'id': 'admin_bonus',
          'title': 'Admin Bonusu',
          'description': 'Admin işlemleri için +10 puan.',
          'points': 10,
          'dailyCap': null,
          'active': true,
          'eventType': 'admin_bonus',
        },
      ],
    }, SetOptions(merge: true));

    final seededLevels = <Map<String, dynamic>>[];
    for (var i = 0; i < LevelConfig.levels.length; i++) {
      final item = LevelConfig.levels[i];
      final maxPoints = i == LevelConfig.levels.length - 1 ? null : LevelConfig.levels[i + 1].minPoints - 1;
      seededLevels.add({
        'id': item.levelKey,
        'title': item.label,
        'minPoints': item.minPoints,
        'maxPointsOrNull': maxPoints,
        'colorKey': item.levelKey,
      });
    }
    await _firestore.collection('points_levels').doc('default').set({'levels': seededLevels}, SetOptions(merge: true));

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
        PointsRule(id: 'price_entry', title: 'Fiyat Girişi', description: 'Fiyat ekleme başına +10 puan.', points: 10, dailyCap: 20, active: true, eventType: 'price_entry'),
        PointsRule(id: 'price_verify', title: 'Fiyat Doğrulama', description: 'Doğrulama başına +2 puan. Günlük en fazla 30 doğrulama puanlanır.', points: 2, dailyCap: 30, active: true, eventType: 'price_verify'),
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
      final totalPoints = _resolveUserTotalPoints(data);
      final weeklyPoints = (data['weeklyPoints'] as num?)?.toInt() ?? 0;
      final monthlyPoints = (data['monthlyPoints'] as num?)?.toInt() ?? 0;
      final trustMap = Map<String, dynamic>.from(data['trust'] as Map? ?? const {});
      final trustUpTotal = (data['trustVerifiedTotal'] as num?)?.toInt() ?? (trustMap['upTotal'] as num?)?.toInt() ?? 0;
      final trustDownTotal = (data['trustWrongTotal'] as num?)?.toInt() ?? (trustMap['downTotal'] as num?)?.toInt() ?? 0;
      final trustTotalVotes = (data['trustTotalVotes'] as num?)?.toInt() ?? (trustUpTotal + trustDownTotal);
      final trustScorePercent = ((data['trustScorePercent'] as num?)?.toDouble() ?? (data['reliabilityScore'] as num?)?.toDouble() ?? ((data['trustScore'] as num?)?.toDouble() ?? 0) * 100)
          .round()
          .clamp(0, 100);
      final level = _standardizeTierName((await _levelForPoints(totalPoints))?.title ?? 'Gözlemci');
      return UserPointsProfile(
        uid: uid,
        totalPoints: totalPoints,
        level: level,
        streakDays: (data['streakDays'] as num?)?.toInt() ?? 0,
        trustScore: trustScorePercent,
        trustTotalVotes: trustTotalVotes,
        weeklyPoints: weeklyPoints,
        monthlyPoints: monthlyPoints,
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
        final isShown = (data['isShown'] as bool?) ?? false;
        final seenAt = data['seenAt'] as Timestamp?;
        if (!isUnlocked || isShown || seenAt != null) continue;

        final def = defsMap[doc.id];
        if (def == null) continue;
        final unlockedAt = (data['unlockedAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        candidates.add(PendingBadgeUnlock(
          badgeId: doc.id,
          badgeTitle: (def['title'] ?? doc.id).toString(),
          badgeDescription: (def['description'] ?? '').toString(),
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
      'isShown': true,
    }, SetOptions(merge: true));
  }

  Stream<List<PointsActivityItem>> streamActivity(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('points_activity')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) => snap.docs
            .map(
              (doc) => PointsActivityItem(
                id: doc.id,
                type: (doc.data()['type'] ?? '').toString(),
                points: ((doc.data()['pointsDelta'] ?? doc.data()['points']) as num?)?.toInt() ?? 0,
                createdAt: (doc.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                meta: Map<String, dynamic>.from(doc.data()['meta'] as Map? ?? const {}),
              ),
            )
            .toList());
  }


  Stream<List<WeeklyLeaderboardEntry>> streamWeeklyLeaderboard({int limit = 10}) {
    return _users
        .orderBy('weeklyPoints', descending: true)
        .orderBy('totalPoints', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final activeWeekKey = _weekKey(DateTime.now());
      final ranked = snap.docs
          .map((doc) {
            final data = doc.data();
            final weekKey = (data['weeklyResetKey'] ?? data['weeklyPointsWeekKey'] ?? '').toString();
            final weeklyPoints = weekKey == activeWeekKey ? (data['weeklyPoints'] as num?)?.toInt() ?? 0 : 0;
            return WeeklyLeaderboardEntry(
              uid: doc.id,
              displayName: (data['username'] ?? data['displayName'] ?? data['name'] ?? 'Kullanıcı').toString(),
              photoUrl: (data['photoUrl'] ?? '').toString(),
              level: _standardizeTierName((data['level'] ?? data['levelName'] ?? 'Gözlemci').toString()),
              weeklyPoints: weeklyPoints,
              totalPoints: (data['totalPoints'] as num?)?.toInt() ?? 0,
            );
          })
          .where((entry) => entry.weeklyPoints > 0)
          .toList();

      ranked.sort((a, b) {
        final byWeekly = b.weeklyPoints.compareTo(a.weeklyPoints);
        if (byWeekly != 0) return byWeekly;
        return b.totalPoints.compareTo(a.totalPoints);
      });
      return ranked;
    });
  }

  Future<bool> awardEvent({
    required String uid,
    required String eventType,
    required Map<String, dynamic> meta,
    bool checkDailyCap = true,
    bool ensureUniqueByMeta = false,
  }) async {
    try {
      await ensurePointsDefaultsSeeded();
      final normalizedType = _normalizeEventType(eventType);
      final pointsDelta = _pointForEvent(normalizedType);
      if (pointsDelta <= 0) {
        if (kDebugMode) debugPrint('PointsService.awardEvent skipped unknown type: $eventType');
        return false;
      }

      final dayKey = DateFormat('yyyyMMdd').format(DateTime.now().toLocal());
      final activeWeekKey = _weekKey(DateTime.now());
      final userRef = _users.doc(uid);
      final dailyRef = userRef.collection('points_daily').doc(dayKey);
      final activityRef = _firestore.collection('points_activity').doc(uid).collection('items').doc();
      final userActivityRef = userRef.collection('points_activity').doc();
      final uniqueMetaId = meta['priceEntryId'] ?? meta['priceId'];
      final uniqueKey = ensureUniqueByMeta && uniqueMetaId != null
          ? '${normalizedType}_${uniqueMetaId}'
          : null;
      final uniqueRef = uniqueKey == null ? null : userRef.collection('points_event_uniques').doc(uniqueKey);
      final levels = await _levels();

      String? previousLevelName;
      String? nextLevelName;
      final awarded = await _firestore.runTransaction<bool>((txn) async {
        final dailySnap = await txn.get(dailyRef);
        final dailyData = dailySnap.data() ?? <String, dynamic>{};
        final counts = Map<String, dynamic>.from(dailyData['counts'] as Map? ?? const {});
        final currentCount = (counts[normalizedType] as num?)?.toInt() ?? 0;
        final cap = checkDailyCap ? _dailyCaps[normalizedType] : null;

        var shouldAwardPoints = true;
        if (cap != null && currentCount >= cap) {
          shouldAwardPoints = false;
        }

        if (uniqueRef != null) {
          final uniqueSnap = await txn.get(uniqueRef);
          if (uniqueSnap.exists) {
            shouldAwardPoints = false;
          } else {
            txn.set(uniqueRef, {
              'eventType': normalizedType,
              'meta': {'priceEntryId': uniqueMetaId},
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }

        final awardedDelta = shouldAwardPoints ? pointsDelta : 0;
        final userSnap = await txn.get(userRef);
        final userData = userSnap.data() ?? <String, dynamic>{};
        final currentPoints = _resolveUserTotalPoints(userData);
        final previousLevel = levels.firstWhere(
          (level) => level.includes(currentPoints),
          orElse: () => levels.first,
        );
        final newTotal = currentPoints + awardedDelta;
        final previousWeekKey = (userData['weeklyResetKey'] ?? userData['weeklyPointsWeekKey'] ?? '').toString();
        final currentWeeklyPoints = previousWeekKey == activeWeekKey ? (userData['weeklyPoints'] as num?)?.toInt() ?? 0 : 0;
        final now = DateTime.now();
        final activeMonthKey = DateFormat('yyyy-MM').format(now.toLocal());
        final previousMonthKey = (userData['monthlyResetKey'] ?? userData['monthlyPointsMonthKey'] ?? '').toString();
        final currentMonthlyPoints = previousMonthKey == activeMonthKey ? (userData['monthlyPoints'] as num?)?.toInt() ?? 0 : 0;
        final newWeeklyPoints = currentWeeklyPoints + awardedDelta;
        final newMonthlyPoints = currentMonthlyPoints + awardedDelta;
        final currentLevel = levels.firstWhere(
          (level) => level.includes(newTotal),
          orElse: () => levels.first,
        );

        if (shouldAwardPoints) {
          txn.set(
            dailyRef,
            {
              'counts.$normalizedType': FieldValue.increment(1),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        } else {
          txn.set(
            dailyRef,
            {
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }

        final activityPayload = {
          'type': normalizedType,
          'createdAt': FieldValue.serverTimestamp(),
          'pointsDelta': awardedDelta,
          'points': awardedDelta,
          'meta': {
            ...meta,
            if (!shouldAwardPoints) 'dailyCapReached': cap != null && currentCount >= cap,
            if (!shouldAwardPoints && uniqueRef != null) 'duplicateEvent': true,
          },
        };

        txn.set(activityRef, activityPayload);
        txn.set(userActivityRef, activityPayload);

        final standardizedLevel = _standardizeTierName(currentLevel.title);
        previousLevelName = _standardizeTierName(previousLevel.title);
        nextLevelName = standardizedLevel;
        txn.set(userRef, {
          'totalPoints': FieldValue.increment(awardedDelta),
          'pointsTotal': FieldValue.increment(awardedDelta),
          'points': FieldValue.increment(awardedDelta),
          'level': standardizedLevel,
          'levelName': standardizedLevel,
          'tierName': standardizedLevel,
          'eliteLevel': standardizedLevel,
          'weeklyPoints': newWeeklyPoints,
          'monthlyPoints': newMonthlyPoints,
          'weeklyResetKey': activeWeekKey,
          'weeklyPointsWeekKey': activeWeekKey,
          'monthlyResetKey': activeMonthKey,
          'monthlyPointsMonthKey': activeMonthKey,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return shouldAwardPoints;
      });

      if (!awarded) return false;
      await _updateStreak(uid, eventType: normalizedType);
      await _evaluateBadges(uid);
      final leveledUp = nextLevelName != null && previousLevelName != null && nextLevelName != previousLevelName;
      if (leveledUp) {
        await _notificationService.addNotification(
          NotificationItem(
            id: '',
            type: 'level_up',
            title: 'Rütbe Atladın! 👑',
            message: 'Tebrikler, ${nextLevelName!} rütbesine yükseldin.',
            isRead: false,
            createdAt: Timestamp.now(),
            metaData: {
              'userId': uid,
              'eventType': normalizedType,
              ...meta,
              'previousLevel': previousLevelName,
              'newLevel': nextLevelName,
            },
          ),
        );
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('PointsService.awardEvent failed for $eventType/$uid: $e');
      return false;
    }
  }

  String _normalizeEventType(String eventType) => _eventAliases[eventType] ?? eventType;

  int _pointForEvent(String eventType) {
    final mapped = _pointValues[eventType];
    if (mapped != null) return mapped;
    return 0;
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
    if (eventType != 'price_entry' && eventType != 'price_verify') return;
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
      await awardEvent(uid: uid, eventType: 'daily_streak', meta: {'day': today}, checkDailyCap: true);
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
    final totalPoints = _resolveUserTotalPoints(userData);
    final role = (userData['role'] ?? '').toString();
    final isAdmin = (userData['isAdmin'] as bool?) ?? role == 'admin';

    final level = await _levelForPoints(totalPoints);
    final standardizedTier = _standardizeTierName(level?.title ?? 'Gözlemci');
    final activitySnap = await _firestore.collection('points_activity').doc(uid).collection('items').get();
    final activityDocs = activitySnap.docs;
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    final currentMonthStart = DateTime(DateTime.now().year, DateTime.now().month);
    final weeklyPoints = activityDocs.fold<int>(0, (sum, doc) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (createdAt == null || createdAt.isBefore(oneWeekAgo)) return sum;
      final delta = ((data['pointsDelta'] ?? data['points']) as num?)?.toInt() ?? 0;
      return sum + delta;
    });
    final monthlyPoints = activityDocs.fold<int>(0, (sum, doc) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (createdAt == null || createdAt.isBefore(currentMonthStart)) return sum;
      final delta = ((data['pointsDelta'] ?? data['points']) as num?)?.toInt() ?? 0;
      return sum + delta;
    });

    await userRef.set({
      'totalPoints': totalPoints,
      'pointsTotal': totalPoints,
      'points': totalPoints,
      'level': standardizedTier,
      'levelName': standardizedTier,
      'tierName': standardizedTier,
      'eliteLevel': standardizedTier,
      'weeklyPoints': weeklyPoints,
      'monthlyPoints': monthlyPoints,
      'weeklyResetKey': _weekKey(DateTime.now()),
      'weeklyPointsWeekKey': _weekKey(DateTime.now()),
      'monthlyResetKey': DateFormat('yyyy-MM').format(DateTime.now().toLocal()),
      'monthlyPointsMonthKey': DateFormat('yyyy-MM').format(DateTime.now().toLocal()),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    final activityPriceCount = activityDocs.where((d) => (d.data()['type'] ?? '') == 'price_entry').length;
    final priceCount = math.max((userData['priceEntries'] as num?)?.toInt() ?? 0, activityPriceCount);
    final trustScore = (userData['trustScore'] as num?)?.toInt() ?? 0;

    final unlockMap = <String, bool>{
      'admin_badge': isAdmin || role == 'admin',
      'first_price': priceCount >= 1,
      'price_hunter': priceCount >= 25,
      'price_master': priceCount >= 100,
      'trusted_contributor': trustScore >= 40,
      'elite_contributor': trustScore >= 70,
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
        payload['isShown'] = false;
      }
      await ref.set(payload, SetOptions(merge: true));
    }
  }


  String _standardizeTierName(String rawTier) {
    final parsed = EliteLevelEngine.parseLevelLabel(rawTier);
    return EliteLevelEngine.getLevelStyle(parsed).label;
  }

  int _resolveUserTotalPoints(Map<String, dynamic> data) {
    final totalPoints = (data['totalPoints'] as num?)?.toInt();
    final pointsTotal = (data['pointsTotal'] as num?)?.toInt();
    final points = (data['points'] as num?)?.toInt();
    final candidates = [totalPoints, pointsTotal, points].whereType<int>().toList();
    if (candidates.isEmpty) return 0;
    return candidates.reduce(math.max);
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _weekKey(DateTime date) {
    final monday = DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
    final month = monday.month.toString().padLeft(2, '0');
    final day = monday.day.toString().padLeft(2, '0');
    return '${monday.year}-$month-$day';
  }
}
