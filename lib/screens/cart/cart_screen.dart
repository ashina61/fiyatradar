// lib/screens/cart/cart_screen.dart
// GREENFIELD — savings-first comparison planner
// Rejected: dark summary card on white, toggle as primary UI focus, buried platform info
// UX goal: "How much do I save?" is the hero number — everything supports that decision

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/cart_provider.dart';
import '../../theme/fr_colors.dart';
import '../../utils/formatters.dart';

const _kPad = 24.0;
const _kCardR = 20.0;
const _kShadow = BoxShadow(color: Color(0x0A211510), blurRadius: 12, offset: Offset(0, 3));

// ─────────────────────────────────────────────────────────────────────────────
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

    return Scaffold(
      backgroundColor: FRColors.backgroundWarm,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _PageHeader(itemCount: items.length, onClear: items.isEmpty ? null : () => _confirmClear(context)),
            Expanded(
              child: items.isEmpty
                  ? const _EmptyCart()
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Savings hero
                        SliverToBoxAdapter(child: _SavingsHero(best: best, single: single)),
                        // Mode toggle
                        SliverToBoxAdapter(
                          child: _ModeToggle(
                            bestMix: _bestMix,
                            onToggle: (v) => setState(() => _bestMix = v),
                          ),
                        ),
                        // Items
                        SliverToBoxAdapter(
                          child: _ItemsSection(items: active.items),
                        ),
                        // Platform breakdown
                        SliverToBoxAdapter(
                          child: _PlatformBreakdown(combination: active),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 130)),
                      ],
                    ),
            ),
            if (items.isNotEmpty) _ActionBar(combination: active, onShare: () => _share(active)),
          ],
        ),
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

  Map<String, List<CartItem>> _byPlatform(List<CartItem> items) {
    final map = <String, List<CartItem>>{};
    for (final i in items) {
      map.putIfAbsent(i.platformName, () => []).add(i);
    }
    return map;
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FRColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Listeyi temizle?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: FRColors.textPrimary)),
        content: const Text('Tüm ürünler karşılaştırma listesinden kaldırılır.',
            style: TextStyle(fontSize: 13, color: FRColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(cartProvider.notifier).clear();
              if (!mounted) return;
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FRColors.espresso,
              foregroundColor: FRColors.tan,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Temizle', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _share(CartCombination c) {
    final text = 'FiyatRadar Karşılaştırma:\n\n'
        '${c.items.map((i) => '• ${i.productName}: ${formatTRY(i.price * i.quantity)} (${i.platformName})').join('\n')}\n\n'
        'Toplam: ${formatTRY(c.total)}';
    Share.share(text);
  }
}

// ─── Page header ──────────────────────────────────────────────────────────────
class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.itemCount, required this.onClear});
  final int itemCount;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kPad, 18, _kPad, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Karşılaştırma',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: FRColors.espresso,
                  height: 1,
                ),
              ),
              if (itemCount > 0) ...[
                const SizedBox(height: 3),
                Text(
                  '$itemCount ürün listelendi',
                  style: const TextStyle(fontSize: 13, color: FRColors.textMuted),
                ),
              ],
            ],
          ),
          const Spacer(),
          if (onClear != null)
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: FRColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: FRColors.border),
                ),
                child: const Text(
                  'Temizle',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FRColors.textMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Savings hero ─────────────────────────────────────────────────────────────
class _SavingsHero extends StatelessWidget {
  const _SavingsHero({required this.best, required this.single});
  final CartCombination best;
  final CartCombination single;

  @override
  Widget build(BuildContext context) {
    final savings = single.total - best.total;
    final hasSavings = savings > 0.5;

    return Container(
      margin: const EdgeInsets.fromLTRB(_kPad, 22, _kPad, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(_kCardR),
        border: Border.all(color: FRColors.border),
        boxShadow: const [_kShadow],
      ),
      child: Column(
        children: [
          const Text(
            'EN İYİ FİYAT TOPLAMI',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: FRColors.textMuted,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            formatTRY(best.total),
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: FRColors.espresso,
              height: 1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 14),
          if (hasSavings)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: FRColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: FRColors.success.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trending_down_rounded, size: 15, color: FRColors.success),
                  const SizedBox(width: 7),
                  Text(
                    '${formatTRY(savings)} tasarruf',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: FRColors.success,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              '${best.platformCount} farklı platform',
              style: const TextStyle(fontSize: 13, color: FRColors.textMuted),
            ),
        ],
      ),
    );
  }
}

// ─── Mode toggle ──────────────────────────────────────────────────────────────
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.bestMix, required this.onToggle});
  final bool bestMix;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kPad, 16, _kPad, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: FRColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FRColors.border),
        ),
        child: Row(
          children: [
            _Tab(label: 'En İyi Karışık', icon: Icons.auto_awesome_rounded, active: bestMix, onTap: () => onToggle(true)),
            _Tab(label: 'Tek Platform', icon: Icons.store_rounded, active: !bestMix, onTap: () => onToggle(false)),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.icon, required this.active, required this.onTap});
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? FRColors.espresso : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: active ? FRColors.tan : FRColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : FRColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Items section ────────────────────────────────────────────────────────────
class _ItemsSection extends StatelessWidget {
  const _ItemsSection({required this.items});
  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kPad, 24, _kPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ÜRÜNLERİNİZ',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: FRColors.textMuted, letterSpacing: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: FRColors.surface,
              borderRadius: BorderRadius.circular(_kCardR),
              border: Border.all(color: FRColors.border),
              boxShadow: const [_kShadow],
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  _ItemRow(item: items[i]),
                  if (i < items.length - 1)
                    const Divider(height: 1, indent: 76, endIndent: 16, color: Color(0x07211510)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.imageUrl?.isNotEmpty == true
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _thumb(),
                  )
                : _thumb(),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: FRColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: FRColors.backgroundWarm,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.platformName,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: FRColors.textMuted),
                      ),
                    ),
                    if (item.quantity > 1) ...[
                      const SizedBox(width: 6),
                      Text(
                        'x${item.quantity}',
                        style: const TextStyle(fontSize: 11, color: FRColors.textSubtle),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatTRY(item.price * item.quantity),
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: FRColors.espresso,
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb() => Container(
        width: 52,
        height: 52,
        color: FRColors.backgroundWarm,
        child: const Icon(Icons.category_outlined, size: 20, color: FRColors.textSubtle),
      );
}

// ─── Platform breakdown ───────────────────────────────────────────────────────
class _PlatformBreakdown extends StatelessWidget {
  const _PlatformBreakdown({required this.combination});
  final CartCombination combination;

  @override
  Widget build(BuildContext context) {
    final byPlatform = <String, List<CartItem>>{};
    for (final i in combination.items) {
      byPlatform.putIfAbsent(i.platformName, () => []).add(i);
    }

    if (byPlatform.length <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(_kPad, 20, _kPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PLATFORM ÖZETI',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: FRColors.textMuted, letterSpacing: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: FRColors.surface,
              borderRadius: BorderRadius.circular(_kCardR),
              border: Border.all(color: FRColors.border),
              boxShadow: const [_kShadow],
            ),
            child: Column(
              children: [
                for (var e in byPlatform.entries.toList().asMap().entries) ...[
                  _PlatformRow(
                    name: e.value.key,
                    items: e.value.value,
                    isLast: e.key == byPlatform.length - 1,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformRow extends StatelessWidget {
  const _PlatformRow({required this.name, required this.items, required this.isLast});
  final String name;
  final List<CartItem> items;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (s, i) => s + i.price * i.quantity);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: FRColors.espresso,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: FRColors.tan),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: FRColors.textPrimary)),
                    Text('${items.length} ürün', style: const TextStyle(fontSize: 11, color: FRColors.textMuted)),
                  ],
                ),
              ),
              Text(
                formatTRY(total),
                style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w800, color: FRColors.espresso),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0x06211510)),
      ],
    );
  }
}

// ─── Action bar ───────────────────────────────────────────────────────────────
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.combination, required this.onShare});
  final CartCombination combination;
  final VoidCallback onShare;

  Future<void> _openLinks() async {
    final platforms = <String>{};
    for (final i in combination.items) {
      platforms.add(i.platformName);
    }
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
    for (final p in platforms) {
      final url = urls[p];
      if (url != null) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(_kPad, 14, _kPad, 0),
      decoration: const BoxDecoration(
        color: FRColors.surface,
        border: Border(top: BorderSide(color: Color(0x08211510))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _openLinks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FRColors.espresso,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.open_in_new_rounded, size: 17, color: FRColors.tan),
                    SizedBox(width: 10),
                    Text('Platformlara Git', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined, size: 16),
                label: const Text('Listeyi Paylaş'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FRColors.textPrimary,
                  side: const BorderSide(color: FRColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: FRColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: FRColors.border),
                boxShadow: const [_kShadow],
              ),
              child: const Icon(Icons.compare_arrows_rounded, size: 32, color: FRColors.textSubtle),
            ),
            const SizedBox(height: 22),
            const Text(
              'Karşılaştırma Listesi Boş',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: FRColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Keşfet\'te ürün bulup listeye ekle,\nen iyi fiyatı birlikte hesaplayalım.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: FRColors.textMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data models ─────────────────────────────────────────────────────────────
class CartCombination {
  const CartCombination({
    required this.items,
    required this.total,
    required this.platformCount,
  });

  final List<CartItem> items;
  final double total;
  final int platformCount;
}
