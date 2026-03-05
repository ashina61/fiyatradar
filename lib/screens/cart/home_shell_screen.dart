import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fiyatradar_app.dart';
import 'market_comparison.dart';
import 'cart_provider.dart';
import 'comparison_provider.dart';
import 'tab_provider.dart';

class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(homeTabProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.8,
            colors: [Color(0xFFFFFFFF), FRColors.background],
          ),
        ),
        child: Column(
          children: [
            _Header(activeTab: activeTab),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                child: activeTab == HomeTab.sepet
                    ? const _CartView(key: ValueKey('sepet'))
                    : _CompareView(
                        key: const ValueKey('karsilastir'),
                        pulseController: _pulseController,
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _PremiumBottomNav(),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.activeTab});

  final HomeTab activeTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
          decoration: BoxDecoration(
            color: FRColors.background.withOpacity(0.9),
            border: Border(
              bottom: BorderSide(
                color: FRColors.primary.withOpacity(0.06),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(left: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: FRColors.primary, width: 4),
                  ),
                ),
                child: Text(
                  'Sepetim',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: FRColors.dark,
                      ),
                ),
              ),
              const SizedBox(height: 18),
              _CustomTab(activeTab: activeTab),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomTab extends ConsumerWidget {
  const _CustomTab({required this.activeTab});

  final HomeTab activeTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = (constraints.maxWidth - 10) / 2;
        return Container(
          height: 50,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: FRColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: activeTab == HomeTab.sepet ? 0 : tabWidth,
                child: Container(
                  width: tabWidth,
                  height: 40,
                  decoration: BoxDecoration(
                    color: FRColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: FRColors.primary.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _TabButton(
                    text: 'Sepet',
                    active: activeTab == HomeTab.sepet,
                    onTap: () =>
                        ref.read(homeTabProvider.notifier).setTab(HomeTab.sepet),
                  ),
                  _TabButton(
                    text: 'Karşılaştır',
                    active: activeTab == HomeTab.karsilastir,
                    onTap: () => ref
                        .read(homeTabProvider.notifier)
                        .setTab(HomeTab.karsilastir),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.text,
    required this.active,
    required this.onTap,
  });

  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: active ? FRColors.primary : FRColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _CartView extends ConsumerWidget {
  const _CartView({super.key});

  String _price(double value) =>
      '${value.toStringAsFixed(2).replaceAll('.', ',')}₺';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 15, 24, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _surfaceDecoration(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _summaryItem(Icons.shopping_bag_rounded, '${cart.length} Ürün'),
              Container(
                width: 1,
                height: 24,
                color: FRColors.primary.withOpacity(0.1),
              ),
              _summaryItem(
                Icons.payments_rounded,
                '${_price(total)} Tahmini',
                iconColor: FRColors.gold,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Alışveriş Listeniz',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: FRColors.dark,
                  ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [FRColors.gold, FRColors.primary],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: FRColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ürün arama ekranı açılıyor...')),
                  );
                },
                icon: const Icon(Icons.add_circle, color: FRColors.surface),
                label: const Text('Ürün Ekle'),
                style: TextButton.styleFrom(
                  foregroundColor: FRColors.surface,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ...cart.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: _surfaceDecoration(24),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      item.imageUrl,
                      width: 85,
                      height: 85,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: FRColors.dark,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _price(item.totalPrice),
                              style: const TextStyle(
                                color: FRColors.primary,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: FRColors.primary.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () => ref
                                        .read(cartProvider.notifier)
                                        .removeOrDecrease(item.id),
                                    icon: const Icon(Icons.delete_outline),
                                    color: FRColors.danger,
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => ref
                                        .read(cartProvider.notifier)
                                        .increaseQuantity(item.id),
                                    icon: const Icon(Icons.add),
                                    color: FRColors.dark,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fiyatlar analiz ediliyor...')),
            );
            Future.delayed(const Duration(milliseconds: 500), () {
              ref.read(homeTabProvider.notifier).setTab(HomeTab.karsilastir);
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: FRColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: FRColors.primary.withOpacity(0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'En Uygunu Bul',
                  style: TextStyle(
                    color: FRColors.surface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.east_rounded, color: FRColors.surface),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryItem(IconData icon, String text, {Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, color: iconColor ?? FRColors.muted, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: FRColors.dark,
          ),
        ),
      ],
    );
  }
}

class _CompareView extends ConsumerWidget {
  const _CompareView({super.key, required this.pulseController});

  final AnimationController pulseController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(comparisonProvider);
    final winner = data.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 15, 24, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [FRColors.dark, FRColors.primary],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: FRColors.dark.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: FRColors.gold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star, size: 16, color: FRColors.dark),
                        SizedBox(width: 6),
                        Text(
                          'EN UYGUN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: FRColors.dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: pulseController,
                    builder: (context, child) {
                      final scale = 1 + (pulseController.value * 0.03);
                      final glow = 10 + (pulseController.value * 15);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: FRColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: FRColors.gold, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: FRColors.surface.withOpacity(0.8),
                                blurRadius: glow,
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.savings, size: 18, color: FRColors.gold),
                              SizedBox(width: 6),
                              Text(
                                '5₺ KAZANÇ',
                                style: TextStyle(
                                  color: FRColors.dark,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        winner.marketName,
                        style: const TextStyle(
                          color: FRColors.surface,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${winner.distanceKm} km • Tüm ürünler var',
                        style: TextStyle(
                          color: FRColors.surface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  RichText(
                    text: TextSpan(
                      text: winner.totalPrice.toStringAsFixed(0),
                      style: const TextStyle(
                        color: FRColors.surface,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                      ),
                      children: const [
                        TextSpan(
                          text: '₺',
                          style: TextStyle(
                            fontSize: 20,
                            color: FRColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('A-101 rotası hazırlanıyor...')),
                  );
                },
                icon: const Icon(Icons.directions_walk),
                label: const Text('Markete Git'),
                style: FilledButton.styleFrom(
                  backgroundColor: FRColors.surface,
                  foregroundColor: FRColors.dark,
                  minimumSize: const Size.fromHeight(52),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        Text(
          'Alternatif Marketler',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: FRColors.dark,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: _surfaceDecoration(28),
          child: Column(
            children: data
                .where((e) => !e.isBest)
                .map((market) => _ComparisonRow(market: market))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ComparisonRow extends ConsumerWidget {
  const _ComparisonRow({required this.market});

  final MarketComparison market;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(expandedMarketProvider) == market.marketName;

    return InkWell(
      onTap: () {
        ref.read(expandedMarketProvider.notifier).state =
            expanded ? null : market.marketName;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: FRColors.primary.withOpacity(0.06),
            ),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: market.hasMissing
                            ? FRColors.danger.withOpacity(0.1)
                            : (expanded
                                ? FRColors.gold
                                : FRColors.primary.withOpacity(0.06)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        market.hasMissing ? '!' : '${market.rank}',
                        style: TextStyle(
                          color: market.hasMissing
                              ? FRColors.danger
                              : (expanded ? FRColors.dark : FRColors.muted),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          market.marketName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: FRColors.dark,
                          ),
                        ),
                        Text(
                          market.hasMissing
                              ? '${market.distanceKm} km • ${market.missingCount} Eksik'
                              : '${market.distanceKm} km • Eksik Yok',
                          style: TextStyle(
                            color:
                                market.hasMissing ? FRColors.danger : FRColors.muted,
                            fontWeight: market.hasMissing
                                ? FontWeight.w600
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${market.totalPrice.toStringAsFixed(0)}₺',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: FRColors.dark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: market.hasMissing
                            ? FRColors.danger.withOpacity(0.1)
                            : FRColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        market.hasMissing
                            ? 'Stok Yok'
                            : '+${market.differenceFromBest.toStringAsFixed(0)}₺ Fark',
                        style: TextStyle(
                          color:
                              market.hasMissing ? FRColors.danger : FRColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              height: expanded ? null : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: expanded ? 1 : 0,
                child: expanded
                    ? Container(
                        margin: const EdgeInsets.only(top: 15),
                        padding: const EdgeInsets.only(top: 15),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: FRColors.primary.withOpacity(0.1),
                              style: BorderStyle.solid,
                            ),
                          ),
                        ),
                        child: Column(
                          children: market.details
                              .map(
                                (detail) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        detail.productName,
                                        style: TextStyle(
                                          color: detail.missing
                                              ? FRColors.muted
                                              : FRColors.dark,
                                          decoration: detail.missing
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      if (detail.missing)
                                        const Text(
                                          'Tükendi',
                                          style: TextStyle(
                                            color: FRColors.danger,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        )
                                      else if (detail.diff > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: FRColors.danger
                                                .withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${detail.price.toStringAsFixed(0)}₺ (+${detail.diff.toStringAsFixed(0)}₺)',
                                            style: const TextStyle(
                                              color: FRColors.danger,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        )
                                      else
                                        Text(
                                          '${detail.price.toStringAsFixed(0)}₺ (Aynı)',
                                          style: const TextStyle(
                                            color: FRColors.muted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumBottomNav extends StatelessWidget {
  const _PremiumBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 15),
      decoration: const BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _NavIcon(icon: Icons.home_rounded),
          _NavIcon(icon: Icons.explore_rounded),
          _DiamondButton(),
          _NavIcon(icon: Icons.shopping_bag_rounded, active: true),
          _NavIcon(icon: Icons.person_rounded),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, this.active = false});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Icon(
        icon,
        size: 28,
        color: active ? FRColors.primary : FRColors.muted,
      ),
    );
  }
}

class _DiamondButton extends StatelessWidget {
  const _DiamondButton();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Transform.rotate(
        angle: 0.785398,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [FRColors.gold, FRColors.primary]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: FRColors.primary.withOpacity(0.35),
                blurRadius: 35,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Transform.rotate(
            angle: -0.785398,
            child: const Icon(Icons.add, size: 34, color: FRColors.surface),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _surfaceDecoration(double radius) {
  return BoxDecoration(
    color: FRColors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: FRColors.primary.withOpacity(0.03)),
    boxShadow: [
      BoxShadow(
        color: FRColors.primary.withOpacity(0.04),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
