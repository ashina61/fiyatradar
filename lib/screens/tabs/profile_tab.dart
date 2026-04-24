import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../admin_screen.dart';
import '../main_screen.dart';
import '../notifications_screen.dart';
import '../profile_screens.dart';
import '../product_request_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final rankPoints = state.points % 1000;
    final rankPct = rankPoints / 1000.0;

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
          const SizedBox(height: 20),
          _IdentityCard(state: state),
          const SizedBox(height: 14),
          _TrustCard(state: state),
          const SizedBox(height: 14),
          _RankProgress(pct: rankPct, earned: rankPoints),
          const SizedBox(height: 20),
          _StatGrid(state: state),
          const SizedBox(height: 20),
          FRSectionHead(eyebrow: 'GÖRÜNÜM', title: 'Tema'),
          const SizedBox(height: 10),
          const _ThemeToggleCard(),
          const SizedBox(height: 20),
          FRSectionHead(eyebrow: 'TAKİP', title: 'Radar takvimin'),
          const SizedBox(height: 10),
          _ListGroup(
            items: [
              _ListItem(
                icon: Icons.favorite_rounded,
                title: 'Favoriler',
                subtitle: '${state.favorites.length} ürün takipte',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                ),
              ),
              _ListItem(
                icon: Icons.notifications_active_rounded,
                title: 'Alarmlarım',
                subtitle: '${state.productAlerts.length} aktif fiyat alarmı',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertsScreen()),
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
          FRSectionHead(eyebrow: 'HESAP', title: 'Ayarlar'),
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
                icon: Icons.shield_outlined,
                title: 'Güvenlik',
                subtitle: state.twoFactorEnabled ? '2FA açık' : '2FA kapalı',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SecurityPrefsScreen()),
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
            onTap: () => state.logout(),
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

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final initial =
        state.displayName.isEmpty ? 'F' : state.displayName[0].toUpperCase();
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
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              child: state.profileImageUrl != null
                  ? Image.network(state.profileImageUrl!, fit: BoxFit.cover)
                  : Text(initial, style: frDisplay(34, FontWeight.w800, color: FR.bg)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: frDisplay(22, FontWeight.w700)),
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

class _RankProgress extends StatelessWidget {
  const _RankProgress({required this.pct, required this.earned});
  final double pct;
  final int earned;

  @override
  Widget build(BuildContext context) {
    return FRCard(
      radius: FRRad.l,
      child: Column(
        children: [
          Row(
            children: [
              Text('SONRAKİ RÜTBEYE',
                  style: frOverline(color: FR.ink3, size: 9.5)),
              const Spacer(),
              Text('$earned / 1000 PT',
                  style: frText(11.5, FontWeight.w800, color: FR.gold)),
            ],
          ),
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
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _stat(
          context,
          '${state.favorites.length}',
          'FAVORİ',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
          ),
        ),
        const SizedBox(width: 10),
        _stat(
          context,
          '${state.productAlerts.length}',
          'ALARM',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AlertsScreen()),
          ),
        ),
        const SizedBox(width: 10),
        _stat(
          context,
          '${state.cartItemCount}',
          'SEPET',
          onTap: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 3)),
          ),
        ),
        const SizedBox(width: 10),
        _stat(context, '${state.points}', 'PUAN'),
      ],
    );
  }

  Widget _stat(BuildContext context, String v, String l, {VoidCallback? onTap}) =>
      Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: FRRad.all(FRRad.m),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: frSurface(radius: FRRad.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v, style: frPrice(22, color: FR.ink)),
                const SizedBox(height: 2),
                Text(l, style: frOverline(color: FR.ink3, size: 9)),
              ],
            ),
          ),
        ),
      );
}

class _ListGroup extends StatelessWidget {
  const _ListGroup({required this.items});
  final List<_ListItem> items;

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

class _ThemeToggleCard extends StatefulWidget {
  const _ThemeToggleCard();

  @override
  State<_ThemeToggleCard> createState() => _ThemeToggleCardState();
}

class _ThemeToggleCardState extends State<_ThemeToggleCard> {
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: frSurface(radius: FRRad.l),
      child: Column(
        children: [
          Row(
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
                      isDark
                          ? 'Koyu tema · espresso'
                          : 'Aydınlık tema · krema',
                      style: frText(11.5, FontWeight.w600, color: FR.ink3),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isDark,
                activeColor: FR.bg,
                activeTrackColor: FR.gold,
                inactiveThumbColor: FR.ink2,
                inactiveTrackColor: FR.surfaceHi,
                onChanged: (_) => FRThemeController.instance.toggle(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _themeChip(
                  label: 'Aydınlık',
                  icon: Icons.light_mode_rounded,
                  active: !isDark,
                  onTap: () => FRThemeController.instance
                      .setMode(FRThemeMode.light),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _themeChip(
                  label: 'Koyu',
                  icon: Icons.dark_mode_rounded,
                  active: isDark,
                  onTap: () =>
                      FRThemeController.instance.setMode(FRThemeMode.dark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _themeChip({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: FRRad.all(FRRad.m),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: active ? FR.gold.withOpacity(.16) : FR.bgElev,
          borderRadius: FRRad.all(FRRad.m),
          border: Border.all(color: active ? FR.gold : FR.hairline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: active ? FR.gold : FR.ink2),
            const SizedBox(width: 6),
            Text(label,
                style: frText(12, FontWeight.w800,
                    color: active ? FR.gold : FR.ink2)),
          ],
        ),
      ),
    );
  }
}
