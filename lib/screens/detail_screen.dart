import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/theme/app_colors.dart';
import '../widgets/app_widgets.dart';
import 'add_price_screen.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(children: [
        const StatusBar(),
        const AppTopBar(title: ''),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              Container(
                height: 160,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppColors.radiusXl),
                ),
                child: const Text('🎧', style: TextStyle(fontSize: 72)),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('Sony WH-1000XM5', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.surfaceAlt, AppColors.surface]),
                  border: Border.all(color: const Color.fromRGBO(196, 165, 123, 0.25)),
                  borderRadius: BorderRadius.circular(AppColors.radiusXl),
                ),
                child: const Text('₺1.299', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Fiyat Ekle',
                icon: FontAwesomeIcons.plus,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPriceScreen())),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
