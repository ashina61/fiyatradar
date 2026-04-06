import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/tokens/colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/formatters.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';
import 'favorites_screen.dart';
import 'my_prices_screen.dart';
import 'price_alarms_screen.dart' show WatchlistScreen;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelStreamProvider);

    return Scaffold(
      backgroundColor: FRDsColors.frBackground,
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Bir hata oluştu.')),
        data: (user) {
          if (user == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            });
            return const SizedBox.shrink();
          }

          return SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 150),
              children: [
                _ProfileHero(user: user),
                const SizedBox(height: 16),
                _ProgressCard(user: user),
                const SizedBox(height: 28),
                const _SectionLabel('KOLEKSİYONLAR'),
                const SizedBox(height: 10),
                _ActionCard(
                  children: [
                    _ActionTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Fiyat Alarmlarım',
                      badge: '0 Aktif',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => WatchlistScreen(userId: user.uid)),
                      ),
                    ),
                    _ActionTile(
                      icon: Icons.bookmark_border_rounded,
                      title: 'Koleksiyonlarım (Favoriler)',
                      badge: '1',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => FavoritesScreen(userId: user.uid)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionLabel('LİDERLİK & HESAP'),
                const SizedBox(height: 10),
                _ActionCard(
                  children: [
                    _ActionTile(
                      icon: Icons.fact_check_outlined,
                      title: 'Katkılarım',
                      badge: formatCompactCount(user.priceEntries),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => MyPricesScreen(userId: user.uid)),
                      ),
                    ),
                    _ActionTile(
                      icon: Icons.settings_outlined,
                      title: 'Ayarlar',
                      badge: 'Yönet',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SettingsScreen(isAdmin: user.isAdmin)),
                      ),
                    ),
                    _ActionTile(
                      icon: Icons.logout_rounded,
                      title: 'Çıkış Yap',
                      titleColor: FRDsColors.frDanger,
                      onTap: () async {
                        await ref.read(authNotifierProvider.notifier).signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (_) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final name = [user.firstName, user.lastName]
        .where((s) => (s ?? '').trim().isNotEmpty)
        .join(' ')
        .trim();
    final shown = name.isNotEmpty ? name : (user.name.isNotEmpty ? user.name : user.username);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF24120D),
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Profil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  height: 1.02,
                ),
              ),
              const Spacer(),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A241B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.radar_outlined, color: Color(0xFFDDB98F)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: FRDsColors.frSurface,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFFE7C08F), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: (user.photoUrl ?? '').isEmpty
                        ? Center(
                            child: Text(
                              shown.isEmpty ? '?' : shown[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: FRDsColors.frBrownDeep,
                              ),
                            ),
                          )
                        : CachedNetworkImage(imageUrl: user.photoUrl!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6C197),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: Color(0xFF2A1A14)),
                      SizedBox(width: 6),
                      Text('ADMIN', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2A1A14))),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  shown,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                Text(
                  '@${user.username}',
                  style: const TextStyle(fontSize: 16, color: Color(0xFFDBC8BA), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final total = user.points;
    final target = ((total / 500).floor() + 1) * 500;
    final remain = target - total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF27140E),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('TOPLAM RADAR PUANI', style: TextStyle(color: Color(0xFFBCA99A), letterSpacing: 1.8, fontWeight: FontWeight.w700)),
              Spacer(),
              Icon(Icons.stars_rounded, color: Color(0xFFE2BC8A)),
            ],
          ),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$total', style: const TextStyle(fontSize: 58, color: Colors.white, fontWeight: FontWeight.w800, height: 1.0)),
                const TextSpan(text: ' PT', style: TextStyle(fontSize: 34, color: Color(0xFFE3BC8A), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bir sonraki lig için $remain PT kaldı',
            style: const TextStyle(color: Color(0xFFBCA99A), fontSize: 20),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: FRDsColors.frTextMuted,
        fontWeight: FontWeight.w700,
        fontSize: 13,
        letterSpacing: 2.2,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.children});
  final List<_ActionTile> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FRDsColors.frSurface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, indent: 22, endIndent: 22, color: Color(0x0E2A1D16)),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badge,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? badge;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF1EEEA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: FRDsColors.frTextSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      color: titleColor ?? FRDsColors.frTextPrimary,
                    ),
                  ),
                  if (badge != null)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8EBD8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB66F1C),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: FRDsColors.frTextMuted, size: 28),
          ],
        ),
      ),
    );
  }
}
