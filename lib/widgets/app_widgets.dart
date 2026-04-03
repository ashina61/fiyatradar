import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../core/theme/app_colors.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 44,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('9:41', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            FaIcon(FontAwesomeIcons.batteryFull, size: 14, color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }
}

class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key, required this.title, this.trailing, this.onBack});
  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          InkWell(onTap: onBack ?? () => Navigator.of(context).maybePop(), child: const FaIcon(FontAwesomeIcons.arrowLeft, color: AppColors.textPrimary, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
          trailing ?? const SizedBox(width: 18),
        ],
      ),
    );
  }
}

class SearchInputField extends StatelessWidget {
  const SearchInputField({super.key, required this.hint, this.value, this.onTap});
  final String hint;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppColors.radiusXl),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const FaIcon(FontAwesomeIcons.magnifyingGlass, color: AppColors.tan, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value ?? hint, style: TextStyle(fontSize: 15, color: value == null ? AppColors.textSecondary : AppColors.textPrimary)),
            ),
            const FaIcon(FontAwesomeIcons.qrcode, color: AppColors.textSubtle, size: 16),
          ],
        ),
      ),
    );
  }
}

class LiveFeedItem extends StatelessWidget {
  const LiveFeedItem({super.key, required this.emoji, required this.name, required this.meta, required this.price, this.onTap});
  final String emoji;
  final String name;
  final String meta;
  final String price;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppColors.radiusMd)),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(meta, style: const TextStyle(fontSize: 10, color: AppColors.textSubtle)),
          ])),
          Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.tan)),
        ]),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.icon, this.onTap});
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.tan, borderRadius: BorderRadius.circular(AppColors.radiusLg)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              FaIcon(icon!, size: 14, color: AppColors.bgPrimary),
              const SizedBox(width: 8),
            ],
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.bgPrimary)),
          ],
        ),
      ),
    );
  }
}
