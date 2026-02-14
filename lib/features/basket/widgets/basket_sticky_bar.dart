import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../utils/theme.dart';

class BasketStickyBar extends StatelessWidget {
  final int itemCount;
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback? onPressed;

  const BasketStickyBar({
    super.key,
    required this.itemCount,
    required this.isLoading,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom: AppSpacing.sm,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 10),
            decoration: BoxDecoration(
              color: scheme.surface.withOpacity(0.72),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
            ),
            child: SafeArea(
              top: false,
              minimum: EdgeInsets.zero,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$itemCount ürün',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(126, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                    ),
                    onPressed: isEnabled && !isLoading ? onPressed : null,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: isLoading
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Hesapla',
                              key: ValueKey('label'),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
