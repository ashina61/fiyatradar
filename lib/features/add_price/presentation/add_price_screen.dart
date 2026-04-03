import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';

class AddPriceScreen extends StatelessWidget {
  const AddPriceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Fiyat Ekle',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              _ProductSummary(),
              SizedBox(height: AppSpacing.md),
              _XpBanner(),
              SizedBox(height: AppSpacing.lg),
              _FieldLabel('Fiyat Kaynağı'),
              SizedBox(height: AppSpacing.sm),
              _SourceDropdown(),
              SizedBox(height: AppSpacing.md),
              _FieldLabel('Fiyat (₺)'),
              SizedBox(height: AppSpacing.sm),
              _PriceInput(),
              SizedBox(height: AppSpacing.md),
              _FieldLabel('Not'),
              SizedBox(height: AppSpacing.sm),
              _NoteInput(),
              SizedBox(height: AppSpacing.md),
              _ValidationBox(),
              SizedBox(height: AppSpacing.lg),
              _ScoreGrid(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tan,
                foregroundColor: AppColors.bgPrimary,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              onPressed: () {},
              child: const Text(
                'Fiyatı Gönder',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
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
            child: const Icon(
              Icons.watch_rounded,
              color: AppColors.tan,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Text(
              'Apple Watch SE 2. Nesil',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Değiştir',
              style: TextStyle(
                color: AppColors.tan,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _XpBanner extends StatelessWidget {
  const _XpBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bannerPositive,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Text(
        'Bu fiyatı eklersen +24 XP ve +1 Trust kazanırsın.',
        style: TextStyle(
          color: AppColors.bgPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SourceDropdown extends StatefulWidget {
  const _SourceDropdown();

  @override
  State<_SourceDropdown> createState() => _SourceDropdownState();
}

class _SourceDropdownState extends State<_SourceDropdown> {
  String source = 'Trendyol';

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: source,
      dropdownColor: AppColors.surface,
      iconEnabledColor: AppColors.textSecondary,
      style: const TextStyle(color: AppColors.textPrimary),
      items: ['Trendyol', 'Hepsiburada', 'Amazon']
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (value) => setState(() => source = value ?? source),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.tan),
        ),
      ),
    );
  }
}

class _PriceInput extends StatelessWidget {
  const _PriceInput();

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        prefixText: '₺ ',
        prefixStyle: const TextStyle(
          color: AppColors.tan,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        hintText: '0,00',
        hintStyle: const TextStyle(color: AppColors.textSubtle),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.tan),
        ),
      ),
    );
  }
}

class _NoteInput extends StatelessWidget {
  const _NoteInput();

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: 3,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Opsiyonel notlar',
        hintStyle: const TextStyle(color: AppColors.textSubtle),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.tan),
        ),
      ),
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
      child: const Text(
        'Doğrulama: URL veya ekran görüntüsü eklemek güven skorunu artırır.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

class _ScoreGrid extends StatelessWidget {
  const _ScoreGrid();

  @override
  Widget build(BuildContext context) {
    const cells = [
      'Kaynak Kalitesi +2',
      'Hız +1',
      'Tutarlılık +3',
      'Topluluk +1',
    ];

    return GridView.builder(
      itemCount: cells.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 2.4,
      ),
      itemBuilder: (_, index) {
        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            cells[index],
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
