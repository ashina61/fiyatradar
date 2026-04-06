import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_system.dart';
import '../../models/price_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/formatters.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelStreamProvider);
    final unread = ref.watch(unreadNotificationCountProvider);
    final trending = ref.watch(trendingProductsProvider);
    final latestPrices = ref.watch(latestPricesProvider);

    return FRAppScaffold(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: FRDarkHero(
              title: 'Ana Sayfa',
              subtitle: 'Günün özeti ve topluluk hareketleri',
              kicker: const FRKickerPill('Executive Radar'),
              actions: [
                FRHeroActionButton(
                  icon: Icons.notifications_outlined,
                  onPressed: () {},
                ),
                if (unread > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: FRDsSpacing.space8),
                    child: FRStatusBadge('$unread yeni'),
                  ),
              ],
              content: userAsync.when(
                loading: () => const FRSurfaceCard(child: SizedBox(height: 56)),
                error: (_, __) => const SizedBox.shrink(),
                data: (user) {
                  final name = user?.displayName ?? user?.name ?? 'Radar Üyesi';
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: FRDsTypography.titleLarge.copyWith(color: FRDsColors.frSurface)),
                            const SizedBox(height: FRDsSpacing.space4),
                            Text(
                              '${formatCompactCount(user?.totalPoints ?? 0)} puan • ${user?.level ?? 'Gözlemci'}',
                              style: FRDsTypography.bodyMedium.copyWith(color: FRDsColors.frGoldSoft),
                            ),
                          ],
                        ),
                      ),
                      FRTrustBadge(score: user?.trustScorePercent ?? 0),
                    ],
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FRPageContainer(
              child: Padding(
                padding: const EdgeInsets.only(top: FRDsSpacing.space20),
                child: FRHomeSummarySection(
                  eyebrow: 'GÜNÜN NABZI',
                  title: 'Bugünün özeti',
                  children: [
                    trending.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Trend verisi alınamadı: $e', style: FRDsTypography.bodyMedium),
                      data: (products) {
                        final top = products.take(3).toList();
                        if (top.isEmpty) {
                          return Text('Bugün için trend ürün bulunamadı.', style: FRDsTypography.bodyMedium);
                        }
                        return Column(
                          children: [
                            for (final p in top)
                              Padding(
                                padding: const EdgeInsets.only(bottom: FRDsSpacing.space12),
                                child: FRProductCard(
                                  title: p.name,
                                  subtitle: p.brand,
                                  trailing: const Icon(Icons.chevron_right),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FRPageContainer(
              child: Padding(
                padding: const EdgeInsets.only(top: FRDsSpacing.space20, bottom: FRDsSpacing.space32),
                child: FRMarketRankingSection(
                  eyebrow: 'TOPLULUK AKIŞI',
                  title: 'Son fiyat katkıları',
                  children: [
                    latestPrices.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Katkılar yüklenemedi: $e', style: FRDsTypography.bodyMedium),
                      data: (prices) {
                        if (prices.isEmpty) {
                          return Text('Henüz katkı yok. İlk fiyatı sen ekle.', style: FRDsTypography.bodyMedium);
                        }
                        return Column(
                          children: prices.take(6).map((price) => _RecentPriceRow(price: price)).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentPriceRow extends StatelessWidget {
  const _RecentPriceRow({required this.price});

  final PriceModel price;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FRDsSpacing.space12),
      child: FRInfoRowCard(
        leading: const Icon(Icons.local_offer_outlined),
        title: price.productName ?? 'Ürün',
        subtitle: '${price.storeName ?? 'Market'} • ${price.addedByDisplayName ?? 'Topluluk'}',
        trailing: Text(formatTRY(price.price), style: FRDsTypography.titleMedium),
      ),
    );
  }
}
