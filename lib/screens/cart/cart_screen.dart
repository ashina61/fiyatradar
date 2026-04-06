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
    final best = _bestMixTotal(items);
    final single = _singlePlatformTotal(items);
    final saving = (single - best).clamp(0, double.infinity).toDouble();

    return Scaffold(
      backgroundColor: FRInk.paper,
      body: SafeArea(
        bottom: false,
        child: items.isEmpty
            ? const _EmptyLedger()
            : ListView(
                padding: const EdgeInsets.fromLTRB(FRInk.gutter, 12, FRInk.gutter, 140),
                children: [
                  _TopActions(
                    itemCount: items.length,
                    onShare: () => Share.share(_shareText(items, subtotal)),
                    onClear: () => _confirmClear(context, ref),
                  ),
                  const SizedBox(height: 14),
                  _SummaryCard(total: subtotal, saving: saving),
                  const SizedBox(height: 18),
                  const Text('SEPET KALEMLERİ', style: FRType.micro),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: FRInk.paperSoft, borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          _LedgerItem(item: items[i]),
                          if (i != items.length - 1)
                            const Divider(height: 1, indent: 16, endIndent: 16, color: FRInk.hairline),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  double _bestMixTotal(List<CartItem> items) => items.fold(0, (a, i) => a + i.price * i.quantity);

  double _singlePlatformTotal(List<CartItem> items) {
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

class _TopActions extends StatelessWidget {
  const _TopActions({required this.itemCount, required this.onShare, required this.onClear});
  final int itemCount;
  final VoidCallback onShare;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Sepet ($itemCount)', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: FRInk.ink)),
        const Spacer(),
        _ActionIcon(icon: Icons.ios_share_rounded, onTap: onShare),
        const SizedBox(width: 8),
        _ActionIcon(icon: Icons.delete_outline_rounded, onTap: onClear),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: FRInk.paperSoft, borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: FRInk.ink),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total, required this.saving});
  final double total;
  final double saving;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: FRInk.dark, borderRadius: BorderRadius.circular(30)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SEPET ÖZETİ', style: TextStyle(color: FRInk.goldSoft, letterSpacing: 2, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 8),
          Text(formatTRY(total), style: const TextStyle(fontSize: 46, color: FRInk.paperSoft, fontWeight: FontWeight.w800, height: 1.0)),
          const SizedBox(height: 8),
          Text(
            saving > 0
                ? 'Akıllı dağılımla ${formatTRY(saving)} tasarruf sağlıyorsun.'
                : 'Topluluk fiyatlarıyla optimize edildi.',
            style: const TextStyle(color: FRInk.goldSoft, fontSize: 15),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: FRType.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${item.platformName} · ${formatTRY(item.price)}', style: FRType.body.copyWith(color: FRInk.inkMute, fontSize: 13)),
              ],
            ),
          ),
          _Stepper(
            quantity: item.quantity,
            onDec: () => ref.read(basketViewModelProvider).updateQuantity(item.productId, item.quantity - 1),
            onInc: () => ref.read(basketViewModelProvider).updateQuantity(item.productId, item.quantity + 1),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 80, child: Text(formatTRY(item.price * item.quantity), textAlign: TextAlign.right, style: FRType.numeral)),
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
        SizedBox(width: 24, child: Text('$quantity', textAlign: TextAlign.center, style: FRType.numeral.copyWith(fontSize: 15))),
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: FRInk.paperDeep, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: FRInk.ink),
      ),
    );
  }
}

class _EmptyLedger extends StatelessWidget {
  const _EmptyLedger();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Sepet boş. Ürün ekleyerek karşılaştırmayı başlat.', textAlign: TextAlign.center, style: FRType.body),
      ),
    );
  }
}
