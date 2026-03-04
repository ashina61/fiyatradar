import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../models/cart_item.dart';
import '../models/market_comparison.dart';
import '../providers/cart_analysis_providers.dart';

class CartAnalysisScreen extends ConsumerStatefulWidget {
  const CartAnalysisScreen({super.key});

  @override
  ConsumerState<CartAnalysisScreen> createState() => _CartAnalysisScreenState();
}

class _CartAnalysisScreenState extends ConsumerState<CartAnalysisScreen>
    with TickerProviderStateMixin {
  int _tabIndex = 0;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(cartItemsProvider);
    final compareAsync = ref.watch(marketComparisonsProvider);

    return Theme(
      data: _premiumTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F6F2),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text('Sepetim', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              _SegmentedTabs(index: _tabIndex, onChanged: (value) => setState(() => _tabIndex = value)),
              const SizedBox(height: 14),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _tabIndex == 0
                      ? _CartView(key: const ValueKey('cart-view'), itemsAsync: itemsAsync)
                      : _ComparisonView(
                          key: const ValueKey('comparison-view'),
                          dataAsync: compareAsync,
                          pulseController: _pulseController,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: index == 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: MediaQuery.sizeOf(context).width * 0.44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFC89B7B), Color(0xFF6B4226)]),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: _TabBtn(label: 'Sepet', active: index == 0, onTap: () => onChanged(0))),
              Expanded(child: _TabBtn(label: 'Karşılaştır', active: index == 1, onTap: () => onChanged(1))),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  const _TabBtn({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        height: 46,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF6B4226),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CartView extends ConsumerWidget {
  const _CartView({super.key, required this.itemsAsync});

  final AsyncValue<List<CartItem>> itemsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Sepet alınamadı: $e')),
      data: (items) {
        final estimated = items.fold<double>(0, (sum, item) => sum + item.lineTotal);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          children: [
            _CompactSummary(itemCount: items.length, estimated: estimated),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Alışveriş Listeniz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFC89B7B), Color(0xFF6B4226)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [BoxShadow(color: Color(0x4D6B4226), blurRadius: 16, offset: Offset(0, 8))],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_circle, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('Ürün Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => _CartItemCard(item: item)),
            const SizedBox(height: 14),
            Container(
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF2A1A10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('En Uygunu Bul', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                    SizedBox(width: 8),
                    Icon(Icons.east_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CartItemCard extends ConsumerWidget {
  const _CartItemCard({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(activeUserIdProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(item.imageUrl, width: 74, height: 74, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item.unitPrice.toStringAsFixed(2)}₺', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6B4226))),
                    Row(
                      children: [
                        _QtyButton(
                          icon: Icons.delete_outline,
                          color: const Color(0xFFA33333),
                          onTap: userId == null ? null : () => ref.read(cartServiceProvider).decrementItem(userId, item),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        _QtyButton(
                          icon: Icons.add,
                          color: const Color(0xFF2A1A10),
                          onTap: userId == null ? null : () => ref.read(cartServiceProvider).incrementItem(userId, item),
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.color, this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: const Color(0xFFF2ECE6), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

class _ComparisonView extends StatelessWidget {
  const _ComparisonView({super.key, required this.dataAsync, required this.pulseController});

  final AsyncValue<MarketComparisonBundle> dataAsync;
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return dataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Karşılaştırma alınamadı: $e')),
      data: (bundle) {
        if (bundle.winner == null) {
          return const Center(child: Text('Karşılaştırma için sepete ürün ekleyin.'));
        }
        final winner = bundle.winner!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          children: [
            Shimmer.fromColors(
              baseColor: const Color(0xFF2A1A10),
              highlightColor: const Color(0xFF6B4226),
              period: const Duration(milliseconds: 2200),
              child: _WinnerCard(winner: winner, savingAmount: bundle.savingAmount, pulseController: pulseController),
            ),
            const SizedBox(height: 20),
            const Text('Alternatif Marketler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...bundle.alternatives.asMap().entries.map((entry) {
              return _ComparisonRow(rank: entry.key + 2, market: entry.value, winnerTotal: winner.total);
            }),
          ],
        );
      },
    );
  }
}

class _WinnerCard extends StatelessWidget {
  const _WinnerCard({
    required this.winner,
    required this.savingAmount,
    required this.pulseController,
  });

  final MarketComparison winner;
  final double savingAmount;
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2A1A10), Color(0xFF6B4226)]),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [BoxShadow(color: Color(0x332A1A10), blurRadius: 30, offset: Offset(0, 16))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFC89B7B), borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [Icon(Icons.star, size: 16), SizedBox(width: 4), Text('EN UYGUN', style: TextStyle(fontWeight: FontWeight.w800))]),
          ),
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              final glow = 0.4 + (pulseController.value * 0.6);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC89B7B), width: 2),
                  boxShadow: [BoxShadow(color: Colors.white.withOpacity(glow), blurRadius: 22)],
                ),
                child: Text('${savingAmount.toStringAsFixed(0)}₺ KAZANÇ', style: const TextStyle(fontWeight: FontWeight.w800)),
              );
            },
          ),
        ]),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(winner.marketName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
            Text('${winner.distanceKm.toStringAsFixed(1)} km • Tüm ürünler var', style: const TextStyle(color: Color(0xFFE8D8C8))),
          ]),
          Text('${winner.total.toStringAsFixed(0)}₺', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2A1A10),
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Text('Markete Git', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(width: 8), Icon(Icons.directions_walk)],
          ),
        ),
      ]),
    );
  }
}

class _ComparisonRow extends StatefulWidget {
  const _ComparisonRow({required this.rank, required this.market, required this.winnerTotal});

  final int rank;
  final MarketComparison market;
  final double winnerTotal;

  @override
  State<_ComparisonRow> createState() => _ComparisonRowState();
}

class _ComparisonRowState extends State<_ComparisonRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final diff = widget.market.total - widget.winnerTotal;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    CircleAvatar(backgroundColor: const Color(0xFFF2ECE6), child: Text('${widget.rank}')),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.market.marketName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${widget.market.distanceKm.toStringAsFixed(1)} km • ${widget.market.hasAllProducts ? 'Eksik Yok' : 'Eksik Ürün Var'}'),
                    ])
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${widget.market.total.toStringAsFixed(0)}₺', style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('+${diff.toStringAsFixed(0)}₺ Fark', style: const TextStyle(color: Color(0xFFA33333), fontWeight: FontWeight.w700)),
                  ]),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeInOutCubic,
            height: _expanded ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 240),
              opacity: _expanded ? 1 : 0,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      child: Column(
                        children: widget.market.productDiffs
                            .where((e) => e.isHigher)
                            .map(
                              (diffItem) => Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(diffItem.productName),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0x14A33333),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${diffItem.marketPrice.toStringAsFixed(0)}₺ (+${diffItem.delta.toStringAsFixed(0)}₺)',
                                        style: const TextStyle(color: Color(0xFFA33333), fontWeight: FontWeight.w800, fontSize: 12),
                                      ),
                                    )
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
    );
  }
}

class _CompactSummary extends StatelessWidget {
  const _CompactSummary({required this.itemCount, required this.estimated});

  final int itemCount;
  final double estimated;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.82), borderRadius: BorderRadius.circular(18)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.shopping_bag, color: Color(0xFF6B4226)),
                const SizedBox(width: 6),
                Text('$itemCount Ürün', style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
              Container(width: 1, height: 24, color: const Color(0xFFE8D8C8)),
              Row(children: [
                const Icon(Icons.payments, color: Color(0xFFC89B7B)),
                const SizedBox(width: 6),
                Text('${NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2).format(estimated)} Tahmini', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFC89B7B))),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

final ThemeData _premiumTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFFF9F6F2),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF6B4226),
    secondary: Color(0xFFC89B7B),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF2A1A10),
    error: Color(0xFFA33333),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Color(0xFF2A1A10), fontFamily: 'Outfit'),
  ),
);
