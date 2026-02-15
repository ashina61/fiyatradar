import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/product_provider.dart';

class NeighborhoodMarketsScreen extends ConsumerWidget {
  const NeighborhoodMarketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketsAsync = ref.watch(neighborhoodMarketsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mahalle Pazarları')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddNeighborhoodMarketScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Pazar Ekle'),
      ),
      body: marketsAsync.when(
        data: (markets) => ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: markets.length,
          itemBuilder: (context, index) {
            final market = markets[index];
            return ListTile(
              title: Text((market['name'] ?? '-').toString()),
              subtitle: Text('${market['district'] ?? ''} / ${market['neighborhood'] ?? ''}'),
              trailing: market['verified'] == true ? const Chip(label: Text('Doğrulandı')) : const Chip(label: Text('Topluluk Onayı')),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Pazarlar yüklenemedi.')),
      ),
    );
  }
}

class AddNeighborhoodMarketScreen extends ConsumerStatefulWidget {
  const AddNeighborhoodMarketScreen({super.key});

  @override
  ConsumerState<AddNeighborhoodMarketScreen> createState() => _AddNeighborhoodMarketScreenState();
}

class _AddNeighborhoodMarketScreenState extends ConsumerState<AddNeighborhoodMarketScreen> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _neighborhood = TextEditingController();
  final _days = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mahalle Pazarı Ekle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Pazar adı')),
            TextField(controller: _city, decoration: const InputDecoration(labelText: 'Şehir')),
            TextField(controller: _district, decoration: const InputDecoration(labelText: 'İlçe')),
            TextField(controller: _neighborhood, decoration: const InputDecoration(labelText: 'Mahalle')),
            TextField(controller: _days, decoration: const InputDecoration(labelText: 'Günler (virgülle)')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) return;
                await ref.read(firestoreServiceProvider).addNeighborhoodMarket(
                  uid: uid,
                  name: _name.text.trim(),
                  city: _city.text.trim(),
                  district: _district.text.trim(),
                  neighborhood: _neighborhood.text.trim(),
                  days: _days.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                  location: null,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
