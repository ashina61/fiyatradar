import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import '../ui/components.dart';
import '../ui/tokens.dart';
import 'main_screen.dart';
import 'profile_screens.dart';

/// In-app blog-style page rendered from a banner's `contentBlocks`.
/// The page is a thin reader: heading / paragraph / image blocks stack
/// vertically and the optional CTA at the bottom triggers the same route
/// the banner would otherwise jump to directly.
class BannerPageScreen extends StatelessWidget {
  const BannerPageScreen({super.key, required this.banner});
  final AppBanner banner;

  @override
  Widget build(BuildContext context) {
    final blocks = banner.contentBlocks;
    final state = AppStateScope.of(context);
    final ctaRoute = _ctaRouteFor(banner);

    return Scaffold(
      backgroundColor: FR.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, frBottomScrollPadding(context)),
          children: [
            Row(
              children: [
                FRIconChip(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (banner.hasImage)
              ClipRRect(
                borderRadius: FRRad.all(24),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    banner.imageUrl!,
                    fit: BoxFit.cover,
                    cacheWidth: 1200,
                    cacheHeight: 675,
                    filterQuality: FilterQuality.medium,
                    frameBuilder: frFadeFrameBuilder,
                    errorBuilder: (_, __, ___) => Container(
                      color: FR.surfaceHi,
                      child: Icon(Icons.image_outlined, color: FR.ink3, size: 36),
                    ),
                  ),
                ),
              ),
            if (banner.hasImage) const SizedBox(height: 18),
            Text('FİYATRADAR · YAYIN',
                style: frOverline(color: FR.gold, size: 10)),
            const SizedBox(height: 10),
            Text(
              banner.title.replaceAll('\n', ' '),
              style: frDisplay(30, FontWeight.w700, height: 1.15),
            ),
            if (banner.subtitle.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                banner.subtitle,
                style: frText(14, FontWeight.w600, color: FR.ink3, height: 1.5),
              ),
            ],
            const SizedBox(height: 22),
            if (blocks.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: frSurface(radius: FRRad.l),
                child: Text(
                  'Henüz içerik eklenmemiş. Banner aksiyonunu kullanmak için aşağıdaki butona dokun.',
                  style: frText(13, FontWeight.w600, color: FR.ink3, height: 1.55),
                ),
              )
            else
              for (final block in blocks) ...[
                _BlockView(block: block),
                const SizedBox(height: 14),
              ],
            const SizedBox(height: 14),
            if (ctaRoute != null)
              FRCta(
                label: banner.actionLabel.isEmpty
                    ? 'Devam et'
                    : banner.actionLabel,
                icon: Icons.arrow_forward_rounded,
                onTap: () => runBannerRoute(context, state, ctaRoute),
              ),
          ],
        ),
      ),
    );
  }

  String? _ctaRouteFor(AppBanner b) {
    if (b.actionType == 'route' && b.actionTarget.trim().isNotEmpty) {
      return b.actionTarget.trim();
    }
    return null;
  }
}

class _BlockView extends StatelessWidget {
  const _BlockView({required this.block});
  final BannerContentBlock block;

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case 'heading':
        return Text(
          block.value,
          style: frDisplay(20, FontWeight.w700, height: 1.25),
        );
      case 'image':
        if (block.value.trim().isEmpty) return const SizedBox.shrink();
        return ClipRRect(
          borderRadius: FRRad.all(20),
          child: Image.network(
            block.value,
            fit: BoxFit.cover,
            cacheWidth: 1200,
            cacheHeight: 1200,
            filterQuality: FilterQuality.medium,
            frameBuilder: frFadeFrameBuilder,
            errorBuilder: (_, __, ___) => Container(
              height: 180,
              alignment: Alignment.center,
              color: FR.surfaceHi,
              child: Icon(Icons.broken_image_outlined,
                  color: FR.ink3, size: 28),
            ),
          ),
        );
      case 'text':
      default:
        return Text(
          block.value,
          style: frText(14, FontWeight.w600, color: FR.ink2, height: 1.55),
        );
    }
  }
}

/// Resolves a banner action and navigates accordingly. Routes are kept
/// short so they're easy to write in the admin form.
///
/// Supported routes:
/// - `home` · `explore` · `add` · `basket` · `profile` (main tabs)
/// - `cheapest` (Keşfet → ucuzlayanlar)
/// - `newest` (Keşfet → yeni)
/// - `favorites` (Profil → favoriler)
/// - `category:<name>` (Keşfet, kategori filtresi açık)
/// - `https://…` (harici link → tarayıcı yerine in-app webview yok, sadece bilgi göster)
void runBannerRoute(BuildContext context, AppState state, String route) {
  final lower = route.trim().toLowerCase();
  if (lower.isEmpty) return;
  if (lower == 'home') {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)),
    );
    return;
  }
  if (lower == 'explore' || lower == 'cheapest' || lower == 'newest' ||
      lower.startsWith('category:')) {
    if (lower == 'cheapest') {
      state.setExplorePresetFilter(1);
    } else if (lower == 'newest') {
      state.setExplorePresetFilter(2);
    } else if (lower.startsWith('category:')) {
      state.setExplorePresetCategory(route.substring(route.indexOf(':') + 1));
    } else {
      state.setExplorePresetFilter(0);
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
    );
    return;
  }
  if (lower == 'add' || lower == 'addprice') {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
    );
    return;
  }
  if (lower == 'basket' || lower == 'cart' || lower == 'compare') {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 3)),
    );
    return;
  }
  if (lower == 'profile') {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 4)),
    );
    return;
  }
  if (lower == 'favorites') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
    );
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Bu yönlendirme tanınmadı: $route')),
  );
}
