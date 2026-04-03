import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/state/user_state.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_widgets.dart';
import 'cart_screen.dart';
import 'detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onTabChange});
  final ValueChanged<int> onTabChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);

    return Column(
      children: [
        const StatusBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Merhaba, $userName', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSubtle)),
                  const Text.rich(
                    TextSpan(
                      text: 'Fiyat',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      children: [TextSpan(text: 'Radar', style: TextStyle(color: AppColors.tan))],
                    ),
                  ),
                ]),
              ),
              InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())), child: const FaIcon(FontAwesomeIcons.cartShopping, color: AppColors.tan, size: 18)),
            ],
          ),
        ),
        SearchInputField(
          hint: 'Ürün, marka veya kategori ara...',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              const Text('Canlı Fiyatlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              LiveFeedItem(
                emoji: '🎧',
                name: 'Sony WH-1000XM5',
                meta: 'Trendyol • 2s',
                price: '₺1.299',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DetailScreen())),
              ),
              LiveFeedItem(
                emoji: '📚',
                name: 'Simyacı',
                meta: 'D&R • 12s',
                price: '₺89',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DetailScreen())),
              ),
              const SizedBox(height: 20),
              PrimaryButton(label: 'Fiyat Ekle', icon: FontAwesomeIcons.plus, onTap: () => onTabChange(2)),
            ],
          ),
        )
      ],
    );
  }
}
