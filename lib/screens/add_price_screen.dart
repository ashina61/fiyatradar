import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/theme/app_colors.dart';
import '../widgets/app_widgets.dart';

class AddPriceScreen extends StatelessWidget {
  const AddPriceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const StatusBar(),
      const AppTopBar(title: 'Fiyat Bildir'),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color.fromRGBO(196, 165, 123, 0.06), Color.fromRGBO(196, 165, 123, 0.02)]),
                borderRadius: BorderRadius.circular(AppColors.radiusLg),
                border: Border.all(color: const Color.fromRGBO(196, 165, 123, 0.25)),
              ),
              child: const Text("Level 13'e 25 XP kaldı", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            const _Field(label: 'Fiyat Kaynağı *', value: 'Platform seçin...'),
            const _Field(label: 'Fiyat *', value: '₺ 1.299'),
            PrimaryButton(label: 'Fiyatı Gönder', icon: FontAwesomeIcons.paperPlane, onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    ]);
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppColors.radiusLg), border: Border.all(color: AppColors.border)),
          child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
        ),
      ]),
    );
  }
}
