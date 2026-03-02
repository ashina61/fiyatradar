import 'package:flutter/material.dart';

class HorizontalCategoriesWidget extends StatelessWidget {
  const HorizontalCategoriesWidget({super.key});

  static const Color _softBeige = Color(0xFFF5EBE1);
  static const Color _darkBrown = Color(0xFF6B4226);

  static const List<_CategoryItem> _mockCategories = [
    _CategoryItem(name: 'Kişisel Bakım', icon: Icons.face),
    _CategoryItem(name: 'Kitap', icon: Icons.menu_book),
    _CategoryItem(name: 'Spor', icon: Icons.sports_soccer),
    _CategoryItem(name: 'Elektronik', icon: Icons.devices),
    _CategoryItem(name: 'Giyim', icon: Icons.checkroom),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CategoriesHeader(),
        const SizedBox(height: 16),
        SizedBox(
          height: 102,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _mockCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final item = _mockCategories[index];
                return _CategoryItemView(item: item);
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: const [
          _AccentLine(),
          SizedBox(width: 8),
          Text(
            'Kategoriler',
            style: TextStyle(
              color: HorizontalCategoriesWidget._darkBrown,
              fontSize: 18,
              fontWeight: FontWeight.w600,
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
      width: 3,
      height: 16,
      decoration: BoxDecoration(
        color: HorizontalCategoriesWidget._darkBrown,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _CategoryItemView extends StatelessWidget {
  const _CategoryItemView({required this.item});

  final _CategoryItem item;

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
            item.icon,
            color: HorizontalCategoriesWidget._darkBrown,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 74,
          child: Text(
            item.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: HorizontalCategoriesWidget._darkBrown,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryItem {
  const _CategoryItem({required this.name, required this.icon});

  final String name;
  final IconData icon;
}
