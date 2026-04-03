import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/theme/app_colors.dart';
import '../widgets/app_widgets.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(children: [
        const StatusBar(),
        const AppTopBar(title: 'Karşılaştırma'),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color.fromRGBO(196, 165, 123, 0.08), Color.fromRGBO(196, 165, 123, 0.02)]),
                borderRadius: BorderRadius.circular(AppColors.radiusXl),
                border: Border.all(color: const Color.fromRGBO(196, 165, 123, 0.25)),
              ),
              child: const Column(children: [
                Text('EN İYİ KOMBİNASYON', style: TextStyle(fontSize: 11, color: AppColors.textSubtle, fontWeight: FontWeight.w600)),
                Text('₺3.847', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              ]),
            ),
            const SizedBox(height: 16),
            const LiveFeedItem(emoji: '🎧', name: 'Sony WH-1000XM5', meta: 'Adet: 1 • Trendyol', price: '₺1.299'),
            PrimaryButton(label: "Platform'lara Git", icon: FontAwesomeIcons.upRightFromSquare, onTap: () {}),
          ]),
        ),
      ]),
    );
  }
}
