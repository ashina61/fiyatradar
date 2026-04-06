import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/product_card.dart';
import '../product_detail_screen.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  String _selectedCategory = 'Tümü';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final filtered = state.products.where((p) {
      final matchCat = _selectedCategory == 'Tümü' ||
          p.category == _selectedCategory;
      final matchQ = _query.isEmpty ||
          p.name.toLowerCase().contains(_query.toLowerCase()) ||
          p.brand.toLowerCase().contains(_query.toLowerCase());
      return matchCat && matchQ;
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Keşfet',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: CoffeeColors.espresso)),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CoffeeColors.foam,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune,
                      color: CoffeeColors.darkRoast),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Ürün, marka ara…',
                prefixIcon: Icon(Icons.search, color: CoffeeColors.cocoa),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: state.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = state.categories[i];
                final selected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? CoffeeColors.espresso
                          : CoffeeColors.foam,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: selected
                              ? CoffeeColors.espresso
                              : CoffeeColors.crema),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: selected
                            ? CoffeeColors.cream
                            : CoffeeColors.darkRoast,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Sonuç bulunamadı',
                        style: TextStyle(color: CoffeeColors.cocoa)),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.74,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      return ProductCard(
                        product: p,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(product: p),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
