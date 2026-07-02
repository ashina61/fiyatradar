import 'package:cloud_firestore/cloud_firestore.dart';

/// FiyatRadar level / rank sistemi.
///
/// Puan birikimine göre kullanıcıya kademe atar; her kademenin Türkçe bir
/// adı ve eşik puanı var. UI tarafı bu listeyi kullanarak ilerleme barı
/// üretir; rules tarafı puanın delta'sını zaten +50 ile sınırlandırdığı
/// için level "manipüle" edilemez.
class FRLevel {
  final int index;
  final String name;
  final int minPoints;

  const FRLevel({
    required this.index,
    required this.name,
    required this.minPoints,
  });
}

class FRLevels {
  static const List<FRLevel> all = <FRLevel>[
    FRLevel(index: 0, name: 'Yeni Avcı', minPoints: 0),
    FRLevel(index: 1, name: 'Mahalle Gözcüsü', minPoints: 100),
    FRLevel(index: 2, name: 'İlçe Avcısı', minPoints: 300),
    FRLevel(index: 3, name: 'Bölge Uzmanı', minPoints: 750),
    FRLevel(index: 4, name: 'Şehir Sentinel', minPoints: 1500),
    FRLevel(index: 5, name: 'Radar Pilotu', minPoints: 3000),
    FRLevel(index: 6, name: 'Topluluk Mimarı', minPoints: 6000),
  ];

  static FRLevel forPoints(int points) {
    var current = all.first;
    for (final l in all) {
      if (points >= l.minPoints) current = l;
    }
    return current;
  }

  static FRLevel? nextOf(FRLevel current) {
    final i = current.index + 1;
    if (i >= all.length) return null;
    return all[i];
  }
}

/// Aksiyon tabanlı rozet kataloğu.
///
/// Her rozet bir id'ye ve bir "earn" kuralına sahip. Kullanıcının
/// `users/{uid}.badges` array'inde id stringleri saklanıyor; UI bu listeyi
/// FRBadges.all ile cross-reference edip kazanılmış olanları gösteriyor.
class FRBadge {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int rewardPoints;

  const FRBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.rewardPoints,
  });
}

class FRBadges {
  // Stat-tabanlı rozetler. Sıra ile okunur — eşik geçildiyse kazanıldı.
  static const FRBadge firstReport = FRBadge(
    id: 'first_report',
    name: 'İlk fiyat',
    description: 'İlk bölgesel fiyatını bildirdin.',
    emoji: '🎯',
    rewardPoints: 10,
  );
  static const FRBadge tenReports = FRBadge(
    id: 'ten_reports',
    name: 'Düzenli avcı',
    description: '10 farklı fiyat bildirimi yaptın.',
    emoji: '🛒',
    rewardPoints: 25,
  );
  static const FRBadge fiftyReports = FRBadge(
    id: 'fifty_reports',
    name: 'Bölge uzmanı',
    description: '50 fiyat bildirimi · topluluğa ciddi katkı.',
    emoji: '🧭',
    rewardPoints: 50,
  );
  static const FRBadge firstVerify = FRBadge(
    id: 'first_verify',
    name: 'İlk doğrulama',
    description: 'Birinin fiyatını "ben de gördüm" ile doğruladın.',
    emoji: '✅',
    rewardPoints: 5,
  );
  static const FRBadge tenVerifies = FRBadge(
    id: 'ten_verifies',
    name: 'Mukayese ustası',
    description: '10 farklı fiyatı doğruladın.',
    emoji: '🛡',
    rewardPoints: 20,
  );
  static const FRBadge firstPhoto = FRBadge(
    id: 'first_photo',
    name: 'Kanıtlayıcı',
    description: 'İlk fotoğraflı bildirimi yolladın.',
    emoji: '📷',
    rewardPoints: 10,
  );
  static const FRBadge streak3 = FRBadge(
    id: 'streak_3',
    name: 'Üçüncü gün',
    description: '3 gün üst üste katkı yaptın.',
    emoji: '🔥',
    rewardPoints: 10,
  );
  static const FRBadge streak7 = FRBadge(
    id: 'streak_7',
    name: 'Tam hafta',
    description: '7 gün streak yaptın.',
    emoji: '⚡',
    rewardPoints: 25,
  );
  static const FRBadge streak30 = FRBadge(
    id: 'streak_30',
    name: 'Aylık avcı',
    description: '30 gün streak — efsane.',
    emoji: '🏆',
    rewardPoints: 100,
  );

  static const List<FRBadge> all = <FRBadge>[
    firstReport,
    tenReports,
    fiftyReports,
    firstVerify,
    tenVerifies,
    firstPhoto,
    streak3,
    streak7,
    streak30,
  ];

  static FRBadge? byId(String id) {
    for (final b in all) {
      if (b.id == id) return b;
    }
    return null;
  }
}

/// Kullanıcı dokümanından okunan gamification snapshot.
class GamificationSnapshot {
  final int points;
  final int contributions;
  final int verifyContributions;
  final int photoContributions;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastContributionDay;
  final Set<String> badges;

  const GamificationSnapshot({
    required this.points,
    required this.contributions,
    required this.verifyContributions,
    required this.photoContributions,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastContributionDay,
    required this.badges,
  });

  factory GamificationSnapshot.fromMap(Map<String, dynamic> m) {
    final ts = m['lastContributionDay'];
    DateTime? lastDay;
    if (ts is Timestamp) lastDay = ts.toDate();
    if (ts is String) lastDay = DateTime.tryParse(ts);
    return GamificationSnapshot(
      points: (m['points'] as num?)?.toInt() ?? 0,
      contributions: (m['contributions'] as num?)?.toInt() ?? 0,
      verifyContributions:
          (m['verifyContributions'] as num?)?.toInt() ?? 0,
      photoContributions:
          (m['photoContributions'] as num?)?.toInt() ?? 0,
      currentStreak: (m['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (m['longestStreak'] as num?)?.toInt() ?? 0,
      lastContributionDay: lastDay,
      badges: ((m['badges'] as List?) ?? const [])
          .map((e) => e.toString())
          .toSet(),
    );
  }

  FRLevel get level => FRLevels.forPoints(points);

  /// 0..1 — bir sonraki seviyeye olan ilerleme.
  double get levelProgress {
    final next = FRLevels.nextOf(level);
    if (next == null) return 1;
    final span = (next.minPoints - level.minPoints).toDouble();
    if (span <= 0) return 1;
    return ((points - level.minPoints) / span).clamp(0.0, 1.0);
  }

  /// Streak şu an aktif mi (bugün veya dün katkı varsa)?
  bool get streakActive {
    if (currentStreak <= 0) return false;
    final last = lastContributionDay;
    if (last == null) return false;
    final today = _todayUtc();
    final lastDay = DateTime.utc(last.year, last.month, last.day);
    final diff = today.difference(lastDay).inDays;
    return diff <= 1;
  }

  static DateTime _todayUtc() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day);
  }
}

/// Streak tracker — client-side. Cloud Function ileride server-driven
/// versiyonu yazılana kadar bu utility geçerli kabul edilir.
class StreakCalculator {
  /// Yeni katkı geldiğinde mevcut snapshot'tan beklenen yeni streak
  /// değerlerini üretir. Üst sınırlar Firestore rules tarafında
  /// `hasSafeStreakBadgeMutation` ile korunur (currentStreak ≤ prev+1,
  /// longestStreak monotonik, rozet yalnız bilinen id ve silinemez).
  ///
  /// Mantık:
  ///   - Aynı gün ikinci katkı → streak değişmez.
  ///   - Bir önceki gün → streak +1.
  ///   - 2+ gün ara → streak 1'e reset.
  static ({int currentStreak, int longestStreak, DateTime today})
      advance({
    required int currentStreak,
    required int longestStreak,
    required DateTime? lastContributionDay,
  }) {
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    int next;
    if (lastContributionDay == null) {
      next = 1;
    } else {
      final lastDay = DateTime.utc(
        lastContributionDay.year,
        lastContributionDay.month,
        lastContributionDay.day,
      );
      final diff = today.difference(lastDay).inDays;
      if (diff == 0) {
        next = currentStreak <= 0 ? 1 : currentStreak;
      } else if (diff == 1) {
        next = currentStreak + 1;
      } else {
        next = 1;
      }
    }
    final longest = next > longestStreak ? next : longestStreak;
    return (currentStreak: next, longestStreak: longest, today: today);
  }
}
