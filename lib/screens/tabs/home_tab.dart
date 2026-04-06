import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/product_card.dart';
import '../product_detail_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final trending = state.products.take(4).toList();
    final recent = state.products.reversed.take(6).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CoffeeColors.espresso,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.coffee,
                    color: CoffeeColors.cream, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Merhaba ☕',
                        style: TextStyle(
                            color: CoffeeColors.cocoa, fontSize: 13)),
                    Text('FiyatRadar',
                        style: TextStyle(
                            color: CoffeeColors.espresso,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none,
                    color: CoffeeColors.darkRoast),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CoffeeColors.espresso, CoffeeColors.mocha],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Markette gördüğünü\npaylaş, herkes kazansın',
                  style: TextStyle(
                    color: CoffeeColors.cream,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: CoffeeColors.caramel,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: CoffeeColors.espresso, size: 18),
                      SizedBox(width: 6),
                      Text('Fiyat Ekle',
                          style: TextStyle(
                              color: CoffeeColors.espresso,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Öne Çıkan Fırsatlar', onMore: () {}),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.74,
            ),
            itemCount: trending.length,
            itemBuilder: (context, i) {
              final p = trending[i];
              return ProductCard(
                product: p,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: p),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Son Eklenenler', onMore: () {}),
          const SizedBox(height: 12),
          ...recent.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: p),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: CoffeeColors.crema),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: CoffeeColors.foam,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Text(p.emoji,
                              style: const TextStyle(fontSize: 28)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: CoffeeColors.espresso)),
                              Text('${p.brand} • ${p.category}',
                                  style: const TextStyle(
                                      color: CoffeeColors.cocoa,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(
                          p.lowestPrice == null
                              ? '-'
                              : '₺${p.lowestPrice!.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: CoffeeColors.accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onMore});
  final String title;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: CoffeeColors.espresso)),
        ),
        TextButton(
          onPressed: onMore,
          child: const Text('Tümü',
              style: TextStyle(color: CoffeeColors.caramel)),
        ),
      ],
    );
  }
}
