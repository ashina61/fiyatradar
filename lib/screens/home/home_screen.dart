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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(FRInk.gutter, 12, FRInk.gutter, 140),
          children: [
            _TopBar(unread: unread),
            const SizedBox(height: 16),
            _HeroCard(userName: user?.firstName, priceCount: prices.length),
            const SizedBox(height: 20),
            const _SectionLabel('PİYASA ÖZETİ'),
            const SizedBox(height: 8),
            _MarketFlowCard(prices: prices),
            const SizedBox(height: 20),
            const _SectionLabel('HIZLI AKSİYON'),
            const SizedBox(height: 8),
            _AddPriceCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddPriceScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.unread});
  final int unread;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Ana Sayfa',
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: FRInk.ink),
        ),
        const Spacer(),
        Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: FRInk.paperSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.notifications_none_rounded, color: FRInk.ink),
            ),
            if (unread > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: FRInk.gold, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.userName, required this.priceCount});
  final String? userName;
  final int priceCount;

  @override
  Widget build(BuildContext context) {
    final name = (userName ?? '').trim();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FRInk.dark,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: FRInk.goldSoft, borderRadius: BorderRadius.circular(999)),
                child: const Text('GÜNÜN NABZI', style: TextStyle(color: FRInk.dark, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              const Spacer(),
              Text(_todayText(), style: const TextStyle(color: FRInk.goldSoft, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$priceCount fiyat güncellemesi',
            style: const TextStyle(fontSize: 34, height: 1.05, fontWeight: FontWeight.w800, color: FRInk.paperSoft),
          ),
          const SizedBox(height: 6),
          Text(
            name.isNotEmpty
                ? '$name, radarın bugün güçlü. Topluluk verisi canlı akıyor.'
                : 'Topluluk verisi canlı akıyor. Kritik ürünlerde hareket yüksek.',
            style: const TextStyle(fontSize: 15, color: FRInk.goldSoft, height: 1.4),
          ),
        ],
      ),
    );
  }

  String _todayText() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
  }
}

class _MarketFlowCard extends StatelessWidget {
  const _MarketFlowCard({required this.prices});
  final List<PriceModel> prices;

  @override
  Widget build(BuildContext context) {
    if (prices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: FRInk.paperSoft, borderRadius: BorderRadius.circular(24)),
        child: const Text('Henüz güncel fiyat yok. İlk katkıyı sen yap.', style: FRType.body),
      );
    }

    return Container(
      decoration: BoxDecoration(color: FRInk.paperSoft, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          for (var i = 0; i < prices.take(6).length; i++) ...[
            _PriceRow(index: i, price: prices[i]),
            if (i != prices.take(6).length - 1)
              const Divider(height: 1, indent: 18, endIndent: 18, color: FRInk.hairline),
          ],
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.index, required this.price});
  final int index;
  final PriceModel price;

  @override
  Widget build(BuildContext context) {
    final delta = price.score;
    final isFall = delta <= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Text('${index + 1}'.padLeft(2, '0'), style: FRType.micro),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((price.productName ?? 'Ürün').trim(), style: FRType.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text((price.storeName ?? 'Market').trim(), style: FRType.body.copyWith(color: FRInk.inkMute, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: delta == 0 ? FRInk.paperDeep : (isFall ? FRInk.fallWash : FRInk.riseWash),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              delta == 0 ? '•' : (isFall ? '▼' : '▲'),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: delta == 0 ? FRInk.inkMute : (isFall ? FRInk.fall : FRInk.rise),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(formatTRY(price.price), style: FRType.numeral),
        ],
      ),
    );
  }
}

class _AddPriceCard extends StatelessWidget {
  const _AddPriceCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: FRInk.paperSoft,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fiyat Bildir', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('20 saniyede katkı ver, topluluk verisini güçlendir.', style: TextStyle(color: FRInk.inkMute)),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: FRInk.dark, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_rounded, color: FRInk.paperSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.value);
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(fontSize: 12, letterSpacing: 2.1, fontWeight: FontWeight.w700, color: FRInk.inkMute),
    );
  }
}
