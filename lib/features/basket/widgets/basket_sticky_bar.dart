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
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.92),
              border: Border(top: BorderSide(color: AppColors.outline.withOpacity(0.8))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Toplam ürün: $itemCount',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                      onPressed: isEnabled && !isLoading ? onPressed : null,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: isLoading
                            ? const Row(
                                key: ValueKey('loading'),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: AppSpacing.sm),
                                  Text('Hesaplanıyor…'),
                                ],
                              )
                            : const Text(
                                'Hesapla',
                                key: ValueKey('label'),
                              ),
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
