// lib/screens/home/home_screen.dart
// GREENFIELD — warm editorial layout, no dark header island
// Rejected: full-width dark header, floating search overlap, horizontal carousel island
// UX goal: "Morning briefing" — what changed today, what am I tracking

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/price_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/fr_colors.dart';
import '../../utils/formatters.dart';

const _kPad = 24.0;
const _kCardR = 20.0;
const _kGap = 32.0;
const _kShadow = BoxShadow(color: Color(0x0A211510), blurRadius: 12, offset: Offset(0, 3));

// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userModelStreamProvider);
    final unread = ref.watch(unreadNotificationCountProvider);
    final trending = ref.watch(trendingProductsProvider);
    final latestPrices = ref.watch(latestPricesProvider);

    return Scaffold(
      backgroundColor: FRColors.backgroundWarm,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _TopBar(unread: unread)),
            SliverToBoxAdapter(
              child: userAsync.when(
                loading: () => const _GreetingShimmer(),
                error: (_, __) => const SizedBox.shrink(),
                data: (u) => _GreetingCard(user: u),
              ),
            ),
            const SliverToBoxAdapter(child: _SecLabel('BUGÜN NE DEĞİŞTİ')),
            SliverToBoxAdapter(
              child: _PricePulse(trending: trending, latest: latestPrices),
            ),
            const SliverToBoxAdapter(child: _SecLabel('SON KATKILAR')),
            SliverToBoxAdapter(
              child: _CommunityFeed(prices: latestPrices),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 130)),
          ],
        ),
      ),
    );
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.unread});
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kPad, 18, _kPad, 0),
      child: Row(
        children: [
          RichText(
            text: const TextSpan(children: [
              TextSpan(
                text: 'Fiyat',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: FRColors.espresso,
                ),
              ),
              TextSpan(
                text: 'Radar',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 21,
                  fontWeight: FontWeight.w400,
                  color: FRColors.tan,
                ),
              ),
            ]),
          ),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: FRColors.surface,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: FRColors.border),
                  boxShadow: const [_kShadow],
                ),
                child: const Icon(Icons.notifications_outlined, size: 20, color: FRColors.textPrimary),
              ),
              if (unread > 0)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      color: FRColors.espresso,
                      shape: BoxShape.circle,
                      border: Border.all(color: FRColors.backgroundWarm, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: FRColors.tan),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Greeting card ────────────────────────────────────────────────────────────
class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.user});
  final dynamic user;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Günaydın';
    if (h < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  @override
  Widget build(BuildContext context) {
    final name = (user?.username?.trim().isNotEmpty == true
            ? user!.username.trim()
            : user?.name?.trim() ?? '') as String;
    final points = (user?.totalPoints ?? 0) as int;
    final level = (user?.level ?? '') as String;
    final photoUrl = user?.photoUrl as String?;

    return Container(
      margin: const EdgeInsets.fromLTRB(_kPad, 22, _kPad, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: FRColors.espresso,
        borderRadius: BorderRadius.circular(_kCardR),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting${name.isNotEmpty ? ", $name" : ""}',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCompactCount(points),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: FRColors.tan,
                        height: 1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 6, bottom: 4),
                      child: Text(
                        'PT',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FRColors.tan),
                      ),
                    ),
                  ],
                ),
                if (level.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    level.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.4),
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          _Avatar(url: photoUrl, name: name, size: 56),
        ],
      ),
    );
  }
}

class _GreetingShimmer extends StatelessWidget {
  const _GreetingShimmer();
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(_kPad, 22, _kPad, 0),
        height: 120,
        decoration: BoxDecoration(
          color: FRColors.surface,
          borderRadius: BorderRadius.circular(_kCardR),
          border: Border.all(color: FRColors.border),
        ),
      );
}

// ─── Section label ────────────────────────────────────────────────────────────
class _SecLabel extends StatelessWidget {
  const _SecLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(_kPad, _kGap, _kPad, 14),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: FRColors.textMuted,
            letterSpacing: 1.5,
          ),
        ),
      );
}

// ─── Price pulse ──────────────────────────────────────────────────────────────
class _PricePulse extends StatelessWidget {
  const _PricePulse({required this.trending, required this.latest});
  final AsyncValue<List<ProductModel>> trending;
  final AsyncValue<List<PriceModel>> latest;

  @override
  Widget build(BuildContext context) {
    final products = trending.valueOrNull ?? [];
    if (products.isEmpty) {
      return SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: _kPad),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, __) => Container(
            width: 150,
            decoration: BoxDecoration(
              color: FRColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FRColors.border),
            ),
          ),
        ),
      );
    }

    final priceMap = <String, double>{};
    for (final p in latest.valueOrNull ?? []) {
      final pid = p.selectedProductId ?? p.productId;
      priceMap.putIfAbsent(pid, () => p.price);
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _kPad),
        physics: const BouncingScrollPhysics(),
        itemCount: products.length.clamp(0, 8),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final p = products[i];
          final price = priceMap[p.id] ?? p.lastPrice;
          return _PulseCard(product: p, price: price);
        },
      ),
    );
  }
}

class _PulseCard extends StatelessWidget {
  const _PulseCard({required this.product, required this.price});
  final ProductModel product;
  final double? price;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FRColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FRColors.border),
        boxShadow: const [_kShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _productThumb(product.effectiveImage),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: FRColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const Spacer(),
                if (price != null)
                  Text(
                    formatTRY(price!),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: FRColors.camelStrong,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productThumb(String? url) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _fallbackThumb(),
              )
            : _fallbackThumb(),
      );

  Widget _fallbackThumb() => Container(
        width: 42,
        height: 42,
        color: FRColors.backgroundWarm,
        child: const Icon(Icons.category_outlined, size: 18, color: FRColors.textSubtle),
      );
}

// ─── Community feed ───────────────────────────────────────────────────────────
class _CommunityFeed extends StatelessWidget {
  const _CommunityFeed({required this.prices});
  final AsyncValue<List<PriceModel>> prices;

  @override
  Widget build(BuildContext context) {
    final list = (prices.valueOrNull ?? []).take(10).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPad),
      child: list.isEmpty
          ? _emptyState()
          : Container(
              decoration: BoxDecoration(
                color: FRColors.surface,
                borderRadius: BorderRadius.circular(_kCardR),
                border: Border.all(color: FRColors.border),
                boxShadow: const [_kShadow],
              ),
              child: Column(
                children: [
                  for (var i = 0; i < list.length; i++) ...[
                    _FeedRow(price: list[i]),
                    if (i < list.length - 1)
                      const Divider(height: 1, indent: 62, endIndent: 16, color: Color(0x08211510)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _emptyState() => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: FRColors.surface,
          borderRadius: BorderRadius.circular(_kCardR),
          border: Border.all(color: FRColors.border),
        ),
        child: const Center(
          child: Text(
            'Henüz katkı yok.\nİlk fiyatı ekleyen sen ol!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: FRColors.textMuted, height: 1.5),
          ),
        ),
      );
}

class _FeedRow extends StatelessWidget {
  const _FeedRow({required this.price});
  final PriceModel price;

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'şimdi';
    if (d.inMinutes < 60) return '${d.inMinutes}dk önce';
    if (d.inHours < 24) return '${d.inHours}sa önce';
    return '${d.inDays}g önce';
  }

  @override
  Widget build(BuildContext context) {
    final reporter = price.addedByDisplayName ?? price.reporterName ?? 'Kullanıcı';
    final product = price.productName ?? 'Ürün';
    final store = price.storeName ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: FRColors.backgroundWarm,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                reporter.isNotEmpty ? reporter[0].toUpperCase() : 'K',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: FRColors.tan),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reporter,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: FRColors.textPrimary),
                      ),
                    ),
                    Text(_ago(price.reportedAt),
                        style: const TextStyle(fontSize: 11, color: FRColors.textSubtle)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  product,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: FRColors.textMuted),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      formatTRY(price.price),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: FRColors.espresso,
                      ),
                    ),
                    if (store.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: FRColors.backgroundWarm,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(store,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: FRColors.textMuted)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared avatar ────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name, required this.size});
  final String? url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 3),
        child: CachedNetworkImage(
          imageUrl: url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: FRColors.tan.withOpacity(0.18),
          borderRadius: BorderRadius.circular(size / 3),
          border: Border.all(color: FRColors.tan.withOpacity(0.35)),
        ),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: TextStyle(
              fontSize: size * 0.38,
              fontWeight: FontWeight.w800,
              color: FRColors.tan,
            ),
          ),
        ),
      );
}
