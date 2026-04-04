import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 8);
  }
}

class AppScaffoldShell extends StatelessWidget {
  const AppScaffoldShell({super.key, required this.body, this.bottomBar});
  final Widget body;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.gradientMain),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(child: body),
        bottomNavigationBar: bottomBar,
      ),
    );
  }
}

class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key, required this.title, this.trailing, this.onBack, this.showBack = false});
  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.lg, AppSpace.xl, AppSpace.md),
      child: Row(
        children: [
          if (showBack)
            InkWell(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: Container(
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: _surface(),
                child: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 14),
              ),
            ),
          if (showBack) const SizedBox(width: AppSpace.md),
          Expanded(child: Text(title, style: Theme.of(context).textTheme.headlineMedium)),
          trailing ?? const SizedBox.shrink(),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.lg),
        decoration: _surface(),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.tan, size: 16),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                value ?? hint,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: value == null ? AppColors.textSubtle : AppColors.textPrimary),
              ),
            ),
            const SignalChip(label: 'Canlı'),
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
    return GestureDetector(
      onTap: onTap,
      child: SurfaceCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.sm)),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpace.xs),
                  Text(meta, style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
            Text(price, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.goldFog)),
          ],
        ),
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpace.lg)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(padding: padding, decoration: _surface(), child: child);
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.icon, this.onTap});
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 14),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        backgroundColor: AppColors.tan,
        foregroundColor: AppColors.bgPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }
}

class SignalChip extends StatelessWidget {
  const SignalChip({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
        decoration: BoxDecoration(color: AppColors.success.withOpacity(0.18), borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.success)),
      );
}

class BadgeChip extends StatelessWidget {
  const BadgeChip({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
        decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.border)),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});
  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.xl, AppSpace.xl, AppSpace.md),
        child: Row(children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          if (action != null) Text(action!, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.goldFog)),
        ]),
      );
}

class PriceListRow extends StatelessWidget {
  const PriceListRow({super.key, required this.title, required this.subtitle, required this.price});
  final String title;
  final String subtitle;
  final String price;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpace.xs),
              Text(subtitle, style: Theme.of(context).textTheme.labelMedium),
            ]),
          ),
          Text(price, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.goldFog)),
        ]),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.detail});
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        child: Column(children: [
          const Icon(Icons.radar, color: AppColors.textSubtle),
          const SizedBox(height: AppSpace.md),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpace.sm),
          Text(detail, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ]),
      );
}

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.primaryLabel, required this.onPrimaryTap, this.secondaryLabel, this.onSecondaryTap});
  final String primaryLabel;
  final VoidCallback onPrimaryTap;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(color: AppColors.bgSecondary, border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.7)))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(label: primaryLabel, onTap: onPrimaryTap),
          if (secondaryLabel != null) ...[
            const SizedBox(height: AppSpace.sm),
            OutlinedButton(
              onPressed: onSecondaryTap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: Text(secondaryLabel!),
            ),
          ]
        ],
      ),
    );
  }
}

BoxDecoration _surface() => BoxDecoration(
      color: AppColors.surface.withOpacity(0.95),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.border.withOpacity(0.85)),
      boxShadow: AppElevation.card,
    );
