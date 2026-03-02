import 'package:flutter/material.dart';

import '../models/category_model.dart';
import '../models/category_theme.dart';
import '../utils/material_icon_resolver.dart';

class HorizontalCategoriesWidget extends StatelessWidget {
  const HorizontalCategoriesWidget({super.key});

  static const Color _softBeige = Color(0xFFF5EBE1);
  static const Color _darkBrown = Color(0xFF6B4226);
  static const Color _accentBrown = Color(0xFFAF6B3E);

  static final List<CategoryModel> _homeCategories =
      CategoryThemeCatalog.themes
          .where((theme) => theme.id != 'diger')
          .map(
            (theme) => CategoryModel(
              id: theme.id,
              title: theme.title,
              isActive: true,
              canonicalId: theme.id,
              sort: theme.sortOrder,
              iconAssetPath: theme.iconAssetPath,
              iconName: 'category',
            ),
          )
          .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CategoriesHeader(),
        const SizedBox(height: 15),
        SizedBox(
          height: 108,
          child: ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _homeCategories.length,
              itemBuilder: (context, index) {
                final category = _homeCategories[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == _homeCategories.length - 1 ? 0 : 20,
                  ),
                  child: _CategoryItemView(category: category),
                );
              },
            ),
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
    return const Padding(
      padding: EdgeInsets.only(left: 16, right: 20),
      child: Row(
        children: [
          _AccentLine(),
          SizedBox(width: 12),
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
      height: 24,
      decoration: BoxDecoration(
        color: HorizontalCategoriesWidget._accentBrown,
        borderRadius: BorderRadius.circular(4),
      ),
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
