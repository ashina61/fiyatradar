import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_system.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../points/points_screen.dart';
import '../settings/settings_screen.dart';
import 'favorites_screen.dart';
import 'my_prices_screen.dart';
import 'price_alarms_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelStreamProvider);

    return userAsync.when(
      loading: () => const FRAppScaffold(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => FRAppScaffold(child: Center(child: Text('Profil yüklenemedi: $e'))),
      data: (user) {
        final uid = user?.uid;
        if (uid == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
          });
          return const FRAppScaffold(child: Center(child: CircularProgressIndicator()));
        }

        final displayName = user?.displayName ?? user?.name ?? 'Radar Üyesi';
        final level = user?.level ?? 'Gözlemci';
        final points = user?.totalPoints ?? 0;
        final trust = user?.trustScorePercent ?? 0;

        return FRAppScaffold(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: FRDarkHero(
                  title: 'Profil',
                  subtitle: 'Kimlik, güven ve katkı görünümü',
                  kicker: const FRKickerPill('Prestige Identity'),
                  actions: [
                    FRHeroActionButton(
                      icon: CupertinoIcons.settings,
                      onPressed: () {
                        Navigator.of(context).push(CupertinoPageRoute(builder: (_) => SettingsScreen(isAdmin: user?.isAdmin ?? false)));
                      },
                    ),
                  ],
                  content: FRAvatarTile(name: displayName, imageUrl: user?.photoUrl),
                ),
              ),
              SliverToBoxAdapter(
                child: FRPageContainer(
                  child: Padding(
                    padding: const EdgeInsets.only(top: FRDsSpacing.space20),
                    child: FRProfileIdentitySection(
                      eyebrow: 'RADAR ÖZETİ',
                      title: displayName,
                      children: [
                        Row(
                          children: [
                            Expanded(child: FRStatCard(value: '$points', label: 'Toplam Puan', description: level)),
                            const SizedBox(width: FRDsSpacing.space12),
                            Expanded(child: FRStatCard(value: '%$trust', label: 'Güven', description: 'Topluluk güven skoru')),
                          ],
                        ),
                        const SizedBox(height: FRDsSpacing.space12),
                        FRLevelBadge(level),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FRPageContainer(
                  child: Padding(
                    padding: const EdgeInsets.only(top: FRDsSpacing.space20),
                    child: FRAchievementsSection(
                      eyebrow: 'KATKILAR',
                      title: 'Hızlı erişimler',
                      children: [
                        FRInfoRowCard(
                          title: 'Puanlarım',
                          subtitle: 'Seviye ve görev görünümü',
                          onTap: () => Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const PointsScreen())),
                        ),
                        const SizedBox(height: FRDsSpacing.space8),
                        FRInfoRowCard(
                          title: 'Eklediğim Fiyatlar',
                          subtitle: 'Fiyat katkı geçmişi',
                          onTap: () => Navigator.of(context).push(
                            CupertinoPageRoute(builder: (_) => MyPricesScreen(userId: uid)),
                          ),
                        ),
                        const SizedBox(height: FRDsSpacing.space8),
                        FRInfoRowCard(
                          title: 'Fiyat Alarmlarım',
                          subtitle: 'Aktif alarm listesi',
                          onTap: () => Navigator.of(context).push(
                            CupertinoPageRoute(builder: (_) => WatchlistScreen(userId: uid)),
                          ),
                        ),
                        const SizedBox(height: FRDsSpacing.space8),
                        FRInfoRowCard(
                          title: 'Favorilerim',
                          subtitle: 'Takip edilen ürünler',
                          onTap: () => Navigator.of(context).push(
                            CupertinoPageRoute(builder: (_) => FavoritesScreen(userId: uid)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: FRDsSpacing.space32)),
            ],
          ),
        );
      },
    );
  }
}
