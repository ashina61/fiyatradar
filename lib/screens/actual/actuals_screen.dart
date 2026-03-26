import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/actual_item_model.dart';
import '../../models/actual_model.dart';
import '../../providers/actual_provider.dart';

class ActualsScreen extends ConsumerStatefulWidget {
  const ActualsScreen({super.key});

  @override
  ConsumerState<ActualsScreen> createState() => _ActualsScreenState();
}

class _ActualsScreenState extends ConsumerState<ActualsScreen> {
  String? _selectedMarketId;
  String? _selectedActualId;

  static const _bg = Color(0xFFEDEAE3);
  static const _dk = Color(0xFF18100A);
  static const _whiteCard = Color(0xFFFAFAF8);
  static const _gold = Color(0xFFBF9470);
  static const _goldLight = Color(0xFFD0A882);
  static const _green = Color(0xFF27A85A);
  static const _red = Color(0xFFE53935);
  static const _t2 = Color(0xFF5E4A38);
  static const _t3 = Color(0xFFA0887A);

  @override
  Widget build(BuildContext context) {
    final actualsAsync = ref.watch(adminActualsProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: actualsAsync.when(
                data: (actuals) => _buildFirestoreContent(actuals),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Aktüel kataloglar yüklenemedi.\n$error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFirestoreContent(List<ActualModel> allActuals) {
    final actuals = allActuals.where((actual) => actual.isActive).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    if (actuals.isEmpty) {
      return const Center(child: Text('Yayınlanmış aktüel katalog bulunamadı.'));
    }

    final markets = <_MarketTabData>[];
    for (final actual in actuals) {
      if (markets.any((market) => market.id == actual.marketId)) continue;
      markets.add(
        _MarketTabData(
          id: actual.marketId,
          name: actual.marketName.isEmpty ? 'Market' : actual.marketName,
          color: _marketColor(actual.marketName),
        ),
      );
    }

    final selectedMarketId = markets.any((market) => market.id == _selectedMarketId) ? _selectedMarketId : markets.first.id;
    final marketActuals = actuals.where((actual) => actual.marketId == selectedMarketId).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final selectedActualId = marketActuals.any((actual) => actual.id == _selectedActualId) ? _selectedActualId : marketActuals.first.id;
    final selectedActual = marketActuals.firstWhere((actual) => actual.id == selectedActualId);
    final isUpcoming = selectedActual.startDate.isAfter(DateTime.now());
    final dateTabs = marketActuals
        .map(
          (actual) => _DateTabData(
            id: actual.id,
            label: DateFormat('d MMMM', 'tr_TR').format(actual.startDate),
          ),
        )
        .toList();

    final itemsAsync = ref.watch(actualItemsProvider(selectedActual.id));

    return Column(
      children: [
        _buildMarketTabs(markets, selectedMarketId),
        _buildDateTabs(dateTabs, selectedActual.id),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: isUpcoming ? _upcomingBanner() : _activeBanner(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: itemsAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Text('Bu katalog için ürün bulunamadı.'),
                      );
                    }
                    return Column(
                      children: [
                        for (int i = 0; i < items.length; i++)
                          _AnimatedEntry(
                            delay: i * 90,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: _ProductCard(
                                data: _ProductData.fromActualItem(items[i]),
                                marketName: selectedActual.marketName,
                                isUpcoming: isUpcoming,
                                dk: _dk,
                                gold: _gold,
                                goldLight: _goldLight,
                                whiteCard: _whiteCard,
                                green: _green,
                                red: _red,
                                t2: _t2,
                                t3: _t3,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text('Ürünler yüklenemedi: $error'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: _dk,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x1A18100A), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _iconBox(
            icon: Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          Text('Aktüel Kataloglar', style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: Colors.white)),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined, color: _gold),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketTabs(List<_MarketTabData> markets, String? selectedMarketId) {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final market = markets[index];
          final selected = selectedMarketId == market.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedMarketId = market.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? _dk : _whiteCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? _dk : const Color(0x14281108)),
                boxShadow: [
                  BoxShadow(
                    color: selected ? const Color(0x2E1C1108) : const Color(0x08281108),
                    blurRadius: selected ? 20 : 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  AnimatedScale(
                    scale: selected ? 1 : .8,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: market.color, shape: BoxShape.circle),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      market.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : _t2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: markets.length,
      ),
    );
  }

  Widget _buildDateTabs(List<_DateTabData> dates, String selectedActualId) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0D1C1108))),
      ),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, index) {
            final selected = selectedActualId == dates[index].id;
            return GestureDetector(
              onTap: () => setState(() => _selectedActualId = dates[index].id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0x26BF9470) : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: selected ? _gold : const Color(0x4DBF9470)),
                ),
                child: Text(
                  dates[index].label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? _dk : _t2,
                  ),
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemCount: dates.length,
        ),
      ),
    );
  }

  Widget _activeBanner() {
    return Container(
      key: const ValueKey('activeBanner'),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0x1A27A85A),
        border: Border.all(color: const Color(0x3327A85A)),
      ),
      child: _bannerContent(Icons.groups_rounded, 'Mağazada mısın? Bildir!', 'Gördüğün ürünün stok durumunu bildir, radar topluluğuna katıl ve puan kazan.', _green),
    );
  }

  Widget _upcomingBanner() {
    return Container(
      key: const ValueKey('upcomingBanner'),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0x1ABF9470),
        border: Border.all(color: const Color(0x4DBF9470)),
      ),
      child: _bannerContent(Icons.schedule_rounded, 'Kampanya Bekleniyor', 'Bu ürünler henüz raflara dizilmedi. Piyasaya çıktığı an stok takibi başlayacak.', _gold),
    );
  }

  Widget _bannerContent(IconData icon, String title, String subtitle, Color tone) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _whiteCard,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: tone.withOpacity(.2), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Icon(icon, size: 18, color: tone),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: _dk)),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: _t2, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconBox({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0x33BF9470)),
          color: const Color(0x0DFFFFFF),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Color _marketColor(String rawName) {
    final name = rawName.toLowerCase();
    if (name.contains('bim') || name.contains('bi̇m')) return const Color(0xFFD4A000);
    if (name.contains('a101') || name.contains('a-101')) return const Color(0xFFD44020);
    if (name.contains('şok') || name.contains('sok')) return const Color(0xFF7B3FA0);
    if (name.contains('migros')) return const Color(0xFFE07020);
    return _gold;
  }
}

String _formatPrice(double value) => '${value.toStringAsFixed(2).replaceAll('.', ',')}₺';

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.data,
    required this.marketName,
    required this.isUpcoming,
    required this.dk,
    required this.gold,
    required this.goldLight,
    required this.whiteCard,
    required this.green,
    required this.red,
    required this.t2,
    required this.t3,
  });

  final _ProductData data;
  final String marketName;
  final bool isUpcoming;
  final Color dk;
  final Color gold;
  final Color goldLight;
  final Color whiteCard;
  final Color green;
  final Color red;
  final Color t2;
  final Color t3;

  @override
  Widget build(BuildContext context) {
    final cardMuted = data.outOfStock && !isUpcoming;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: cardMuted ? .6 : 1,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(cardMuted ? Colors.grey.withOpacity(.35) : Colors.transparent, BlendMode.saturation),
        child: Container(
          decoration: BoxDecoration(
            color: whiteCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x14281108)),
            boxShadow: const [BoxShadow(color: Color(0x0F1C1108), blurRadius: 30, offset: Offset(0, 10))],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 185,
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F4EE),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0x0D1C1108)),
                          ),
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(Color(0x11FFFFFF), BlendMode.multiply),
                            child: CachedNetworkImage(imageUrl: data.imageUrl, fit: BoxFit.contain),
                          ),
                        ),
                        if (isUpcoming)
                          Transform.rotate(
                            angle: -.17,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: dk,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: gold),
                              ),
                              child: Text('YAKINDA', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: gold)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(data.brand, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .8, color: gold)),
                    const SizedBox(height: 4),
                    Text(data.name, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: dk, height: 1.2)),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(data.newPrice, style: GoogleFonts.dmSerifDisplay(fontSize: 30, color: dk, height: 1)),
                        if (data.oldPrice != null) ...[
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(data.oldPrice!, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: t3, decoration: TextDecoration.lineThrough)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (!isUpcoming) _stockArea(context) else _upcomingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stockArea(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: dk,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: const Border(top: BorderSide(color: Color(0x1A1C1108))),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x26BF9470)),
            ),
            child: Opacity(
              opacity: data.reportDisabled || data.outOfStock ? .5 : 1,
              child: IgnorePointer(
                ignoring: data.reportDisabled || data.outOfStock,
                child: Column(
                  children: [
                    Text(data.reportTitle ?? 'Şu an buradasın, durumu bildir:', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: .4)),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        _StockButton(label: '🟢 Bol', type: _BranchStatus.bol),
                        SizedBox(width: 8),
                        _StockButton(label: '🟡 Az', type: _BranchStatus.az),
                        SizedBox(width: 8),
                        _StockButton(label: '🔴 Bitti', type: _BranchStatus.yok),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Text(
            '📍 Çevrendeki $marketName Şubeleri',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            data.note.isEmpty ? 'Bu ürün için henüz şube bildirimi yok.' : data.note,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white.withOpacity(.7), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _upcomingOverlay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0x14BF9470),
        border: Border(top: BorderSide(color: Color(0x4DBF9470), style: BorderStyle.solid)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, color: gold, size: 32),
          const SizedBox(height: 10),
          Text('Beklemede Kal', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: dk)),
          const SizedBox(height: 6),
          Text(
            'Bu fırsat Salı günü raflarda yerini alacak. Piyasaya çıktığı an stok takibi başlayacaktır.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: t2, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _StockButton extends StatelessWidget {
  const _StockButton({required this.label, required this.type});

  final String label;
  final _BranchStatus type;

  @override
  Widget build(BuildContext context) {
    final (colors, text, border) = switch (type) {
      _BranchStatus.bol => ([const Color(0x3327A85A), const Color(0x0D27A85A)], const Color(0xFFA7F3D0), const Color(0x4D27A85A)),
      _BranchStatus.az => ([const Color(0x4DBF9470), const Color(0x1ABF9470)], const Color(0xFFD0A882), const Color(0x80BF9470)),
      _BranchStatus.yok => ([const Color(0x33E53935), const Color(0x0DE53935)], const Color(0xFFFCA5A5), const Color(0x4DE53935)),
    };

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Center(child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: text))),
      ),
    );
  }
}

class _AnimatedEntry extends StatelessWidget {
  const _AnimatedEntry({required this.child, required this.delay});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + delay),
      curve: Curves.easeOut,
      builder: (_, value, ch) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, (1 - value) * 20), child: ch),
      ),
      child: child,
    );
  }
}

enum _BranchStatus { bol, az, yok }

class _ProductData {
  const _ProductData({
    required this.brand,
    required this.name,
    required this.newPrice,
    this.oldPrice,
    required this.imageUrl,
    required this.note,
    this.reportTitle,
    this.reportDisabled = false,
    this.outOfStock = false,
  });

  factory _ProductData.fromActualItem(ActualItemModel item) {
    final brand = item.category.trim().isEmpty ? 'AKTÜEL ÜRÜN' : item.category.trim().toUpperCase();
    return _ProductData(
      brand: brand,
      name: item.name,
      newPrice: _formatPrice(item.price),
      oldPrice: item.oldPrice == null ? null : _formatPrice(item.oldPrice!),
      imageUrl: item.imageUrl,
      note: item.note,
      reportTitle: item.type.trim().isEmpty ? null : item.type.trim(),
      outOfStock: item.isActive == false,
    );
  }

  final String brand;
  final String name;
  final String newPrice;
  final String? oldPrice;
  final String imageUrl;
  final String note;
  final String? reportTitle;
  final bool reportDisabled;
  final bool outOfStock;
}

class _DateTabData {
  const _DateTabData({required this.id, required this.label});

  final String id;
  final String label;
}

class _MarketTabData {
  const _MarketTabData({required this.id, required this.name, required this.color});

  final String id;
  final String name;
  final Color color;
}
