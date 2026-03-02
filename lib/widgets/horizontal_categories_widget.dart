import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category_model.dart';
import '../providers/product_provider.dart';
import '../utils/material_icon_resolver.dart';

class HorizontalCategoriesWidget extends ConsumerWidget {
  const HorizontalCategoriesWidget({super.key});

  static const Color _softBeige = Color(0xFFF5EBE1);
  static const Color _darkBrown = Color(0xFF6B4226);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CategoriesHeader(),
        const SizedBox(height: 15),
        SizedBox(
          height: 108,
          child: categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              return ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == categories.length - 1 ? 0 : 20,
                      ),
                      child: _CategoryItemView(category: category),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _CategoriesHeader extends StatelessWidget {
  const _CategoriesHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 20),
      child: Row(
        children: const [
          _AccentLine(),
          SizedBox(width: 20),
          Text(
            'Kategoriler',
            style: TextStyle(
              color: HorizontalCategoriesWidget._darkBrown,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentLine extends StatelessWidget {
  const _AccentLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 38,
      color: HorizontalCategoriesWidget._darkBrown,
    );
  }
}

class _CategoryItemView extends StatelessWidget {
  const _CategoryItemView({required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 65,
          height: 65,
          decoration: const BoxDecoration(
            color: HorizontalCategoriesWidget._softBeige,
            shape: BoxShape.circle,
          ),
          child: Icon(
            materialIconFromName(category.iconName),
            color: HorizontalCategoriesWidget._darkBrown,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          category.title,
          style: const TextStyle(
            color: HorizontalCategoriesWidget._darkBrown,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
