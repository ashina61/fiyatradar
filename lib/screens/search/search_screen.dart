import 'package:flutter/material.dart';

import '../../theme/neo_design.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NeoScaffold(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ara', style: NeoDesign.title()),
            const SizedBox(height: 10),
            TextField(
              decoration: NeoDesign.input('Ürün, marka veya kategori', icon: Icons.search),
              controller: _controller,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                Chip(label: Text('İndirimli Ürünler')),
                Chip(label: Text('Temel Gıda')),
                Chip(label: Text('Kişisel Bakım')),
                Chip(label: Text('Teknoloji')),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 8,
                itemBuilder: (_, index) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: NeoDesign.glassCard(),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_basket_outlined, color: NeoDesign.warning),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Örnek ürün ${index + 1}', style: NeoDesign.body(color: NeoDesign.text))),
                      Text('₺${(index + 1) * 19}', style: NeoDesign.body(color: NeoDesign.secondary)),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
