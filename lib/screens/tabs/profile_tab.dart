import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';
import '../admin_screen.dart';
import '../notifications_screen.dart';

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
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
        children: [
          FRPageHeader(
            overline: 'KİMLİK · GÜVEN · KATKI',
            title: 'Profil',
            trailing: FRIconChip(
              icon: Icons.settings_outlined,
              onTap: () {},
            ),
          ),
          const SizedBox(height: 20),
          _IdentityCard(state: state),
          const SizedBox(height: 14),
          _RankProgress(pct: rankPct, earned: rankPoints),
          const SizedBox(height: 20),
          _StatGrid(state: state),
          const SizedBox(height: 20),
          FRSectionHead(eyebrow: 'TAKİP', title: 'Radar takvimin'),
          const SizedBox(height: 10),
          _ListGroup(
            items: [
              _ListItem(
                icon: Icons.favorite_rounded,
                title: 'Favoriler',
                subtitle: '${state.favorites.length} ürün takipte',
                onTap: () {},
              ),
              _ListItem(
                icon: Icons.notifications_active_rounded,
                title: 'Alarmlarım',
                subtitle: '${state.productAlerts.length} aktif fiyat alarmı',
                onTap: () {},
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
                onTap: () {},
              ),
              _ListItem(
                icon: Icons.shield_outlined,
                title: 'Güvenlik',
                subtitle: state.twoFactorEnabled ? '2FA açık' : '2FA kapalı',
                onTap: () {},
              ),
              _ListItem(
                icon: Icons.place_outlined,
                title: 'Konum tercihleri',
                subtitle: 'Kadıköy, İstanbul',
                onTap: () {},
              ),
              _ListItem(
                icon: Icons.notifications_none_rounded,
                title: 'Bildirim tercihleri',
                subtitle: state.pushNotificationsEnabled ? 'Açık' : 'Kapalı',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 18),
          _AdminCta(onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminScreen()),
              )),
          const SizedBox(height: 14),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
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
              gradient: const LinearGradient(colors: [FR.goldHi, FR.goldDeep]),
              borderRadius: FRRad.all(22),
              boxShadow: [BoxShadow(color: FR.gold.withOpacity(.3), blurRadius: 20)],
            ),
            alignment: Alignment.center,
            child: Text(initial, style: frDisplay(34, FontWeight.w800, color: FR.bg)),
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
                      const Icon(Icons.auto_awesome_rounded,
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
        ],
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
        _stat('${state.favorites.length}', 'FAVORİ'),
        const SizedBox(width: 10),
        _stat('${state.productAlerts.length}', 'ALARM'),
        const SizedBox(width: 10),
        _stat('${state.cartItemCount}', 'SEPET'),
        const SizedBox(width: 10),
        _stat('${state.points}', 'PUAN'),
      ],
    );
  }

  Widget _stat(String v, String l) => Expanded(
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
              const Divider(height: 1, color: FR.hairline, indent: 16, endIndent: 16),
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
            const Icon(Icons.chevron_right_rounded, color: FR.ink3),
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
            const Icon(Icons.admin_panel_settings_outlined,
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
            const Icon(Icons.arrow_forward_rounded, color: FR.gold, size: 18),
          ],
        ),
      ),
    );
  }
}
