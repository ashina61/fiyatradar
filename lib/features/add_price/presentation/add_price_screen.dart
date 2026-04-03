import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';

class AddPriceScreen extends StatelessWidget {
  const AddPriceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        bottomNavigationBar: Container(
          color: AppColors.surfaceAlt,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tan,
                  foregroundColor: AppColors.bgPrimary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                onPressed: () {},
                child: const Text('Fiyatı Gönder'),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fiyat Ekle', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.lg),
              const _ProductSummary(),
              const SizedBox(height: AppSpacing.md),
              const _MotivationBanner(),
              const SizedBox(height: AppSpacing.lg),
              const _FieldLabel('Fiyat Kaynağı'),
              const SizedBox(height: AppSpacing.sm),
              _Dropdown(),
              const SizedBox(height: AppSpacing.md),
              const _FieldLabel('Fiyat (₺)'),
              const SizedBox(height: AppSpacing.sm),
              const _PriceInput(),
              const SizedBox(height: AppSpacing.md),
              const _FieldLabel('Not'),
              const SizedBox(height: AppSpacing.sm),
              const _NoteInput(),
              const SizedBox(height: AppSpacing.md),
              const _ValidationBox(),
              const SizedBox(height: AppSpacing.lg),
              const _TrustImpactGrid(),
              const SizedBox(height: AppSpacing.xxl),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductSummary extends StatelessWidget {
  const _ProductSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: CachedNetworkImage(
              imageUrl: 'https://images.unsplash.com/photo-1585386959984-a41552231658?w=300',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(child: Text('Apple Watch SE 2. Nesil')),
          TextButton(onPressed: () {}, child: const Text('Değiştir')),
        ],
      ),
    );
  }
}

class _MotivationBanner extends StatelessWidget {
  const _MotivationBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Text('Bu fiyatı eklersen +24 XP ve +1 Trust kazanırsın.', style: TextStyle(color: AppColors.bgPrimary)),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(fontWeight: FontWeight.w600));
  }
}

class _Dropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: 'Trendyol',
      items: ['Trendyol', 'Hepsiburada', 'Amazon']
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (_) {},
      decoration: const InputDecoration(),
    );
  }
}

class _PriceInput extends StatelessWidget {
  const _PriceInput();

  @override
  Widget build(BuildContext context) {
    return const TextField(
      keyboardType: TextInputType.number,
      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
      decoration: InputDecoration(prefixText: '₺ '),
    );
  }
}

class _NoteInput extends StatelessWidget {
  const _NoteInput();

  @override
  Widget build(BuildContext context) {
    return const TextField(
      maxLines: 3,
      decoration: InputDecoration(hintText: 'Opsiyonel notlar'),
    );
  }
}

class _ValidationBox extends StatelessWidget {
  const _ValidationBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning),
      ),
      child: const Text('Doğrulama: URL veya ekran görüntüsü eklemek güven skorunu artırır.'),
    );
  }
}

class _TrustImpactGrid extends StatelessWidget {
  const _TrustImpactGrid();

  @override
  Widget build(BuildContext context) {
    final cells = ['Kaynak Kalitesi +2', 'Hız +1', 'Tutarlılık +3', 'Topluluk +1'];
    return GridView.builder(
      itemCount: cells.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 2.3,
      ),
      itemBuilder: (_, index) => Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(cells[index]),
      ),
    );
  }
}
