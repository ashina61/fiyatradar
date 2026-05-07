import 'package:flutter/material.dart';

import '../models/price_reporting.dart';
import '../state/app_state.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';

/// Bölge katkıcısı paneli — kullanıcıyı motive etmek için "bölgemde 4.
/// sıradayım, 2 kişi öndeyim" duygusunu vermek üzere yapılandırıldı.
///
/// Veri kaynağı: `priceReports` son 30 gün, cityId+districtId filtreli.
/// Sıralama AppState._aggregateContributors → score = report + 0.5*photo.
class RegionalLeaderboardScreen extends StatelessWidget {
  const RegionalLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final city = (state.cityName ?? '').trim();
    final district = (state.districtName ?? '').trim();
    final hasRegion = city.isNotEmpty && district.isNotEmpty;
    final myUid = state.user?.uid ?? '';

    return Scaffold(
      backgroundColor: FR.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                FRIconChip(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: FRPageHeader(
                overline: 'BÖLGEMDE',
                title: 'Katkı sıralaması',
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: !hasRegion
                  ? _NoRegion()
                  : StreamBuilder<List<RegionalContributorScore>>(
                      stream: state.watchRegionalContributorBoard(
                        city: city,
                        district: district,
                      ),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting &&
                            !snap.hasData) {
                          return const Padding(
                            padding: EdgeInsets.fromLTRB(20, 4, 20, 24),
                            child: FRSkeletonList(
                              count: 6,
                              itemHeight: 64,
                              radius: 14,
                            ),
                          );
                        }
                        final list =
                            snap.data ?? const <RegionalContributorScore>[];
                        if (list.isEmpty) {
                          return _EmptyBoard(district: district, city: city);
                        }
                        final myIndex = myUid.isEmpty
                            ? -1
                            : list.indexWhere((c) => c.userId == myUid);
                        return ListView(
                          padding: EdgeInsets.fromLTRB(
                              20, 4, 20, frBottomScrollPadding(context)),
                          children: [
                            _MyRankCard(
                              region: '$district / $city',
                              myIndex: myIndex,
                              total: list.length,
                              myScore:
                                  myIndex >= 0 ? list[myIndex] : null,
                            ),
                            const SizedBox(height: 16),
                            FRSectionHead(
                              eyebrow: 'SON 30 GÜN',
                              title: 'Top katkıcılar',
                              action: Text(
                                '${list.length} kişi',
                                style: frText(11, FontWeight.w800,
                                    color: FR.ink3),
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (var i = 0; i < list.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _BoardRow(
                                  rank: i + 1,
                                  score: list[i],
                                  isMe: list[i].userId == myUid,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyRankCard extends StatelessWidget {
  const _MyRankCard({
    required this.region,
    required this.myIndex,
    required this.total,
    required this.myScore,
  });
  final String region;
  final int myIndex;
  final int total;
  final RegionalContributorScore? myScore;

  @override
  Widget build(BuildContext context) {
    final myRank = myIndex >= 0 ? myIndex + 1 : null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FR.surfaceHi, FR.surfaceLo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: FRRad.all(FRRad.xl),
        border: Border.all(color: FR.goldDeep.withOpacity(.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SENİN POZİSYONUN',
              style: frOverline(color: FR.gold, size: 9.5)),
          const SizedBox(height: 6),
          Text(region, style: frText(12, FontWeight.w700, color: FR.ink3)),
          const SizedBox(height: 12),
          if (myRank == null) ...[
            Text(
              'Bu bölgede henüz katkın yok',
              style: frDisplay(20, FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'İlk fiyatı sen ekle, sıralamayı aç.',
              style: frText(12.5, FontWeight.w600,
                  color: FR.ink3, height: 1.45),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$myRank.',
                    style: frDisplay(38, FontWeight.w800, color: FR.gold)),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('/ $total kişi',
                      style: frText(12.5, FontWeight.w800, color: FR.ink2)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${myScore!.reportCount} fiyat · ${myScore!.photoCount} fotoğraf · skor ${myScore!.score.toStringAsFixed(1)}',
              style: frText(12, FontWeight.w700, color: FR.ink3),
            ),
            const SizedBox(height: 8),
            if (myRank > 1)
              Text(
                '${myRank - 1} kişi önünde · onları geçmek için fiyat ekle.',
                style: frText(11.5, FontWeight.w700, color: FR.gold),
              )
            else
              Text(
                'Bölgenin 1 numarasısın 🎯',
                style: frText(12, FontWeight.w800, color: FR.good),
              ),
          ],
        ],
      ),
    );
  }
}

class _BoardRow extends StatelessWidget {
  const _BoardRow({
    required this.rank,
    required this.score,
    required this.isMe,
  });
  final int rank;
  final RegionalContributorScore score;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? FR.gold.withOpacity(.10) : FR.surface,
        borderRadius: FRRad.all(FRRad.m),
        border: Border.all(
          color: isMe ? FR.gold.withOpacity(.55) : FR.hairline,
          width: isMe ? 1.4 : 1.0,
        ),
      ),
      child: Row(children: [
        SizedBox(
          width: 34,
          child: Center(
            child: medal.isNotEmpty
                ? Text(medal, style: const TextStyle(fontSize: 18))
                : Text('$rank',
                    style: frText(13, FontWeight.w800,
                        color: isMe ? FR.gold : FR.ink2)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMe ? 'Sen · ${score.userDisplayName}' : score.userDisplayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: frText(13, FontWeight.w800,
                    color: isMe ? FR.gold : FR.ink),
              ),
              const SizedBox(height: 2),
              Text(
                '${score.reportCount} fiyat${score.photoCount > 0 ? " · ${score.photoCount} foto" : ""}',
                style: frText(11, FontWeight.w700, color: FR.ink3),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(score.score.toStringAsFixed(1),
            style: frText(13, FontWeight.w800, color: FR.gold)),
      ]),
    );
  }
}

class _NoRegion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined, size: 36, color: FR.ink3),
            const SizedBox(height: 12),
            Text('Önce bölgeni seç',
                style: frDisplay(18, FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Sıralamayı görmek için il/ilçe gerekli.',
              style: frText(12.5, FontWeight.w600, color: FR.ink3),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard({required this.district, required this.city});
  final String district;
  final String city;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 36, color: FR.gold),
            const SizedBox(height: 12),
            Text('Sıralama açılmadı',
                style: frDisplay(18, FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              '$district / $city için son 30 günde rapor yok.\n'
              'İlk fiyatı sen ekle, listenin en üstüne otur.',
              textAlign: TextAlign.center,
              style: frText(12.5, FontWeight.w600,
                  color: FR.ink3, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
