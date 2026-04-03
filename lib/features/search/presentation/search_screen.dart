import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final filters = ['Market', 'Elektronik', 'Gıda', 'Bakım', 'Ev'];
    final results = [
      ('Bluetooth Hoparlör', '₺899', 'Amazon', '1 dk önce'),
      ('Protein Tozu', '₺749', 'Trendyol', '4 dk önce'),
      ('Airfryer', '₺2.599', 'Hepsiburada', '10 dk önce'),
    ];

    return SafeArea(
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            const SliverAppBar(
              pinned: true,
              title: Text('Ara'),
              backgroundColor: AppColors.bgPrimary,
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickySearchDelegate(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (_, index) => _FilterChip(label: filters[index]),
                        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                        itemCount: filters.length,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ...results.map((result) => _ResultTile(result: result)),
                    const SizedBox(height: AppSpacing.xl),
                    const _EmptyState(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get maxExtent => 84;

  @override
  double get minExtent => 84;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.bgPrimary,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Ara: ürün, marka, platform',
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppColors.textSecondary),
            icon: Icon(Icons.search, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result});

  final (String, String, String, String) result;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: AppColors.tan),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.$1),
                const SizedBox(height: AppSpacing.xs),
                Text('${result.$3} • ${result.$4}', style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(result.$2, style: const TextStyle(color: AppColors.tan, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, color: AppColors.textSecondary),
          SizedBox(height: AppSpacing.sm),
          Text('Aradığınız kriterde sonuç bulunamadı.', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
