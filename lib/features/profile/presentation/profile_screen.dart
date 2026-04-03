import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = ['Bildirimler', 'Konum', 'Karanlık Mod', 'Hakkında', 'Gizlilik'];
    final links = ['FAQ', 'Güncelleme Geçmişi', 'Admin Linkleri'];

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const CircleAvatar(radius: 42, backgroundColor: AppColors.tan, child: Text('FK', style: TextStyle(color: AppColors.bgPrimary))),
              const SizedBox(height: AppSpacing.sm),
              const Text('Fatih Kaya', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.xs),
              const Chip(label: Text('Level 18 • Elite'), backgroundColor: AppColors.surfaceAlt),
              const SizedBox(height: AppSpacing.lg),
              const _StatsRow(),
              const SizedBox(height: AppSpacing.lg),
              const _XpProgress(),
              const SizedBox(height: AppSpacing.lg),
              ...settings.map((item) => _ListTileItem(label: item)),
              const SizedBox(height: AppSpacing.md),
              ...links.map((item) => _ListTileItem(label: item)),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Center(child: Text('Çıkış Yap', style: TextStyle(color: AppColors.bgPrimary, fontWeight: FontWeight.w700))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _StatCard(label: 'Fiyat', value: '482')),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: _StatCard(label: 'Doğrulama', value: '137')),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: _StatCard(label: 'Yorum', value: '96')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _XpProgress extends StatelessWidget {
  const _XpProgress();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('XP Progress'),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: const LinearProgressIndicator(
              value: 0.74,
              minHeight: AppSpacing.sm,
              backgroundColor: AppColors.surfaceAlt,
              color: AppColors.tan,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListTileItem extends StatelessWidget {
  const _ListTileItem({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        title: Text(label),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
