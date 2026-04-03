import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_radius.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              const Text(
                'Adem 👋',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Arama Çubuğu
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.textSubtle, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Ürün, market veya kategori ara',
                        style: TextStyle(color: AppColors.textSubtle, fontSize: 15),
                      ),
                    ),
                    const Icon(Icons.qr_code_scanner_rounded, color: AppColors.textSubtle, size: 22),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Canlı Fiyatlar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.bolt_rounded, color: AppColors.tan, size: 20),
                      SizedBox(width: 8),
                      Text('Canlı Fiyatlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push('/search'),
                    child: const Text('Tümü', style: TextStyle(color: AppColors.tan, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              _buildFeedItem(context, 'Şampuan Pro', '2 dk önce • Trendyol', '₺189', Icons.water_drop_rounded, Colors.teal),
              _buildFeedItem(context, 'Kahve Çekirdeği', '5 dk önce • Hepsiburada', '₺329', Icons.coffee_rounded, Colors.orange),
              _buildFeedItem(context, 'Kablosuz Kulaklık', '9 dk önce • Amazon', '₺1.299', Icons.headphones_rounded, Colors.grey),

              const SizedBox(height: AppSpacing.xxl),

              // Seçkiler
              Row(
                children: const [
                  Icon(Icons.auto_awesome_rounded, color: AppColors.tan, size: 20),
                  SizedBox(width: 8),
                  Text('Seçkiler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              SizedBox(
                height: 140,
                child: Row(
                  children: [
                    _buildSelectionCard('Haftanın\nFırsatı', const [Color(0xFFB8956A), Color(0xFF8A6A4A)]),
                    const SizedBox(width: AppSpacing.md),
                    _buildSelectionCard('Doğrulanmış\nDüşüşler', const [Color(0xFF6B8A7A), Color(0xFF4A6B5A)]),
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
        padding: const EdgeInsets.only(bottom: 12),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/add-price'),
          backgroundColor: AppColors.tan,
          foregroundColor: AppColors.bgPrimary,
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
          label: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.w700)),
          icon: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  Widget _buildFeedItem(BuildContext context, String title, String meta, String price, IconData icon, Color iconColor) {
    return GestureDetector(
      onTap: () => context.push('/detail'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
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
              decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(meta, style: const TextStyle(fontSize: 12, color: AppColors.textSubtle)),
                ],
              ),
            ),
            Text(price, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.tan)),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard(String text, List<Color> colors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.white70, size: 24),
            Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
