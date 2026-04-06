// lib/screens/profile/profile_screen.dart
// GREENFIELD v2 — "The Dossier"
// Rejected from the previous iteration: multi-card stacked hierarchy, big avatar card
// with rounded brown chrome, inline settings widgets, points card.
// UX goal: identity + trust + progression at a glance, then a single hairline list.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/fr_ink.dart';
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
      backgroundColor: FRInk.paper,
      body: userAsync.when(
        loading: () => const Center(
          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 1.5, color: FRInk.ink)),
        ),
        error: (_, __) => const Center(child: Text('Bir hata oluştu.', style: FRType.body)),
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
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 160),
              children: [
                const SizedBox(height: 18),
                const _TopLabel(),
                const SizedBox(height: 28),
                _IdentityBlock(user: user),
                const SizedBox(height: 32),
                _StatsRow(user: user),
                const SizedBox(height: 30),
                const FRHairline(),
                _MenuItem(
                  label: 'Katkılarım',
                  sub: 'Bildirdiğin fiyatlar',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyPricesScreen())),
                ),
                const FRHairline(indent: FRInk.gutter),
                _MenuItem(
                  label: 'Favoriler',
                  sub: 'Takip ettiğin ürünler',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen())),
                ),
                const FRHairline(indent: FRInk.gutter),
                _MenuItem(
                  label: 'Fiyat alarmları',
                  sub: 'Seni bilgilendireceğimiz ürünler',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WatchlistScreen())),
                ),
                const FRHairline(indent: FRInk.gutter),
                _MenuItem(
                  label: 'Ayarlar',
                  sub: 'Bildirimler, gizlilik, hesap',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
                const FRHairline(indent: FRInk.gutter),
                _MenuItem(
                  label: 'Çıkış yap',
                  sub: null,
                  destructive: true,
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
                const FRHairline(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopLabel extends StatelessWidget {
  const _TopLabel();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: FRInk.gutter),
      child: Text('DOSYA', style: FRType.micro),
    );
  }
}

class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final name = [user.firstName, user.lastName]
        .where((s) => (s ?? '').trim().isNotEmpty)
        .join(' ')
        .trim();
    final shown = name.isNotEmpty ? name : (user.name.isNotEmpty ? user.name : user.username);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              width: 68, height: 68,
              child: (user.photoUrl ?? '').isEmpty
                  ? Container(
                      color: FRInk.paperDeep,
                      alignment: Alignment.center,
                      child: Text(
                        (shown.isNotEmpty ? shown[0] : '?').toUpperCase(),
                        style: const TextStyle(
                          fontFamily: FRType.family,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: FRInk.ink,
                        ),
                      ),
                    )
                  : CachedNetworkImage(imageUrl: user.photoUrl!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          Text(shown, style: FRType.title),
          const SizedBox(height: 4),
          Text('@${user.username}', style: FRType.body.copyWith(color: FRInk.inkMute)),
          const SizedBox(height: 12),
          _LevelBadge(level: user.level),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});
  final String level;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: FRInk.saffronWash,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        level.toUpperCase(),
        style: const TextStyle(
          fontFamily: FRType.family,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: FRInk.saffronDeep,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user});
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter),
      child: Row(
        children: [
          _StatCol(label: 'KATKI', value: formatCompactCount(user.priceEntries)),
          Container(width: 1, height: 44, color: FRInk.hairline),
          _StatCol(label: 'GÜVEN', value: '${user.trustScorePercent}%'),
          Container(width: 1, height: 44, color: FRInk.hairline),
          _StatCol(label: 'PUAN', value: formatCompactCount(user.points)),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  const _StatCol({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: FRType.title.copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text(label, style: FRType.micro),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.label, this.sub, required this.onTap, this.destructive = false});
  final String label;
  final String? sub;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter, vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: FRType.bodyStrong.copyWith(
                      fontSize: 16,
                      color: destructive ? FRInk.rise : FRInk.ink,
                    ),
                  ),
                  if (sub != null) ...[
                    const SizedBox(height: 3),
                    Text(sub!, style: FRType.body.copyWith(color: FRInk.inkMute, fontSize: 13)),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: destructive ? FRInk.rise : FRInk.inkMute,
            ),
          ],
        ),
      ),
    );
  }
}
