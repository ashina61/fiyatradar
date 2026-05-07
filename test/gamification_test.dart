import 'package:flutter_test/flutter_test.dart';

import 'package:fiyatradar/models/gamification.dart';

void main() {
  group('FRLevels', () {
    test('0 puan → Yeni Avcı', () {
      expect(FRLevels.forPoints(0).name, 'Yeni Avcı');
    });

    test('200 puan → Mahalle Gözcüsü', () {
      expect(FRLevels.forPoints(200).name, 'Mahalle Gözcüsü');
    });

    test('20000 puan → Topluluk Mimarı (max)', () {
      expect(FRLevels.forPoints(20000).name, 'Topluluk Mimarı');
    });

    test('nextOf last level returns null', () {
      final last = FRLevels.all.last;
      expect(FRLevels.nextOf(last), isNull);
    });
  });

  group('StreakCalculator', () {
    test('ilk katkı: streak=1', () {
      final r = StreakCalculator.advance(
        currentStreak: 0,
        longestStreak: 0,
        lastContributionDay: null,
      );
      expect(r.currentStreak, 1);
      expect(r.longestStreak, 1);
    });

    test('aynı gün ikinci katkı: streak değişmez', () {
      final today = DateTime.now().toUtc();
      final r = StreakCalculator.advance(
        currentStreak: 5,
        longestStreak: 7,
        lastContributionDay: today,
      );
      expect(r.currentStreak, 5);
      expect(r.longestStreak, 7);
    });

    test('bir gün önce katkı: streak +1', () {
      final yesterday = DateTime.now().toUtc().subtract(const Duration(days: 1));
      final r = StreakCalculator.advance(
        currentStreak: 5,
        longestStreak: 7,
        lastContributionDay: yesterday,
      );
      expect(r.currentStreak, 6);
      expect(r.longestStreak, 7);
    });

    test('iki gün ara: streak reset = 1', () {
      final twoDaysAgo =
          DateTime.now().toUtc().subtract(const Duration(days: 2));
      final r = StreakCalculator.advance(
        currentStreak: 9,
        longestStreak: 9,
        lastContributionDay: twoDaysAgo,
      );
      expect(r.currentStreak, 1);
      expect(r.longestStreak, 9);
    });

    test('yeni rekor: longestStreak güncellenir', () {
      final yesterday =
          DateTime.now().toUtc().subtract(const Duration(days: 1));
      final r = StreakCalculator.advance(
        currentStreak: 9,
        longestStreak: 9,
        lastContributionDay: yesterday,
      );
      expect(r.currentStreak, 10);
      expect(r.longestStreak, 10);
    });
  });

  group('GamificationSnapshot', () {
    test('streakActive: bugün katkı varsa aktif', () {
      final snap = GamificationSnapshot(
        points: 0,
        contributions: 1,
        verifyContributions: 0,
        photoContributions: 0,
        currentStreak: 1,
        longestStreak: 1,
        lastContributionDay: DateTime.now().toUtc(),
        badges: const {},
      );
      expect(snap.streakActive, isTrue);
    });

    test('streakActive: 2+ gün önceyse pasif', () {
      final snap = GamificationSnapshot(
        points: 0,
        contributions: 5,
        verifyContributions: 0,
        photoContributions: 0,
        currentStreak: 5,
        longestStreak: 5,
        lastContributionDay:
            DateTime.now().toUtc().subtract(const Duration(days: 3)),
        badges: const {},
      );
      expect(snap.streakActive, isFalse);
    });
  });
}
