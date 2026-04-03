import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = ['Airfryer XL', 'Filtre Kahve Makinesi', 'Blender Seti'];
    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: const _CartBottomBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Karşılaştırma', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.lg),
              const _SummaryCard(),
              const SizedBox(height: AppSpacing.md),
              const _ToggleCompare(),
              const SizedBox(height: AppSpacing.md),
              ...products.map((p) => _ProductCard(name: p)),
              const SizedBox(height: AppSpacing.lg),
              const _PlatformDistribution(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Toplam'), Text('₺8.149', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700))]),
          Chip(label: Text('₺732 Tasarruf', style: TextStyle(color: AppColors.bgPrimary)), backgroundColor: AppColors.success),
        ],
      ),
    );
  }
}

class _ToggleCompare extends StatelessWidget {
  const _ToggleCompare();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ToggleButton(label: 'En İyi Karışık', active: true)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _ToggleButton(label: 'Tek Platform', active: false)),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: active ? AppColors.tan : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(label, style: TextStyle(color: active ? AppColors.bgPrimary : AppColors.textPrimary)),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          CircleAvatar(backgroundColor: AppColors.surfaceAlt, child: Icon(Icons.shopping_bag_outlined)),
          SizedBox(width: AppSpacing.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Ürün'), Text('Amazon Türkiye', style: TextStyle(color: AppColors.textSecondary))])),
          Chip(label: Text('Trust 92', style: TextStyle(color: AppColors.bgPrimary)), backgroundColor: AppColors.success),
        ],
      ),
    );
  }
}

class _PlatformDistribution extends StatelessWidget {
  const _PlatformDistribution();

  @override
  Widget build(BuildContext context) {
    final list = ['Amazon: 2 ürün', 'Hepsiburada: 1 ürün', 'Trendyol: 1 ürün'];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Platform Dağılımı', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          ...list.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(item),
              )),
        ],
      ),
    );
  }
}

class _CartBottomBar extends StatelessWidget {
  const _CartBottomBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceAlt,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: const Row(
        children: [
          Expanded(child: _BottomBtn(label: 'Platformlara Git', filled: true)),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: _BottomBtn(label: 'Paylaş', filled: false)),
        ],
      ),
    );
  }
}

class _BottomBtn extends StatelessWidget {
  const _BottomBtn({required this.label, required this.filled});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: filled ? AppColors.tan : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(label, style: TextStyle(color: filled ? AppColors.bgPrimary : AppColors.textPrimary)),
    );
  }
}
