import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../utils/theme.dart';

class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final String cacheKey;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    required this.cacheKey,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.md);

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _ImageFallback(width: width, height: height, borderRadius: radius);
    }

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        cacheKey: '${cacheKey}_${imageUrl.hashCode}',
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 180),
        filterQuality: FilterQuality.high,
        placeholder: (_, __) => _ImageSkeleton(width: width, height: height),
        errorWidget: (_, __, ___) =>
            _ImageFallback(width: width, height: height, borderRadius: radius),
      ),
    );
  }
}

class _ImageSkeleton extends StatelessWidget {
  final double? width;
  final double? height;

  const _ImageSkeleton({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceVariant,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const _ImageFallback({
    this.width,
    this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: Theme.of(context).colorScheme.outline,
            size: 24,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Görsel yok',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
