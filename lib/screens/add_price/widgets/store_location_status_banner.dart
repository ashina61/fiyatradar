import 'dart:async';
import 'package:flutter/material.dart';
import '../../../utils/constants.dart';

class StoreLocationStatusBanner extends StatelessWidget {
  const StoreLocationStatusBanner({
    super.key,
    required this.isResolving,
    required this.locationPermissionDenied,
    required this.locationPermissionDeniedForever,
    required this.locationServiceDisabled,
    required this.locationUnavailable,
    required this.hasUserPosition,
    required this.onOpenLocationSettings,
    required this.onOpenAppSettings,
    required this.onRetry,
  });

  final bool isResolving;
  final bool locationPermissionDenied;
  final bool locationPermissionDeniedForever;
  final bool locationServiceDisabled;
  final bool locationUnavailable;
  final bool hasUserPosition;
  final FutureOr<void> Function() onOpenLocationSettings;
  final FutureOr<void> Function() onOpenAppSettings;
  final FutureOr<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (isResolving) {
      return _banner(
        color: scheme.primaryContainer.withOpacity(0.6),
        child: Row(children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
          ),
          const SizedBox(width: 8),
          Text('Konum alınıyor…', style: TextStyle(fontSize: 12, color: scheme.primary)),
        ]),
      );
    }

    if (locationServiceDisabled) {
      return _banner(
        color: scheme.errorContainer.withOpacity(0.55),
        child: Row(children: [
          Icon(Icons.location_disabled, size: 16, color: scheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Konum servisleri kapalı. Yakındaki mağazalar için servisleri açın.',
              style: TextStyle(fontSize: 12, color: scheme.error),
            ),
          ),
          TextButton(onPressed: () { onOpenLocationSettings(); }, child: const Text('Konum servislerini aç')),
        ]),
      );
    }

    if (locationPermissionDenied || locationPermissionDeniedForever) {
      final deniedText = locationPermissionDeniedForever
          ? 'Konum izni kalıcı reddedildi.'
          : 'Yakındaki mağazalar için konum izni gerekli.';

      return _banner(
        color: scheme.tertiaryContainer.withOpacity(0.6),
        child: Row(children: [
          Icon(Icons.location_off, size: 16, color: scheme.tertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              deniedText,
              style: TextStyle(fontSize: 12, color: scheme.onTertiaryContainer),
            ),
          ),
          TextButton(
            onPressed: () {
              if (locationPermissionDeniedForever) {
                onOpenAppSettings();
              } else {
                onRetry();
              }
            },
            child: const Text('Konumu Aç'),
          ),
        ]),
      );
    }

    if (locationUnavailable) {
      return _banner(
        color: scheme.surfaceVariant,
        child: Row(children: [
          Icon(Icons.my_location, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Konum alınamadı, mağazalar mesafesiz listeleniyor.',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
          TextButton(onPressed: () { onRetry(); }, child: const Text('Tekrar dene')),
        ]),
      );
    }

    if (hasUserPosition) {
      return _banner(
        color: scheme.primaryContainer.withOpacity(0.6),
        child: Row(children: [
          Icon(Icons.near_me, size: 14, color: scheme.primary),
          const SizedBox(width: 8),
          Text('Mesafeye göre sıralanıyor', style: TextStyle(fontSize: 12, color: scheme.primary)),
        ]),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _banner({required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: child,
    );
  }
}
