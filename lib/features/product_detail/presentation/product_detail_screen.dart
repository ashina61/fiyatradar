import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: const _BottomActionBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _TopActions(),
              SizedBox(height: AppSpacing.lg),
              _HeroImage(),
              SizedBox(height: AppSpacing.lg),
              _BestPriceCard(),
              SizedBox(height: AppSpacing.lg),
              _TrustAnalysis(),
              SizedBox(height: AppSpacing.lg),
              _ContributorSpotlight(),
              SizedBox(height: AppSpacing.lg),
              _MiniChart(),
              SizedBox(height: AppSpacing.lg),
              _OtherPlatforms(),
              SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopActions extends StatelessWidget {
  const _TopActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionIcon(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
        const Spacer(),
        _ActionIcon(icon: Icons.share_rounded, onTap: () {}),
        const SizedBox(width: AppSpacing.sm),
        _ActionIcon(icon: Icons.bookmark_border_rounded, onTap: () {}),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: CachedNetworkImage(
        imageUrl: 'https://images.unsplash.com/photo-1517336714739-489689fd1ca8?w=900',
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _BestPriceCard extends StatelessWidget {
  const _BestPriceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EN İYİ FİYAT', style: TextStyle(color: AppColors.tan, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          const Text('₺1.299', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.xs),
          const Text('Amazon Türkiye • Doğrulandı', style: TextStyle(color: AppColors.success)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _ActionButton(label: 'Listeye Ekle', filled: true, onTap: () {})),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _ActionButton(label: 'Alarm Kur', filled: false, onTap: () {})),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.filled, required this.onTap});

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: filled ? AppColors.tan : AppColors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label, style: TextStyle(color: filled ? AppColors.bgPrimary : AppColors.textPrimary)),
      ),
    );
  }
}

class _TrustAnalysis extends StatelessWidget {
  const _TrustAnalysis();

  @override
  Widget build(BuildContext context) {
    final items = ['Kaynak', 'Güncellik', 'Topluluk', 'Sapma'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Güven Analizi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(items[index]),
                const Text('A+', style: TextStyle(color: AppColors.success)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ContributorSpotlight extends StatelessWidget {
  const _ContributorSpotlight();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(backgroundColor: AppColors.tan, child: Text('Z')),
        title: Text('Zeynep K. tarafından eklendi'),
        subtitle: Text('Elite Contributor • 98% doğruluk'),
      ),
    );
  }
}

class _MiniChart extends StatelessWidget {
  const _MiniChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fiyat Trendi'),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              8,
              (index) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  height: 40 + (index % 4) * 20,
                  decoration: BoxDecoration(
                    color: AppColors.tan,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtherPlatforms extends StatelessWidget {
  const _OtherPlatforms();

  @override
  Widget build(BuildContext context) {
    final platforms = ['Hepsiburada • ₺1.349', 'Trendyol • ₺1.365', 'MediaMarkt • ₺1.399'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Diğer Platformlar', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        ...platforms.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(item),
          ),
        ),
      ],
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(color: AppColors.surfaceAlt),
      child: const _ActionButton(label: 'Hemen Satın Al / Takibe Ekle', filled: true, onTap: nullAction),
    );
  }
}

void nullAction() {}
