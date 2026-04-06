// lib/screens/home/home_screen.dart
// GREENFIELD v2 — "The Pulse"
// Rejected from the previous iteration: warm dark header chrome, greeting card hero,
// editorial section labels, brown rounded cards, carousel ticker.
// UX goal: in 2 seconds communicate the state of the market today.
// Composition: masthead date → display stat → thin ticker list → quiet contribute row.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/price_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/fr_ink.dart';
import '../../utils/formatters.dart';
import '../add_price/add_price_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userModelStreamProvider).valueOrNull;
    final unread = ref.watch(unreadNotificationCountProvider);
    final prices = ref.watch(latestPricesProvider).valueOrNull ?? const <PriceModel>[];

    return Scaffold(
      backgroundColor: FRInk.paper,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Masthead(unread: unread)),
            const SliverToBoxAdapter(child: _DateBlock()),
            SliverToBoxAdapter(child: _PulseStat(count: prices.length, userFirstName: user?.firstName)),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            const SliverToBoxAdapter(child: _SectionLabel('PİYASA HAREKETİ')),
            SliverToBoxAdapter(
              child: prices.isEmpty
                  ? const _EmptyTicker()
                  : _Ticker(prices: prices),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 36)),
            const SliverToBoxAdapter(child: _SectionLabel('KATKI')),
            const SliverToBoxAdapter(child: _ContributeRow()),
            const SliverToBoxAdapter(child: SizedBox(height: 160)),
          ],
        ),
      ),
    );
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead({required this.unread});
  final AsyncValue<int> unread;

  @override
  Widget build(BuildContext context) {
    final count = unread.valueOrNull ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 18, FRInk.gutter, 0),
      child: Row(
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: FRType.family,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: FRInk.ink,
                letterSpacing: -0.3,
              ),
              children: [
                TextSpan(text: 'fiyat'),
                TextSpan(text: 'radar', style: TextStyle(fontWeight: FontWeight.w300)),
                TextSpan(text: '.', style: TextStyle(color: FRInk.saffron, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const Spacer(),
          _IconStub(icon: Icons.notifications_none_rounded, badge: count),
        ],
      ),
    );
  }
}

class _IconStub extends StatelessWidget {
  const _IconStub({required this.icon, this.badge = 0});
  final IconData icon;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40, height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 24, color: FRInk.ink),
          if (badge > 0)
            Positioned(
              top: 6, right: 6,
              child: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: FRInk.saffron, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

class _DateBlock extends StatelessWidget {
  const _DateBlock();
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];
    const weekdays = ['Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi','Pazar'];
    final date = '${now.day.toString().padLeft(2,'0')} ${months[now.month-1]}';
    final weekday = weekdays[now.weekday - 1];
    return Padding(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 34, FRInk.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(weekday.toUpperCase(), style: FRType.micro),
          const SizedBox(height: 6),
          Text(date, style: FRType.title),
        ],
      ),
    );
  }
}

class _PulseStat extends StatelessWidget {
  const _PulseStat({required this.count, this.userFirstName});
  final int count;
  final String? userFirstName;

  @override
  Widget build(BuildContext context) {
    final name = (userFirstName ?? '').trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 22, FRInk.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: FRType.display,
              children: [
                TextSpan(text: '$count'),
                const TextSpan(text: '\n'),
                TextSpan(
                  text: 'fiyat güncellendi',
                  style: FRType.display.copyWith(color: FRInk.inkSoft, fontWeight: FontWeight.w300),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name.isNotEmpty
                ? 'İyi günler, $name — topluluk bu sabah aktif.'
                : 'Topluluk bu sabah aktif. Fiyatlar saniye saniye güncelleniyor.',
            style: FRType.body,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(FRInk.gutter, 0, FRInk.gutter, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: FRType.micro),
          const SizedBox(height: 10),
          const FRHairline(),
        ],
      ),
    );
  }
}

class _Ticker extends StatelessWidget {
  const _Ticker({required this.prices});
  final List<PriceModel> prices;

  @override
  Widget build(BuildContext context) {
    final rows = prices.take(8).toList();
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          _TickerRow(price: rows[i], index: i),
          if (i != rows.length - 1) const FRHairline(indent: FRInk.gutter),
        ],
      ],
    );
  }
}

class _TickerRow extends StatelessWidget {
  const _TickerRow({required this.price, required this.index});
  final PriceModel price;
  final int index;

  @override
  Widget build(BuildContext context) {
    final delta = price.score;
    final isFall = delta <= 0;
    final deltaLabel = delta == 0 ? '·' : (isFall ? '▼' : '▲');
    final deltaColor = delta == 0
        ? FRInk.inkMute
        : (isFall ? FRInk.fall : FRInk.rise);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter, vertical: FRInk.rowV),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text((index + 1).toString().padLeft(2, '0'), style: FRType.micro),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (price.productName ?? 'Ürün').trim(),
                  style: FRType.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  (price.storeName ?? 'Market').trim(),
                  style: FRType.body.copyWith(color: FRInk.inkMute, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatTRY(price.price), style: FRType.numeral),
              const SizedBox(height: 3),
              Text(
                deltaLabel,
                style: TextStyle(
                  fontFamily: FRType.family,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: deltaColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTicker extends StatelessWidget {
  const _EmptyTicker();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: FRInk.gutter, vertical: 40),
      child: Text(
        'Henüz bugün için hareket yok. İlk fiyatı sen ekle.',
        style: FRType.body,
      ),
    );
  }
}

class _ContributeRow extends StatelessWidget {
  const _ContributeRow();
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddPriceScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FRInk.gutter, vertical: 22),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fiyat bildir', style: FRType.subtitle),
                  SizedBox(height: 4),
                  Text('Yaklaşık 20 saniye — topluluk için.', style: FRType.body),
                ],
              ),
            ),
            Container(
              width: 48, height: 48,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: FRInk.ink, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_outward_rounded, color: FRInk.paper, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
