import 'package:flutter/material.dart';

import '../../theme/neo_design.dart';

class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NeoScaffold(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sepet Motoru', style: NeoDesign.title()),
            const SizedBox(height: 8),
            Text('Yeni mimariye uygun tek ekran karşılaştırma görünümü.', style: NeoDesign.body()),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: const [
                  _BasketCard(store: 'Market A', total: '₺1.242', saving: '₺86 avantaj'),
                  SizedBox(height: 10),
                  _BasketCard(store: 'Market B', total: '₺1.270', saving: '₺58 avantaj'),
                  SizedBox(height: 10),
                  _BasketCard(store: 'Market C', total: '₺1.328', saving: '₺0'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _BasketCard extends StatelessWidget {
  const _BasketCard({required this.store, required this.total, required this.saving});

  final String store;
  final String total;
  final String saving;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NeoDesign.glassCard(),
      child: Row(
        children: [
          const Icon(Icons.store_mall_directory_outlined, color: NeoDesign.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(store, style: NeoDesign.body(color: NeoDesign.text))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(total, style: NeoDesign.title(18)),
              Text(saving, style: NeoDesign.body(color: NeoDesign.secondary)),
            ],
          )
        ],
      ),
    );
  }
}
