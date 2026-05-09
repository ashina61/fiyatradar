import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../ui/tokens.dart';

class ProfileAvatarImage extends StatefulWidget {
  const ProfileAvatarImage({
    super.key,
    required this.imageUrl,
    required this.displayName,
    required this.size,
    required this.radius,
    required this.initialStyle,
    this.cacheWidth,
    this.fallbackColor,
    this.onImageError,
  });

  final String? imageUrl;
  final String displayName;
  final double size;
  final double radius;
  final TextStyle initialStyle;
  final int? cacheWidth;
  final Color? fallbackColor;
  final ValueChanged<String>? onImageError;

  @override
  State<ProfileAvatarImage> createState() => _ProfileAvatarImageState();
}

class _ProfileAvatarImageState extends State<ProfileAvatarImage> {
  ImageProvider? _provider;
  String? _precacheKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncProvider();
  }

  @override
  void didUpdateWidget(covariant ProfileAvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.cacheWidth != widget.cacheWidth) {
      _syncProvider();
    }
  }

  void _syncProvider() {
    final url = widget.imageUrl?.trim();
    if (url == null || url.isEmpty) {
      _provider = null;
      _precacheKey = null;
      return;
    }
    final provider = CachedNetworkImageProvider(
      url,
      maxWidth: widget.cacheWidth,
    );
    _provider = provider;
    final precacheKey = '$url|${widget.cacheWidth ?? 0}';
    if (_precacheKey == precacheKey) return;
    _precacheKey = precacheKey;
    precacheImage(provider, context).catchError((Object _) {
      widget.onImageError?.call(url);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider;
    final fallback = _AvatarFallback(
      displayName: widget.displayName,
      style: widget.initialStyle,
      color: widget.fallbackColor,
    );

    return SizedBox.square(
      dimension: widget.size,
      child: ClipRRect(
        borderRadius: FRRad.all(widget.radius),
        child: provider == null
            ? fallback
            : Stack(
                fit: StackFit.expand,
                children: [
                  fallback,
                  Image(
                    key: ValueKey(widget.imageUrl),
                    image: provider,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                    frameBuilder: (context, child, frame, wasSyncLoaded) {
                      if (wasSyncLoaded) return child;
                      return AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: child,
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      final url = widget.imageUrl?.trim();
                      if (url != null && url.isNotEmpty) {
                        widget.onImageError?.call(url);
                      }
                      return fallback;
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.displayName,
    required this.style,
    this.color,
  });

  final String displayName;
  final TextStyle style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final trimmed = displayName.trim();
    final initial = trimmed.isEmpty ? 'F' : trimmed[0].toUpperCase();
    return ColoredBox(
      color: color ?? Colors.transparent,
      child: Center(child: Text(initial, style: style)),
    );
  }
}
