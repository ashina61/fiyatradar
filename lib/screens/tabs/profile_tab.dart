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
          const SizedBox(height: 18),
          _IdentityCard(state: state),
          const SizedBox(height: 12),
          _TrustCard(state: state),
          const SizedBox(height: 12),
          _ProgressCard(snap: snap),
          const SizedBox(height: 12),
          _RegionalRankCta(state: state),
          const SizedBox(height: 12),
          _PremiumCta(state: state),
          const SizedBox(height: 18),
          const FRSectionHead(eyebrow: 'TAKİP', title: 'Radar takvimin'),
          const SizedBox(height: 10),
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
          const SizedBox(height: 18),
          const FRSectionHead(eyebrow: 'HESAP', title: 'Ayarlar'),
          const SizedBox(height: 10),
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
          const SizedBox(height: 18),
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
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
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
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FRBadges.all
                  .map((b) => _BadgeChip(badge: b, earned: snap.badges.contains(b.id)))
                  .toList(),
            ),
          ],
        ),
      ),
    ),
  );
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

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileInfoScreen()),
      ),
      borderRadius: FRRad.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [FR.surfaceHi, FR.surfaceLo],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: FRRad.all(24),
          border: Border.all(color: FR.goldDeep.withOpacity(.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [FR.goldHi, FR.goldDeep]),
                borderRadius: FRRad.all(22),
                boxShadow: [BoxShadow(color: FR.gold.withOpacity(.3), blurRadius: 20)],
              ),
              clipBehavior: Clip.antiAlias,
              child: ProfileAvatarImage(
                imageUrl: state.profileImageUrl,
                displayName: state.displayName,
                size: 76,
                radius: 22,
                cacheWidth: 228,
                initialStyle: frDisplay(34, FontWeight.w800, color: FR.onGold),
                onImageError: (url) => state.clearCachedProfileImageUrl(
                  failedUrl: url,
                ),
              ),
            ),
            const SizedBox(width: 16),
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
                            style: frDisplay(22, FontWeight.w700)),
                      ),
                      if (state.premium.isActive) ...[
                        const SizedBox(width: 8),
                        const FRProBadge(compact: false),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(state.username,
                      style: frText(12, FontWeight.w700, color: FR.ink3)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: FR.gold.withOpacity(.16),
                      borderRadius: FRRad.all(999),
                      border: Border.all(color: FR.gold.withOpacity(.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            color: FR.gold, size: 13),
                        const SizedBox(width: 5),
                        Text('Elit Radar · ${state.points} PT',
                            style: frText(11, FontWeight.w800, color: FR.gold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Combined level + streak card so the profile keeps progress signals
/// without stacking two near-identical surfaces back-to-back.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.snap});
  final GamificationSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final level = snap.level;
    final next = FRLevels.nextOf(level);
    final pct = snap.levelProgress;
    final flame = snap.currentStreak >= 30
        ? '🏆'
        : snap.currentStreak >= 7
            ? '⚡'
            : snap.currentStreak >= 3
                ? '🔥'
                : '🌱';
    final streakLabel = snap.currentStreak == 0
        ? 'Streak yok'
        : '${snap.currentStreak} gün${snap.streakActive ? "" : " · sıfırlandı"}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FR.surfaceHi, FR.surfaceLo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: FRRad.all(FRRad.l),
        border: Border.all(color: FR.goldDeep.withOpacity(.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('SEVİYE · ${level.index + 1}',
                  style: frOverline(color: FR.gold, size: 9.5)),
              const Spacer(),
              Text(
                next == null
                    ? '${snap.points} PT · MAKSİMUM'
                    : '${snap.points} / ${next.minPoints} PT',
                style: frText(11.5, FontWeight.w800, color: FR.gold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(level.name, style: frDisplay(20, FontWeight.w700)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: FRRad.all(999),
            child: LinearProgressIndicator(
              value: pct.clamp(0, 1).toDouble(),
              minHeight: 8,
              color: FR.gold,
              backgroundColor: FR.bgElev,
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: 6),
            Text(
              'Bir sonraki: ${next.name} · ${(next.minPoints - snap.points)} PT',
              style: frText(11, FontWeight.w700, color: FR.ink3),
            ),
          ],
          const SizedBox(height: 12),
          Container(height: 1, color: FR.hairlineSoft),
          const SizedBox(height: 12),
          Row(children: [
            Text(flame, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(streakLabel, style: frText(13, FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    '${snap.contributions} fiyat · ${snap.verifyContributions} doğrulama · en uzun ${snap.longestStreak} gün',
                    style: frText(10.5, FontWeight.w600, color: FR.ink3),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }
}


class _ListGroup extends StatelessWidget {
  const _ListGroup({required this.items});
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: frSurface(radius: FRRad.l),
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
              child: Icon(icon, color: FR.gold, size: 18),
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
        decoration: BoxDecoration(
          color: FR.surfaceHi,
          borderRadius: FRRad.all(FRRad.l),
          border: Border.all(color: FR.goldDeep.withOpacity(.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.admin_panel_settings_outlined,
                color: FR.gold, size: 22),
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
            Icon(Icons.arrow_forward_rounded, color: FR.gold, size: 18),
          ],
        ),
      ),
    );
  }
}

class _TrustCard extends StatelessWidget {
  const _TrustCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final pct = state.trustScorePercent;
    final c = pct >= 70
        ? FR.good
        : pct >= 40
            ? FR.warn
            : FR.bad;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: frSurface(radius: FRRad.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_moon_outlined, size: 16, color: c),
              const SizedBox(width: 8),
              Text('TOPLULUK GÜVENİ',
                  style: frOverline(color: FR.ink3, size: 9.5)),
              const Spacer(),
              Text('%$pct', style: frPrice(18, color: c)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: FRRad.all(999),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0, 1).toDouble(),
              minHeight: 6,
              color: c,
              backgroundColor: FR.bgElev,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.trustTotalVotes == 0
                ? 'Henüz oy kullanmadın. Doğrulama oyu kullandıkça güven ağırlığın artar.'
                : '${state.trustVerifiedTotal} doğru · ${state.trustWrongTotal} hatalı · '
                    '${state.contributions} fiyat katkın',
            style: frText(11.5, FontWeight.w600, color: FR.ink3, height: 1.45),
          ),
        ],
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [FR.surfaceHi, FR.surfaceLo],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: FRRad.all(24),
              border: Border.all(color: FR.goldDeep.withOpacity(.35)),
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
  const _BadgeChip({required this.badge, required this.earned});
  final FRBadge badge;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${badge.emoji} ${badge.name} · ${badge.description} · +${badge.rewardPoints} PT',
            ),
          ),
        );
      },
      borderRadius: FRRad.all(999),
      child: Opacity(
        opacity: earned ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: earned ? FR.gold.withOpacity(.12) : FR.bgElev,
            borderRadius: FRRad.all(999),
            border: Border.all(
              color: earned ? FR.gold.withOpacity(.45) : FR.hairline,
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

class _RegionalRankCta extends StatelessWidget {
  const _RegionalRankCta({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final city = (state.cityName ?? '').trim();
    final district = (state.districtName ?? '').trim();
    final region = (city.isEmpty || district.isEmpty)
        ? 'Bölgeni seç'
        : '$district / $city';
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const RegionalLeaderboardScreen()),
      ),
      borderRadius: FRRad.all(FRRad.l),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FR.surface,
          borderRadius: FRRad.all(FRRad.l),
          border: Border.all(color: FR.gold.withOpacity(.45)),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: FR.gold.withOpacity(.16),
              borderRadius: FRRad.all(12),
              border: Border.all(color: FR.gold.withOpacity(.45)),
            ),
            child: Icon(Icons.emoji_events_rounded, color: FR.gold, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bölgemde sıralamam',
                    style: frText(13.5, FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  region,
                  style: frText(11.5, FontWeight.w700, color: FR.ink3),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, size: 18, color: FR.gold),
        ]),
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
                      : 'Bayat-fiyat alarmı, leaderboard top-100, reklamsız',
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
