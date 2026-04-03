import 'package:flutter/material.dart';

import '../widgets/app_widgets.dart';
import 'detail_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const StatusBar(),
        const AppTopBar(title: 'Ara'),
        const SearchInputField(hint: 'Ürün, marka veya kategori ara...', value: 'kablosuz kulaklık'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              LiveFeedItem(
                emoji: '🎧',
                name: 'Sony WH-1000XM5',
                meta: 'Trendyol • 2s',
                price: '₺1.299',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DetailScreen())),
              ),
              LiveFeedItem(
                emoji: '🎧',
                name: 'Bose QuietComfort 45',
                meta: 'Hepsiburada • 5s',
                price: '₺1.349',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DetailScreen())),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
