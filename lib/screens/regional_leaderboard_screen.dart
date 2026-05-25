import 'package:flutter/material.dart';

import '../models/price_reporting.dart';
import '../state/app_state.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';

/// Bölge katkıcısı paneli — kullanıcıyı motive etmek için "bölgemde 4.
/// sıradayım, 2 kişi öndeyim" duygusunu vermek üzere yapılandırıldı.
///
/// Veri kaynağı: `priceReports` son N gün, cityId/districtId filtreli.
/// Sıralama AppState._aggregateContributors → score = report + 0.5*photo.
///
/// Scope filtresi (Aşama 3):
///   • district  — yalnız ilçe (default)
///   • city      — kullanıcının ili
///   • turkey    — Türkiye geneli (Pro önerimi yapan auto top-100)
///
/// Window:
///   • 7d / 30d — segmented filter
enum LeaderboardScope { district, city, turkey }

class RegionalLeaderboardScreen extends StatefulWidget {
  const RegionalLeaderboardScreen({super.key});

  @override
  State<RegionalLeaderboardScreen> createState() =>
      _RegionalLeaderboardScreenState();
}

class _RegionalLeaderboardScreenState
    extends State<RegionalLeaderboardScreen> {
  LeaderboardScope _scope = LeaderboardScope.district;
  int _windowDays = 30;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final city = (state.cityName ?? '').trim();
    final district = (state.districtName ?? '').trim();
    final hasRegion = city.isNotEmpty && district.isNotEmpty;
    final myUid = state.user?.uid ?? '';
    // Pro: top-100 → 500 doc limitine çıkar; ücretsiz → top-50.
    final isPro = state.premium.isActive;
    final limit = isPro ? 500 : 200;

    String? streamCity;
    String? streamDistrict;
    switch (_scope) {
      case LeaderboardScope.district:
        streamCity = city;
        streamDistrict = district;
        break;
      case LeaderboardScope.city:
        streamCity = city;
        streamDistrict = null;
        break;
      case LeaderboardScope.turkey:
        streamCity = null;
        streamDistrict = null;
        break;
    }

    final scopeRequiresRegion =
        _scope == LeaderboardScope.district || _scope == LeaderboardScope.city;

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
                overline: 'KATKI SIRALAMASI',
                title: _scopeTitle(_scope, city, district),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ScopeBar(
                scope: _scope,
                windowDays: _windowDays,
                onScope: (s) => setState(() => _scope = s),
                onWindow: (d) => setState(() => _windowDays = d),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: scopeRequiresRegion && !hasRegion
                  ? _NoRegion()
                  : StreamBuilder<List<RegionalContributorScore>>(
                      stream: state.watchRegionalContributorBoard(
                        city: streamCity,
                        district: streamDistrict,
                        windowDays: _windowDays,
                        limit: limit,
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
                          return _EmptyBoard(
                            label: _scopeRegionLabel(_scope, city, district),
                          );
                        }
                        final myIndex = myUid.isEmpty
                            ? -1
                            : list.indexWhere((c) => c.userId == myUid);
                        // Top-N sınırı: ücretsiz kullanıcı top-50, Pro top-100.
                        final visibleLimit = isPro ? 100 : 50;
                        final visible =
                            list.take(visibleLimit).toList();
                        return ListView(
                          padding: EdgeInsets.fromLTRB(
                              20, 4, 20, frBottomScrollPadding(context)),
                          children: [
                            _MyRankCard(
                              region:
                                  _scopeRegionLabel(_scope, city, district),
                              myIndex: myIndex,
                              total: list.length,
                              myScore:
                                  myIndex >= 0 ? list[myIndex] : null,
                            ),
                            const SizedBox(height: 16),
                            FRSectionHead(
                              eyebrow: 'SON $_windowDays GÜN',
                              title: isPro
                                  ? 'Top ${visible.length}'
                                  : 'Top ${visible.length}',
                              action: Text(
                                '${list.length} kişi',
                                style: frText(11, FontWeight.w800,
                                    color: FR.ink3),
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (var i = 0; i < visible.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _BoardRow(
                                  rank: i + 1,
                                  score: visible[i],
                                  isMe: visible[i].userId == myUid,
                                  meIsPremium: isPro,
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
    required this.meIsPremium,
  });
  final int rank;
  final RegionalContributorScore score;
  final bool isMe;

  /// Oturum açmış kullanıcının canlı premium durumu. Kendi satırında, eski
  /// raporlarda `reporterIsPro` yazılmamış olsa bile yeni yükseltilmiş Pro
  /// rozetinin anında görünmesi için `score.isPro` ile OR'lanır.
  final bool meIsPremium;

  @override
  Widget build(BuildContext context) {
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '';
    // Mevcut FiyatRadar Pro rozeti (FRProBadge) — yeni rozet TASARLANMAZ,
    // uygulamadaki mevcut bileşen reuse edilir. Sıralamayı etkilemez; yalnız
    // kullanıcı adının yanında görsel işaret.
    final showPro = score.isPro || (isMe && meIsPremium);
    if (showPro) {
      debugPrint('LEADERBOARD_EXISTING_PRO_BADGE_RENDERED: ${score.userId}');
    }
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
              Row(
                children: [
                  Flexible(
                    child: Text(
                      isMe
                          ? 'Sen · ${score.userDisplayName}'
                          : score.userDisplayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: frText(13, FontWeight.w800,
                          color: isMe ? FR.gold : FR.ink),
                    ),
                  ),
                  if (showPro) ...[
                    const SizedBox(width: 6),
                    const FRProBadge(compact: true),
                  ],
                ],
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
  const _EmptyBoard({required this.label});
  final String label;

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
              '$label için seçili pencerede rapor yok.\n'
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

String _scopeTitle(LeaderboardScope s, String city, String district) {
  switch (s) {
    case LeaderboardScope.district:
      if (city.isEmpty || district.isEmpty) return 'Bölgemde';
      return '$district / $city';
    case LeaderboardScope.city:
      return city.isEmpty ? 'Şehrimde' : city;
    case LeaderboardScope.turkey:
      return 'Türkiye geneli';
  }
}

String _scopeRegionLabel(LeaderboardScope s, String city, String district) {
  switch (s) {
    case LeaderboardScope.district:
      if (city.isEmpty || district.isEmpty) return 'Bölgen';
      return '$district / $city';
    case LeaderboardScope.city:
      return city.isEmpty ? 'Şehrin' : city;
    case LeaderboardScope.turkey:
      return 'Türkiye';
  }
}

class _ScopeBar extends StatelessWidget {
  const _ScopeBar({
    required this.scope,
    required this.windowDays,
    required this.onScope,
    required this.onWindow,
  });
  final LeaderboardScope scope;
  final int windowDays;
  final ValueChanged<LeaderboardScope> onScope;
  final ValueChanged<int> onWindow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _scopeChip('İlçe', LeaderboardScope.district),
            _scopeChip('Şehir', LeaderboardScope.city),
            _scopeChip('Türkiye', LeaderboardScope.turkey),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _windowChip('7 gün', 7),
            _windowChip('30 gün', 30),
            _windowChip('90 gün', 90),
          ],
        ),
      ],
    );
  }

  Widget _scopeChip(String label, LeaderboardScope s) {
    final selected = scope == s;
    return InkWell(
      onTap: () => onScope(s),
      borderRadius: FRRad.all(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? FR.gold : FR.surface,
          borderRadius: FRRad.all(999),
          border: Border.all(color: selected ? FR.gold : FR.hairline),
        ),
        child: Text(label,
            style: frText(11.5, FontWeight.w800,
                color: selected ? FR.onGold : FR.ink2)),
      ),
    );
  }

  Widget _windowChip(String label, int days) {
    final selected = windowDays == days;
    return InkWell(
      onTap: () => onWindow(days),
      borderRadius: FRRad.all(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? FR.bgElev : FR.surface,
          borderRadius: FRRad.all(999),
          border: Border.all(
            color: selected ? FR.gold.withOpacity(.55) : FR.hairline,
          ),
        ),
        child: Text(label,
            style: frText(10.5, FontWeight.w800,
                color: selected ? FR.gold : FR.ink3)),
      ),
    );
  }
}
