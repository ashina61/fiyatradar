import 'package:flutter/material.dart';

import '../../models/gamification.dart';
import '../../state/app_state.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../admin_screen.dart';
import '../login_screen.dart';
import '../paywall_screen.dart';
import '../regional_leaderboard_screen.dart';
import '../notifications_screen.dart';
import '../profile_screens.dart';
import '../product_request_screen.dart';
import '../watchlist_screen.dart';
import '../widgets/profile_avatar.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final isGuest = state.user?.isAnonymous ?? true;

    if (isGuest) {
      return const _GuestProfile();
    }

    final snap = state.gamification;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 14, 20, frBottomScrollPadding(context)),
        children: [
          FRPageHeader(
            overline: 'KİMLİK · GÜVEN · KATKI',
            title: 'Profil',
            trailing: FRIconChip(
              icon: Icons.settings_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsHubScreen()),
              ),
            ),
          ),
          const SizedBox(height: FRSpace.l),
          // Sayfanın tek baskın bloğu: koyu espresso kimlik hero'su.
          // Eski akış liste başlamadan 5 ayrı kart yığıyordu (kimlik + güven
          // + seviye + sıralama + premium) ve dördü altın çerçeveliydi —
          // design-language.md'nin "kart mezarlığı" yasağının ta kendisi.
          _IdentityCard(state: state),
          const SizedBox(height: FRSpace.m),
          // Güven + seviye + seri tek sakin kartta: hepsi "itibar" sinyali,
          // üçü de ayrı progress-bar kartı olarak yarışıyordu.
          _ReputationCard(state: state, snap: snap),
          const SizedBox(height: FRSpace.m),
          // Sayfadaki tek altın an — premium bunu hak ediyor.
          _PremiumCta(state: state),
          const SizedBox(height: FRSpace.xxl),
          const FRSectionHead(eyebrow: 'TAKİP', title: 'Radar takvimin'),
          const SizedBox(height: FRSpace.m),
          _ListGroup(
            items: [
              _ListItem(
                icon: Icons.bookmark_rounded,
                title: 'Takiplerim',
                subtitle:
                    '${state.favorites.length} favori · ${state.productAlerts.length} alarm',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const WatchlistScreen()),
                ),
              ),
              _ListItem(
                icon: Icons.local_offer_outlined,
                title: 'Katkılarım',
                subtitle: '${state.contributions} fiyat paylaştın',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ContributionsScreen()),
                ),
              ),
              _ListItem(
                icon: Icons.workspace_premium_outlined,
                title: 'Rozetler',
                subtitle:
                    '${snap.badges.length} / ${FRBadges.all.length} rozet kazandın',
                onTap: () => _showBadgesSheet(context, snap),
              ),
              // Bağımsız altın çerçeveli kart yerine liste satırı — bu bir
              // gezinme hedefi, spot ışığı değil.
              _ListItem(
                icon: Icons.emoji_events_outlined,
                title: 'Bölgemde sıralamam',
                subtitle: _regionLabel(state),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RegionalLeaderboardScreen()),
                ),
              ),
              _ListItem(
                icon: Icons.inbox_rounded,
                title: 'Bildirim merkezi',
                subtitle: state.unreadNotificationCount > 0
                    ? '${state.unreadNotificationCount} okunmamış'
                    : 'Hepsi okunmuş',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: FRSpace.xxl),
          const FRSectionHead(eyebrow: 'HESAP', title: 'Ayarlar'),
          const SizedBox(height: FRSpace.m),
          _ListGroup(
            items: [
              _ListItem(
                icon: Icons.person_outline_rounded,
                title: 'Profil bilgileri',
                subtitle: state.username,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProfileInfoScreen()),
                ),
              ),
              _ListItem(
                icon: Icons.notifications_none_rounded,
                title: 'Bildirim tercihleri',
                subtitle: state.pushNotificationsEnabled ? 'Açık' : 'Kapalı',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationPrefsScreen()),
                ),
              ),
              const _ThemeListItem(),
              _ListItem(
                icon: Icons.assignment_add,
                title: 'Ürün talebi oluştur',
                subtitle: 'Kataloğa olmayan bir ürünü öner',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProductRequestScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: FRSpace.xl),
          if (state.isAdmin)
            _AdminCta(onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                )),
          if (!state.isAdmin) const SizedBox(height: 14),
          InkWell(
            onTap: () => _confirmLogout(context, state),
            borderRadius: FRRad.all(FRRad.m),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FR.bad.withOpacity(.08),
                borderRadius: FRRad.all(FRRad.m),
                border: Border.all(color: FR.bad.withOpacity(.3)),
              ),
              child: Text(
                'Çıkış yap',
                style: frText(13, FontWeight.w800, color: FR.bad),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showBadgesSheet(BuildContext context, GamificationSnapshot snap) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: FR.bg,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _BadgesSheet(snap: snap),
  );
}

/// Rozet listesi + seçili rozetin "nasıl kazanılır" detayını sheet'in
/// İÇİNDE gösteren panel. Eskiden bir rozete basınca açıklama SnackBar ile
/// ekranın altında çıkıyordu ama sheet açıkken o alan görünmüyordu; artık
/// seçilen rozetin detayı chip'lerin hemen altında inline açılıyor.
class _BadgesSheet extends StatefulWidget {
  const _BadgesSheet({required this.snap});
  final GamificationSnapshot snap;

  @override
  State<_BadgesSheet> createState() => _BadgesSheetState();
}

class _BadgesSheetState extends State<_BadgesSheet> {
  late FRBadge _selected;

  @override
  void initState() {
    super.initState();
    // Varsayılan seçim: ilk kazanılmış rozet, yoksa listenin ilki.
    _selected = FRBadges.all.firstWhere(
      (b) => widget.snap.badges.contains(b.id),
      orElse: () => FRBadges.all.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final snap = widget.snap;
    final earnedSelected = snap.badges.contains(_selected.id);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rozetler', style: frDisplay(22, FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '${snap.badges.length} / ${FRBadges.all.length} rozet kazandın',
              style: frText(12, FontWeight.w600, color: FR.ink3),
            ),
            const SizedBox(height: 6),
            Text(
              'Bir rozete dokun, nasıl kazanıldığını gör.',
              style: frText(11.5, FontWeight.w600, color: FR.ink3),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FRBadges.all
                  .map((b) => _BadgeChip(
                        badge: b,
                        earned: snap.badges.contains(b.id),
                        selected: b.id == _selected.id,
                        onTap: () => setState(() => _selected = b),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _BadgeDetail(badge: _selected, earned: earnedSelected),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seçili rozetin detay kartı: emoji, ad, kazanım durumu, ödül puanı ve
/// "nasıl kazanılır" açıklaması.
class _BadgeDetail extends StatelessWidget {
  const _BadgeDetail({required this.badge, required this.earned});
  final FRBadge badge;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(badge.id),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FR.surfaceHi, FR.surfaceLo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(
          color: earned ? FR.gold.withOpacity(.45) : FR.hairline,
        ),
        boxShadow: earned
            ? frGoldGlow(opacity: .12)
            : frShadow(blur: 18, y: 9, opacity: .07),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: earned ? FR.gold.withOpacity(.16) : FR.bgElev,
                  borderRadius: FRRad.all(14),
                  border: Border.all(
                    color: earned ? FR.gold.withOpacity(.45) : FR.hairline,
                  ),
                ),
                child: Text(badge.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(badge.name, style: frText(15, FontWeight.w800)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          earned
                              ? Icons.verified_rounded
                              : Icons.lock_outline_rounded,
                          size: 13,
                          color: earned ? FR.good : FR.ink3,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          earned ? 'Kazanıldı' : 'Henüz kazanılmadı',
                          style: frText(11, FontWeight.w800,
                              color: earned ? FR.good : FR.ink3),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: FR.gold.withOpacity(.16),
                  borderRadius: FRRad.all(999),
                  border: Border.all(color: FR.gold.withOpacity(.4)),
                ),
                child: Text('+${badge.rewardPoints} PT',
                    style: frText(11, FontWeight.w800, color: FR.gold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('NASIL KAZANILIR', style: frOverline(color: FR.ink3, size: 9.5)),
          const SizedBox(height: 5),
          Text(
            badge.description,
            style: frText(12.5, FontWeight.w600, color: FR.ink2, height: 1.45),
          ),
        ],
      ),
    );
  }
}

/// Confirms a logout request before tearing down the session, so a stray
/// tap on the destructive CTA doesn't drop the user back to the login
/// screen unexpectedly.
Future<void> _confirmLogout(BuildContext context, AppState state) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: FR.surface,
      title: Text('Çıkış yap', style: frDisplay(20, FontWeight.w700)),
      content: Text(
        'Hesabından çıkmak istediğine emin misin? Sepetin ve favorilerin '
        'hesabına bağlı kalır.',
        style: frText(12.5, FontWeight.w600, color: FR.ink2, height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Vazgeç',
              style: frText(13, FontWeight.w800, color: FR.ink3)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Çıkış yap',
              style: frText(13, FontWeight.w800, color: FR.bad)),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await state.logout();
  }
}

String _regionLabel(AppState state) {
  final city = (state.cityName ?? '').trim();
  final district = (state.districtName ?? '').trim();
  return (city.isEmpty || district.isEmpty) ? 'Bölgeni seç' : '$district / $city';
}

/// Kimlik hero'su — sayfanın tek koyu premium yüzeyi, ana sayfadaki radar
/// hero'suyla aynı espresso ailesinden. Renkler aktif temadan değil
/// [FRPalette.dark]'tan gelir; açık temada krem gövde üzerinde imza bloğu
/// olur, koyu temada elevated yüzey gibi oturur.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.state});
  final AppState state;

  static const FRPalette _d = FRPalette.dark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileInfoScreen()),
      ),
      borderRadius: FRRad.all(FRRad.xxl),
      child: Container(
        padding: const EdgeInsetsDirectional.all(FRSpace.xl),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_d.surfaceHi, _d.bgElev],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: FRRad.all(FRRad.xxl),
          border: Border.all(color: _d.hairline),
          boxShadow: frShadow(blur: 26, y: 14, opacity: FR.isDark ? .4 : .2),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_d.goldHi, _d.goldDeep]),
                borderRadius: FRRad.all(FRRad.xl),
                boxShadow: [
                  BoxShadow(
                      color: _d.gold.withOpacity(.25), blurRadius: 18),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: ProfileAvatarImage(
                imageUrl: state.profileImageUrl,
                displayName: state.displayName,
                size: 72,
                radius: FRRad.xl,
                cacheWidth: 228,
                initialStyle: frDisplay(32, FontWeight.w800, color: _d.onGold),
                onImageError: (url) => state.clearCachedProfileImageUrl(
                  failedUrl: url,
                ),
              ),
            ),
            const SizedBox(width: FRSpace.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(state.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: frDisplay(22, FontWeight.w700,
                                color: _d.ink)),
                      ),
                      if (state.premium.isActive) ...[
                        const SizedBox(width: FRSpace.s),
                        const FRProBadge(compact: false),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(state.username,
                      style: frText(12, FontWeight.w700, color: _d.ink3)),
                  const SizedBox(height: FRSpace.s + 2),
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: _d.gold.withOpacity(.14),
                      borderRadius: FRRad.all(FRRad.pill),
                      border: Border.all(color: _d.gold.withOpacity(.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            color: _d.gold, size: 13),
                        const SizedBox(width: 5),
                        Text(
                            '${FRLevels.forPoints(state.points).name} · ${state.points} PT',
                            style:
                                frText(11, FontWeight.w800, color: _d.gold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: _d.ink3),
          ],
        ),
      ),
    );
  }
}

/// Seviye + seri + topluluk güveni tek sakin yüzeyde. Eskiden üç ayrı
/// progress-bar kartı üst üste yığılıyordu (_TrustCard, _ProgressCard,
/// altın çerçeveler) — hepsi aynı "itibar" sinyali olduğu için tek soft
/// surface kartta toplandı; hero ile yarışan görsel ağırlık kalmadı.
class _ReputationCard extends StatelessWidget {
  const _ReputationCard({required this.state, required this.snap});
  final AppState state;
  final GamificationSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final level = snap.level;
    final next = FRLevels.nextOf(level);
    final pct = snap.levelProgress;
    final trustPct = state.trustScorePercent;
    final trustTone = trustPct >= 70
        ? FR.good
        : trustPct >= 40
            ? FR.warn
            : FR.bad;
    final flame = snap.currentStreak >= 30
        ? '🏆'
        : snap.currentStreak >= 7
            ? '⚡'
            : snap.currentStreak >= 3
                ? '🔥'
                : '🌱';
    final streakLabel = snap.currentStreak == 0
        ? '—'
        : '${snap.currentStreak} gün${snap.streakActive ? "" : " · sıfır"}';

    return Container(
      padding: const EdgeInsetsDirectional.all(FRSpace.l),
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.hairline),
        boxShadow: frShadow(blur: 18, y: 9, opacity: .07),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('SEVİYE · ${level.index + 1}',
                  style: frOverline(color: FR.goldDeep, size: 9.5)),
              const Spacer(),
              Text(
                next == null
                    ? '${snap.points} PT · MAKSİMUM'
                    : '${snap.points} / ${next.minPoints} PT',
                style: frText(11.5, FontWeight.w800, color: FR.ink3),
              ),
            ],
          ),
          const SizedBox(height: FRSpace.xs),
          Text(level.name, style: frDisplay(20, FontWeight.w700)),
          const SizedBox(height: FRSpace.s + 2),
          ClipRRect(
            borderRadius: FRRad.all(FRRad.pill),
            child: LinearProgressIndicator(
              value: pct.clamp(0, 1).toDouble(),
              minHeight: 6,
              color: FR.gold,
              backgroundColor: FR.hairlineSoft,
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: 6),
            Text(
              'Bir sonraki: ${next.name} · ${(next.minPoints - snap.points)} PT',
              style: frText(11, FontWeight.w700, color: FR.ink3),
            ),
          ],
          const SizedBox(height: FRSpace.m),
          Container(height: 1, color: FR.hairlineSoft),
          const SizedBox(height: FRSpace.m),
          Row(
            children: [
              _stat(
                value: '%$trustPct',
                valueColor: trustTone,
                label: 'TOPLULUK GÜVENİ',
              ),
              _divider(),
              _stat(
                value: '$flame $streakLabel',
                label: 'SERİ',
              ),
              _divider(),
              _stat(
                value: '${snap.contributions}',
                label: 'FİYAT KATKISI',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat({
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: frText(14, FontWeight.w800, color: valueColor ?? FR.ink)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: frText(8.5, FontWeight.w800, color: FR.ink3, letter: .9)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsetsDirectional.symmetric(horizontal: FRSpace.m),
      color: FR.hairlineSoft,
    );
  }
}


class _ListGroup extends StatelessWidget {
  const _ListGroup({required this.items});
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FR.surface,
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.hairline),
        boxShadow: frShadow(blur: 18, y: 9, opacity: .07),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Divider(height: 1, color: FR.hairline, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  const _ListItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(FRRad.l),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: FR.surfaceHi,
                borderRadius: FRRad.all(12),
                border: Border.all(color: FR.hairline),
              ),
              // Bakır: utility satır ikonu destek tonu kullanır, altın
              // yalnız premium anlara kalır (design-language: bronz destek).
              child: Icon(icon, color: FR.copper, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: frText(13.5, FontWeight.w800)),
                  Text(subtitle,
                      style: frText(11.5, FontWeight.w600, color: FR.ink3)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: FR.ink3),
          ],
        ),
      ),
    );
  }
}

class _AdminCta extends StatelessWidget {
  const _AdminCta({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsets.all(16),
        // Utility gezinme satırı — altın çerçeve yerine sessiz yüzey,
        // ikon bakır destek tonunda (admin girişi spot ışığı değil).
        decoration: BoxDecoration(
          color: FR.surfaceHi,
          borderRadius: FRRad.all(FRRad.l),
          border: Border.all(color: FR.hairline),
          boxShadow: frShadow(blur: 18, y: 9, opacity: .08),
        ),
        child: Row(
          children: [
            Icon(Icons.admin_panel_settings_outlined,
                color: FR.copper, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin konsolu', style: frText(13.5, FontWeight.w800)),
                  Text('Ürün, fiyat, moderasyon yönetimi',
                      style: frText(11, FontWeight.w600, color: FR.ink3)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: FR.ink3, size: 20),
          ],
        ),
      ),
    );
  }
}

class _GuestProfile extends StatelessWidget {
  const _GuestProfile();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 14, 20, frBottomScrollPadding(context)),
        children: [
          const FRPageHeader(
            overline: 'MİSAFİR',
            title: 'Misafir oturumu',
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            // Sakin kapı kartı — altın çerçeve "premium" değil "kilitli"
            // hissi veriyordu; vurgu ikon kutusunda ve CTA'da yeterli.
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [FR.surfaceHi, FR.surfaceLo],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: FRRad.all(24),
              border: Border.all(color: FR.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: FR.gold.withOpacity(.16),
                        borderRadius: FRRad.all(14),
                        border: Border.all(color: FR.gold.withOpacity(.35)),
                      ),
                      child: Icon(Icons.visibility_outlined,
                          color: FR.gold, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Misafir olarak geziyorsun',
                              style: frDisplay(18, FontWeight.w700)),
                          Text(
                            'Profil ayarları, favoriler ve katkılar yalnızca kayıtlı hesaplarda kullanılabilir.',
                            style: frText(12, FontWeight.w600, color: FR.ink3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FRCta(
                  label: 'Hesap aç / giriş yap',
                  icon: Icons.login_rounded,
                  onTap: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _ListGroup(items: [_ThemeListItem()]),
        ],
      ),
    );
  }
}

/// Compact theme row for use inside a `_ListGroup`. Trailing switch flips
/// dark/light without leaving the profile screen.
class _ThemeListItem extends StatefulWidget {
  const _ThemeListItem();

  @override
  State<_ThemeListItem> createState() => _ThemeListItemState();
}

class _ThemeListItemState extends State<_ThemeListItem> {
  @override
  void initState() {
    super.initState();
    FRThemeController.instance.addListener(_onTheme);
  }

  @override
  void dispose() {
    FRThemeController.instance.removeListener(_onTheme);
    super.dispose();
  }

  void _onTheme() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = FRThemeController.instance.isDark;
    return InkWell(
      onTap: () => FRThemeController.instance.toggle(),
      borderRadius: FRRad.all(FRRad.l),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: FR.surfaceHi,
                borderRadius: FRRad.all(12),
                border: Border.all(color: FR.hairline),
              ),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: FR.gold,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tema', style: frText(13.5, FontWeight.w800)),
                  Text(
                    isDark ? 'Koyu · espresso' : 'Aydınlık · krema',
                    style: frText(11.5, FontWeight.w600, color: FR.ink3),
                  ),
                ],
              ),
            ),
            Switch(
              value: isDark,
              activeColor: FR.onGold,
              activeTrackColor: FR.gold,
              inactiveThumbColor: FR.ink2,
              inactiveTrackColor: FR.surfaceHi,
              onChanged: (_) => FRThemeController.instance.toggle(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.badge,
    required this.earned,
    required this.selected,
    required this.onTap,
  });
  final FRBadge badge;
  final bool earned;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(999),
      child: Opacity(
        opacity: earned ? 1 : 0.5,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? FR.gold.withOpacity(.24)
                : (earned ? FR.gold.withOpacity(.12) : FR.bgElev),
            borderRadius: FRRad.all(999),
            border: Border.all(
              color: selected
                  ? FR.gold
                  : (earned ? FR.gold.withOpacity(.45) : FR.hairline),
              width: selected ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(badge.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                badge.name,
                style: frText(11.5, FontWeight.w800,
                    color: earned ? FR.gold : FR.ink3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumCta extends StatelessWidget {
  const _PremiumCta({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final premium = state.premium;
    final active = premium.isActive;
    final remaining = premium.remaining;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      ),
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  colors: [FR.surfaceHi, FR.surfaceLo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [FR.gold, FR.goldDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: FRRad.all(FRRad.l),
          border: Border.all(
            color: active ? FR.goldDeep.withOpacity(.45) : FR.goldDeep,
          ),
          boxShadow: frGoldGlow(opacity: active ? .12 : .25),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? FR.gold.withOpacity(.16) : FR.bg,
              borderRadius: FRRad.all(12),
              border: Border.all(
                color: active ? FR.gold.withOpacity(.45) : FR.gold,
              ),
            ),
            child: Icon(Icons.workspace_premium_rounded,
                color: FR.gold, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? premium.planLabel : 'FiyatRadar Pro\'ya geç',
                  style: frText(13.5, FontWeight.w800,
                      color: active ? FR.ink : FR.onGold),
                ),
                const SizedBox(height: 2),
                Text(
                  active
                      ? (remaining == null
                          ? 'Aktif abonelik'
                          : 'Yenilemeye ${remaining.inDays} gün')
                      : 'Akıllı sepet, 12 ay grafik, sınırsız alarm, reklamsız',
                  style: frText(11, FontWeight.w700,
                      color: active ? FR.ink3 : FR.onGold.withOpacity(.85)),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded,
              size: 18, color: active ? FR.gold : FR.onGold),
        ]),
      ),
    );
  }
}
