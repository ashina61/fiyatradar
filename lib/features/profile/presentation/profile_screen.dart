import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_radius.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: AppColors.tan.withOpacity(0.3), shape: BoxShape.circle, border: Border.all(color: AppColors.tan, width: 2)),
                child: const Center(child: Text('FK', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.tan))),
              ),
              const SizedBox(height: 16),

              // İsim
              const Text('Fatih Kaya', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),

              // Level Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(border: Border.all(color: AppColors.textSecondary), borderRadius: BorderRadius.circular(AppRadius.md)),
                child: const Text('Level 18 • Elite', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 24),

              // İstatistikler
              Row(
                children: [
                  _buildStatBox('482', 'Fiyat'),
                  const SizedBox(width: 12),
                  _buildStatBox('137', 'Doğrulama'),
                  const SizedBox(width: 12),
                  _buildStatBox('96', 'Yorum'),
                ],
              ),
              const SizedBox(height: 24),

              // XP Progress
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('XP Progress', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    Container(height: 6, decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.full)), child: Row(children: [Container(width: 200, height: 6, decoration: BoxDecoration(color: AppColors.tan, borderRadius: BorderRadius.circular(AppRadius.full)))])),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Ayar Listesi
              _buildSettingItem('Bildirimler'),
              _buildSettingItem('Konum'),
              _buildSettingItem('Karanlık Mod'),
              _buildSettingItem('Hakkında'),
              _buildSettingItem('Gizlilik'),
              _buildSettingItem('FAQ'),
              _buildSettingItem('Güncelleme Geçmişi'),
              _buildSettingItem('Admin Linkleri'),
              const SizedBox(height: 24),

              // Çıkış Butonu
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFD48A8A), borderRadius: BorderRadius.circular(AppRadius.lg)),
                child: const Center(child: Text('Çıkış Yap', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSubtle)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSubtle, size: 20),
        ],
      ),
    );
  }
}
