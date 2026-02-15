import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/product_provider.dart';

class NeighborhoodMarketsScreen extends ConsumerWidget {
  const NeighborhoodMarketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketsAsync = ref.watch(activeNeighborhoodMarketsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mahalle Pazarları')),
      body: marketsAsync.when(
        data: (markets) => ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: markets.length,
          itemBuilder: (context, index) {
            final market = markets[index];
            return ListTile(
              title: Text((market['name'] ?? '-').toString()),
              subtitle: Text('${market['district'] ?? ''} / ${market['neighborhood'] ?? ''}'),
              trailing: const Chip(label: Text('Aktif')),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Pazarlar yüklenemedi.')),
      ),
    );
  }
}
