import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_radius.dart';

class AddPriceScreen extends StatelessWidget {
  const AddPriceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Fiyat Ekle', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ürün Seçimi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  Expanded(child: Text('Apple Watch SE 2. Nesil', style: const TextStyle(fontSize: 15, color: AppColors.textPrimary))),
                  Text('Değiştir', style: TextStyle(color: AppColors.tan, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // XP Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.success.withOpacity(0.3))),
              child: const Text('Bu fiyatı eklersen +24 XP ve +1 Trust kazanırsın.', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 24),

            // Fiyat Kaynağı
            const Text('Fiyat Kaynağı', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: 'Trendyol',
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  items: ['Trendyol', 'Hepsiburada', 'Amazon', 'N11'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(color: AppColors.textPrimary)))).toList(),
                  onChanged: (_) {},
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Fiyat
            const Text('Fiyat (₺)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Container(
              height: 100,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
              child: const TextField(style: TextStyle(fontSize: 20, color: AppColors.textPrimary), decoration: InputDecoration(border: InputBorder.none, hintText: '0,00', hintStyle: TextStyle(color: AppColors.textSubtle))),
            ),
            const SizedBox(height: 24),

            // Not
            const Text('Not', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
              child: const TextField(maxLines: 3, style: TextStyle(fontSize: 15, color: AppColors.textPrimary), decoration: InputDecoration(border: InputBorder.none, hintText: 'Opsiyonel notlar', hintStyle: TextStyle(color: AppColors.textSubtle))),
            ),
            const SizedBox(height: 16),

            // Doğrulama Kutusu
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.tan.withOpacity(0.5))),
              child: const Text('Doğrulama: URL veya ekran görüntüsü eklemek güven skorunu artırır.', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 16),

            // 4 Kutu Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _buildTrustBox('Kaynak Kalitesi +2'),
                _buildTrustBox('Hız +1'),
                _buildTrustBox('Tutarlılık +3'),
                _buildTrustBox('Topluluk +1'),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, AppColors.bgPrimary.withOpacity(0.95)]),
        ),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.tan, foregroundColor: AppColors.bgPrimary, minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)), elevation: 0),
          child: const Text('Fiyatı Gönder', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildTrustBox(String text) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
      child: Center(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
    );
  }
}
