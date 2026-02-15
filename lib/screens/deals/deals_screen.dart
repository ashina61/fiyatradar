import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/product_provider.dart';
import '../../utils/theme.dart';

class DealsScreen extends ConsumerWidget {
  const DealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealsAsync = ref.watch(weeklyDealsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Aktüel')),
      body: SafeArea(
        child: dealsAsync.when(
          data: (deals) => ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: deals.length,
            itemBuilder: (context, index) {
              final deal = deals[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text((deal['marketId'] ?? 'Market').toString()),
                  subtitle: Text('${deal['startDate'] ?? '-'} - ${deal['endDate'] ?? '-'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => DealItemsScreen(
                      dealId: deal['id'].toString(),
                      title: (deal['marketId'] ?? 'Aktüel').toString(),
                    ),
                  )),
                ),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Aktüel verileri yüklenemedi.')),
        ),
      ),
    );
  }
}

class DealItemsScreen extends ConsumerWidget {
  const DealItemsScreen({super.key, required this.dealId, required this.title});

  final String dealId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(dealItemsProvider(dealId));
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: itemsAsync.when(
        data: (items) => ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final dealItemId = item['id'].toString();
            const branchId = 'default';
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((item['productName'] ?? 'Ürün').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('Aktüel: ₺${item['dealPrice'] ?? '-'}  • Normal: ₺${item['normalPrice'] ?? '-'}'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _StockButton(label: 'Stok Var', color: Colors.green, onTap: user == null ? null : () async {
                          final rewarded = await ref.read(firestoreServiceProvider).submitStockReport(uid: user.uid, dealItemId: dealItemId, branchId: branchId, status: 'in_stock');
                          if (!context.mounted) return;
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(rewarded ? 'Teşekkürler! +2 puan kazandın.' : 'Stok bildirimi güncellendi.')));
                        }),
                        _StockButton(label: 'Az Kaldı', color: Colors.orange, onTap: user == null ? null : () async {
                          final rewarded = await ref.read(firestoreServiceProvider).submitStockReport(uid: user.uid, dealItemId: dealItemId, branchId: branchId, status: 'low_stock');
                          if (!context.mounted) return;
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(rewarded ? 'Teşekkürler! +2 puan kazandın.' : 'Stok bildirimi güncellendi.')));
                        }),
                        _StockButton(label: 'Stok Bitti', color: Colors.red, onTap: user == null ? null : () async {
                          final rewarded = await ref.read(firestoreServiceProvider).submitStockReport(uid: user.uid, dealItemId: dealItemId, branchId: branchId, status: 'out_of_stock');
                          if (!context.mounted) return;
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(rewarded ? 'Teşekkürler! +2 puan kazandın.' : 'Stok bildirimi güncellendi.')));
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<Map<String, int>>(
                      stream: ref.read(firestoreServiceProvider).getStockSummary(dealItemId: dealItemId, branchId: branchId),
                      builder: (context, snapshot) {
                        final data = snapshot.data ?? const {'in_stock': 0, 'low_stock': 0, 'out_of_stock': 0};
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
                          child: Text('Stok: ✅${data['in_stock']}  🟠${data['low_stock']}  ❌${data['out_of_stock']}', style: const TextStyle(fontSize: 12)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Ürünler yüklenemedi.')),
      ),
    );
  }
}

class _StockButton extends StatelessWidget {
  const _StockButton({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
