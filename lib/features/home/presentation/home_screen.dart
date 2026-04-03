import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String userName = 'Fatih';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Merhaba,',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              Text(
                '$userName 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded, color: AppColors.textSubtle, size: 22),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Ürün, market veya kategori ara',
                        style: TextStyle(color: AppColors.textSubtle, fontSize: 15),
                      ),
                    ),
                    Icon(Icons.qr_code_scanner_rounded, color: AppColors.textSubtle, size: 22),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: AppColors.tan, size: 20),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        'Canlı Fiyatlar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push('/search'),
                    child: const Text(
                      'Tümü',
                      style: TextStyle(
                        color: AppColors.tan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildFeedItem(
                context,
                'Şampuan Pro',
                '2 dk önce • Trendyol',
                '₺189',
                Icons.water_drop_rounded,
                AppColors.itemTeal,
              ),
              _buildFeedItem(
                context,
                'Kahve Çekirdeği',
                '5 dk önce • Hepsiburada',
                '₺329',
                Icons.coffee_rounded,
                AppColors.itemOrange,
              ),
              _buildFeedItem(
                context,
                'Kablosuz Kulaklık',
                '9 dk önce • Amazon',
                '₺1.299',
                Icons.headphones_rounded,
                AppColors.itemGray,
              ),
              const SizedBox(height: AppSpacing.xxl),
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: AppColors.tan, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Seçkiler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 140,
                child: Row(
                  children: const [
                    _SelectionCard(
                      title: 'Haftanın\nFırsatı',
                      colors: [AppColors.gradientGoldStart, AppColors.gradientGoldEnd],
                    ),
                    SizedBox(width: AppSpacing.md),
                    _SelectionCard(
                      title: 'Doğrulanmış\nDüşüşler',
                      colors: [AppColors.gradientGreenStart, AppColors.gradientGreenEnd],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/add-price'),
          backgroundColor: AppColors.tan,
          foregroundColor: AppColors.bgPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          label: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.w700)),
          icon: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  Widget _buildFeedItem(
    BuildContext context,
    String title,
    String meta,
    String price,
    IconData icon,
    Color iconColor,
  ) {
    return GestureDetector(
      onTap: () => context.push('/detail'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg - 2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: AppSpacing.lg - 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    meta,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.tan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({required this.title, required this.colors});

  final String title;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: AppColors.textPrimary, size: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
