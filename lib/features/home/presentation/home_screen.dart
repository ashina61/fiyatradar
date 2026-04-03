import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final liveItems = [
      ('🧴', 'Şampuan Pro', '₺189', '2 dk önce • Trendyol'),
      ('☕', 'Kahve Çekirdeği', '₺329', '5 dk önce • Hepsiburada'),
      ('🎧', 'Kablosuz Kulaklık', '₺1.299', '9 dk önce • Amazon'),
    ];

    final picks = ['Haftanın Fırsatı', 'Doğrulanan Düşüşler', 'Topluluk Seçimi'];

    return SafeArea(
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/add-price'),
          backgroundColor: AppColors.tan,
          label: const Text('Ekle'),
          icon: const Icon(Icons.add),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: AppSpacing.lg),
              _SearchBar(onTap: () => context.push('/search')),
              const SizedBox(height: AppSpacing.xl),
              const _SectionTitle(title: 'Canlı Fiyatlar'),
              const SizedBox(height: AppSpacing.md),
              ...liveItems.map((item) => _LivePriceTile(item: item)),
              const SizedBox(height: AppSpacing.xl),
              const _SectionTitle(title: 'Seçkiler'),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, index) => _PickCard(title: picks[index]),
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                  itemCount: picks.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Merhaba,', style: TextStyle(color: AppColors.textSecondary)),
        SizedBox(height: AppSpacing.xs),
        Text('FiyatRadar', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: AppColors.textSecondary),
            SizedBox(width: AppSpacing.md),
            Text('Ürün, market veya kategori ara', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600));
  }
}

class _LivePriceTile extends StatelessWidget {
  const _LivePriceTile({required this.item});

  final (String, String, String, String) item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/detail'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(item.$1, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(item.$4, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(item.$3, style: const TextStyle(color: AppColors.tan, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _PickCard extends StatelessWidget {
  const _PickCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.tan),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
