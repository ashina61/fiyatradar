import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/product_provider.dart';
import '../../utils/theme.dart';

class NeighborhoodMarketsManagementTab extends ConsumerWidget {
  const NeighborhoodMarketsManagementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketsAsync = ref.watch(neighborhoodMarketsProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _showMarketForm(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Pazar Ekle'),
            ),
          ),
        ),
        Expanded(
          child: marketsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: FilledButton(
                onPressed: () => ref.invalidate(neighborhoodMarketsProvider),
                child: const Text('Tekrar dene'),
              ),
            ),
            data: (markets) {
              if (markets.isEmpty) {
                return const Center(child: Text('Mahalle pazarı kaydı bulunamadı.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                itemCount: markets.length,
                itemBuilder: (context, index) {
                  final market = markets[index];
                  final id = (market['id'] ?? '').toString();
                  final name = (market['name'] ?? '-').toString();
                  final city = (market['city'] ?? '').toString();
                  final district = (market['district'] ?? '').toString();
                  final neighborhood = (market['neighborhood'] ?? '').toString();
                  final isActive = market['isActive'] == true;

                  return Card(
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text([city, district, neighborhood].where((e) => e.trim().isNotEmpty).join(' / ')),
                      leading: IconButton(
                        onPressed: () => _showMarketForm(context, ref, market: market),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      trailing: Switch(
                        value: isActive,
                        onChanged: (value) => ref.read(firestoreServiceProvider).setNeighborhoodMarketActive(id, value),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showMarketForm(BuildContext context, WidgetRef ref, {Map<String, dynamic>? market}) async {
    final nameController = TextEditingController(text: (market?['name'] ?? '').toString());
    final cityController = TextEditingController(text: (market?['city'] ?? '').toString());
    final districtController = TextEditingController(text: (market?['district'] ?? '').toString());
    final neighborhoodController = TextEditingController(text: (market?['neighborhood'] ?? '').toString());
    bool isActive = market?['isActive'] == true;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(market == null ? 'Mahalle Pazarı Ekle' : 'Mahalle Pazarı Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Pazar adı *')),
                TextField(controller: cityController, decoration: const InputDecoration(labelText: 'Şehir')),
                TextField(controller: districtController, decoration: const InputDecoration(labelText: 'İlçe')),
                TextField(controller: neighborhoodController, decoration: const InputDecoration(labelText: 'Mahalle')),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isActive,
                  onChanged: (value) => setState(() => isActive = value),
                  title: const Text('Aktif'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pazar adı zorunludur.')));
                  return;
                }
                final payload = {
                  'name': nameController.text.trim(),
                  'city': cityController.text.trim(),
                  'district': districtController.text.trim(),
                  'neighborhood': neighborhoodController.text.trim(),
                  'isActive': isActive,
                };
                if (market == null) {
                  await ref.read(firestoreServiceProvider).addNeighborhoodMarket(
                        name: payload['name']! as String,
                        city: payload['city']! as String,
                        district: payload['district']! as String,
                        neighborhood: payload['neighborhood']! as String,
                        isActive: payload['isActive']! as bool,
                      );
                } else {
                  await ref.read(firestoreServiceProvider).updateNeighborhoodMarket((market['id'] ?? '').toString(), payload);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
