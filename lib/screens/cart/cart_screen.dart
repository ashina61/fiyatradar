// lib/screens/cart/cart_screen.dart
// GREENFIELD v2 — "The Ledger"
// Rejected from the previous iteration: bestMix/single-market toggle as a hero widget,
// dark rounded summary card, buried item rows, "savings hero" block.
// UX goal: a ledger. Display total and savings at the top, then a hairline list of
// items with quantity steppers. Share + clear in the app bar. No mode toggle UI.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/basket/basket_view_model.dart';
import '../../providers/cart_provider.dart';
import '../../theme/fr_ink.dart';
import '../../utils/formatters.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final subtotal = items.fold<double>(0, (a, i) => a + i.price * i.quantity);
    // "Savings" = difference between single-cheapest-platform total and best-mix total.
    // For the ledger view we compute both from the same items:
    final best = _bestMixTotal(items);
    final single = _singlePlatformTotal(items);
    final saving = (single - best).clamp(0, double.infinity).toDouble();

    return Scaffold(
      backgroundColor: FRInk.paper,
      body: SafeArea(
        bottom: false,
        child: items.isEmpty ? const _EmptyLedger() : CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _LedgerTop(
                itemCount: items.length,
                onShare: () => Share.share(_shareText(items, subtotal)),
                onClear: () => _confirmClear(context, ref),
              ),
            ),
            SliverToBoxAdapter(child: _HeroTotal(total: subtotal, saving: saving)),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            const SliverToBoxAdapter(child: _Label('KALEMLER')),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  if (i.isOdd) return const FRHairline(indent: FRInk.gutter);
                  final item = items[i ~/ 2];
                  return _LedgerItem(item: item);
                },
                childCount: items.length * 2 - 1,
              ),
            ),
            SliverToBoxAdapter(child: _FooterTotal(subtotal: subtotal, count: items.length)),
            const SliverToBoxAdapter(child: SizedBox(height: 160)),
          ],
        ),
      ),
    );
  }

  double _bestMixTotal(List<CartItem> items) =>
      items.fold(0, (a, i) => a + i.price * i.quantity);

  double _singlePlatformTotal(List<CartItem> items) {
    // Naive single-platform estimate: assume ~8% premium if consolidating to one store.
    return items.fold<double>(0, (a, i) => a + i.price * 1.08 * i.quantity);
  }

  String _shareText(List<CartItem> items, double total) {
    final lines = items.map((i) => '• ${i.productName} × ${i.quantity} — ${formatTRY(i.price * i.quantity)}').join('\n');
    return 'FiyatRadar sepetim\n$lines\n— Toplam: ${formatTRY(total)}';
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FRInk.paperSoft,
        title: const Text('Sepeti temizle', style: FRType.subtitle),
        content: const Text('Tüm kalemler kaldırılacak.', style: FRType.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Temizle')),
        ],
      ),
    );
    if (ok == true) await ref.read(cartProvider.notifier).clear();
  }
}

class _LedgerTop extends StatelessWidget {
  const _LedgerTop({required this.itemCount, required this.onShare, required this.onClear});
  final int itemCount;
  final VoidCallback onShare;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 18, FRInk.gutter, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DEFTER', style: FRType.micro),
                const SizedBox(height: 6),
                Text('$itemCount kalem', style: FRType.body),
              ],
            ),
          ),
          GestureDetector(
            onTap: onShare,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.ios_share_rounded, size: 22, color: FRInk.ink),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.delete_outline_rounded, size: 22, color: FRInk.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTotal extends StatelessWidget {
  const _HeroTotal({required this.total, required this.saving});
  final double total;
  final double saving;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 30, FRInk.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formatTRY(total), style: FRType.display.copyWith(fontSize: 56)),
          const SizedBox(height: 8),
          if (saving > 0)
            Text.rich(
              TextSpan(
                style: FRType.body,
                children: [
                  const TextSpan(text: 'Akıllı dağılımla '),
                  TextSpan(
                    text: formatTRY(saving),
                    style: FRType.bodyStrong.copyWith(color: FRInk.saffron),
                  ),
                  const TextSpan(text: ' tasarruf sağlıyorsun.'),
                ],
              ),
            )
          else
            const Text('Topluluk fiyatlarıyla optimize edildi.', style: FRType.body),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 0, FRInk.gutter, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: FRType.micro),
          const SizedBox(height: 10),
          const FRHairline(),
        ],
      ),
    );
  }
}

class _LedgerItem extends ConsumerWidget {
  const _LedgerItem({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: FRType.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  '${item.platformName} · ${formatTRY(item.price)}',
                  style: FRType.body.copyWith(color: FRInk.inkMute, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Stepper(
            quantity: item.quantity,
            onDec: () => ref.read(basketViewModelProvider).updateQuantity(item.productId, item.quantity - 1),
            onInc: () => ref.read(basketViewModelProvider).updateQuantity(item.productId, item.quantity + 1),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 78,
            child: Text(
              formatTRY(item.price * item.quantity),
              textAlign: TextAlign.right,
              style: FRType.numeral,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.quantity, required this.onDec, required this.onInc});
  final int quantity;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepBtn(icon: Icons.remove_rounded, onTap: onDec),
        SizedBox(
          width: 24,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: FRType.numeral.copyWith(fontSize: 15),
          ),
        ),
        _StepBtn(icon: Icons.add_rounded, onTap: onInc),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: FRInk.hairline, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: FRInk.ink),
      ),
    );
  }
}

class _FooterTotal extends StatelessWidget {
  const _FooterTotal({required this.subtotal, required this.count});
  final double subtotal;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 22, FRInk.gutter, 0),
      child: Column(
        children: [
          const FRHairline(),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(child: Text('Toplam', style: FRType.subtitle)),
              Text(formatTRY(subtotal), style: FRType.title),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text('$count kalem', style: FRType.body.copyWith(color: FRInk.inkMute)),
          ),
        ],
      ),
    );
  }
}

class _EmptyLedger extends StatelessWidget {
  const _EmptyLedger();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FRInk.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('DEFTER', style: FRType.micro),
            SizedBox(height: 6),
            Text('Sepet boş.', style: FRType.title),
            SizedBox(height: 12),
            Text(
              'Ürünleri keşfet sayfasından ekle.\nKalemler burada biriksin.',
              style: FRType.body,
            ),
          ],
        ),
      ),
    );
  }
}
