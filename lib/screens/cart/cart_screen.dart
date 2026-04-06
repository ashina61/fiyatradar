import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design_system/design_system.dart';
import '../../providers/cart_provider.dart';
import '../../utils/formatters.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _bestMix = true;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final best = _calcBest(items);
    final single = _calcSingle(items);
    final active = _bestMix ? best : single;

    return FRAppScaffold(
      child: Column(
        children: [
          FRDarkHero(
            title: 'Sepet Kıyası',
            subtitle: '${items.length} ürün • tasarruf odaklı görünüm',
            kicker: const FRKickerPill('Savings Intelligence'),
            content: Row(
              children: [
                Expanded(child: FRMetricBlock(value: formatTRY(best.total), label: 'En iyi toplam')),
                const SizedBox(width: FRDsSpacing.space12),
                Expanded(child: FRMetricBlock(value: '${best.platformCount}', label: 'Platform')),
              ],
            ),
          ),
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(FRDsSpacing.space20, FRDsSpacing.space12, FRDsSpacing.space20, 0),
              child: FRSegmentedSwitch<bool>(
                segments: const {true: Text('En İyi Karışık'), false: Text('Tek Platform')},
                selected: {_bestMix},
                onSelectionChanged: (selection) => setState(() => _bestMix = selection.first),
              ),
            ),
          Expanded(
            child: items.isEmpty
                ? const _EmptyCart()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(FRDsSpacing.space20),
                    child: Column(
                      children: [
                        FRBasketComparisonSection(
                          eyebrow: 'KARŞILAŞTIRMA',
                          title: 'Toplam avantaj',
                          children: [
                            FRComparisonBar(left: best.total, right: single.total),
                            const SizedBox(height: FRDsSpacing.space12),
                            FRPriceDeltaBadge(
                              label: '${formatTRY((single.total - best.total).abs())} fark',
                              variant: single.total > best.total
                                  ? FRPriceDeltaVariant.positive
                                  : FRPriceDeltaVariant.neutral,
                            ),
                          ],
                        ),
                        const SizedBox(height: FRDsSpacing.space16),
                        FRBasketComparisonSection(
                          eyebrow: 'ÜRÜNLER',
                          title: 'Seçili ürünler',
                          children: active.items
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: FRDsSpacing.space8),
                                  child: FRProductCard(
                                    title: item.productName,
                                    subtitle: '${item.platformName} • x${item.quantity}',
                                    trailing: Text(formatTRY(item.price * item.quantity)),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
          ),
          if (items.isNotEmpty)
            FRFloatingSubmitBar(
              label: 'Platformlara Git',
              onPressed: () => _openLinks(active),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FRPrimaryButton(label: 'Platformlara Git', onPressed: () => _openLinks(active)),
                  const SizedBox(height: FRDsSpacing.space8),
                  FRSecondaryButton(label: 'Listeyi Paylaş', onPressed: () => _share(active)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  CartCombination _calcBest(List<CartItem> items) {
    double total = 0;
    final platforms = <String>{};
    for (final i in items) {
      total += i.price * i.quantity;
      platforms.add(i.platformName);
    }
    return CartCombination(items: items, total: total, platformCount: platforms.length);
  }

  CartCombination _calcSingle(List<CartItem> items) => _calcBest(items);

  Future<void> _openLinks(CartCombination combination) async {
    final urls = {
      'Trendyol': 'https://www.trendyol.com',
      'Hepsiburada': 'https://www.hepsiburada.com',
      'Amazon': 'https://www.amazon.com.tr',
      'N11': 'https://www.n11.com',
      'ÇiçekSepeti': 'https://www.ciceksepeti.com',
      'Migros': 'https://www.migros.com.tr',
      'A101': 'https://www.a101.com.tr',
      'CarrefourSA': 'https://www.carrefoursa.com',
    };
    for (final p in combination.items.map((e) => e.platformName).toSet()) {
      final url = urls[p];
      if (url != null) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }

  void _share(CartCombination c) {
    final text = 'FiyatRadar Karşılaştırma:\n\n'
        '${c.items.map((i) => '• ${i.productName}: ${formatTRY(i.price * i.quantity)} (${i.platformName})').join('\n')}\n\n'
        'Toplam: ${formatTRY(c.total)}';
    Share.share(text);
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FRSurfaceCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.compare_arrows_rounded, size: 40),
            const SizedBox(height: FRDsSpacing.space12),
            Text('Karşılaştırma listesi boş', style: FRDsTypography.titleMedium),
            const SizedBox(height: FRDsSpacing.space8),
            Text('Keşfet ekranından ürün ekleyerek başlayabilirsin.', style: FRDsTypography.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class CartCombination {
  const CartCombination({required this.items, required this.total, required this.platformCount});

  final List<CartItem> items;
  final double total;
  final int platformCount;
}
