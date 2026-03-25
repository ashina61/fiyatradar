import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActualsScreen extends StatefulWidget {
  const ActualsScreen({super.key});

  @override
  State<ActualsScreen> createState() => _ActualsScreenState();
}

class _ActualsScreenState extends State<ActualsScreen> {
  int _selectedMarket = 0;
  int _selectedDate = 1;

  static const _bg = Color(0xFFEDEAE3);
  static const _dk = Color(0xFF18100A);
  static const _whiteCard = Color(0xFFFAFAF8);
  static const _gold = Color(0xFFBF9470);
  static const _goldLight = Color(0xFFD0A882);
  static const _green = Color(0xFF27A85A);
  static const _red = Color(0xFFE53935);
  static const _t2 = Color(0xFF5E4A38);
  static const _t3 = Color(0xFFA0887A);

  final _markets = const [
    _MarketTabData(name: 'BİM', color: Color(0xFFD4A000)),
    _MarketTabData(name: 'A-101', color: Color(0xFFD44020)),
    _MarketTabData(name: 'ŞOK', color: Color(0xFF7B3FA0)),
  ];

  final _dates = const [
    _DateTabData(label: 'Geçen Cuma', isFuture: false),
    _DateTabData(label: 'Bu Cuma (27 Mart)', isFuture: false),
    _DateTabData(label: 'Gelecek Salı (31 Mart)', isFuture: true),
  ];

  final _activeProducts = const [
    _ProductData(
      brand: 'FERRERO',
      name: 'Nutella 750g Avantaj Paketi',
      newPrice: '99,50₺',
      oldPrice: '145,00₺',
      imageUrl: 'https://images.openfoodfacts.org/images/products/301/762/042/2003/front_fr.276.400.jpg',
      branches: [
        _BranchData(name: 'Gülnar Sokak BİM', distance: 'Buradasın • 1 dk önce', status: _BranchStatus.bol, isCurrent: true),
      ],
      reportTitle: 'Şu an buradasın, durumu bildir:',
    ),
    _ProductData(
      brand: 'PHILIPS',
      name: 'Essential Airfryer HD9252',
      newPrice: '1.999₺',
      oldPrice: '2.899₺',
      imageUrl: 'https://m.media-amazon.com/images/I/61Nl0bW7-4L._AC_SL1500_.jpg',
      reportTitle: 'Bu şubede değilsin',
      reportDisabled: true,
      branches: [
        _BranchData(name: 'Çamlık Merkez BİM', distance: '450m • 15 dk önce', status: _BranchStatus.az),
        _BranchData(name: 'Cumhuriyet Cad. BİM', distance: '820m • 2 saat önce', status: _BranchStatus.yok),
      ],
    ),
    _ProductData(
      brand: 'SEK',
      name: 'Tam Yağlı Süt 1 Lt (6\'lı Koli)',
      newPrice: '110,00₺',
      oldPrice: '150,00₺',
      imageUrl: 'https://images.openfoodfacts.org/images/products/869/039/703/0064/front_tr.21.400.jpg',
      outOfStock: true,
      branches: [
        _BranchData(name: 'Gülnar Sokak BİM', distance: 'Buradasın • 2 dk önce', status: _BranchStatus.yok, isCurrent: true),
      ],
    ),
  ];

  final _upcomingProducts = const [
    _ProductData(
      brand: 'DOVE',
      name: 'Şampuan 500ml + Duş Jeli',
      newPrice: '125,00₺',
      oldPrice: '180,00₺',
      imageUrl: 'https://images.openfoodfacts.org/images/products/871/090/815/9966/front_fr.50.400.jpg',
    ),
    _ProductData(
      brand: 'NESCAFÉ',
      name: 'Classic 200g + Kupa Hediye',
      newPrice: '189,90₺',
      oldPrice: '240,00₺',
      imageUrl: 'https://images.openfoodfacts.org/images/products/761/303/524/2993/front_fr.8.400.jpg',
    ),
  ];

  bool get _isUpcoming => _dates[_selectedDate].isFuture;

  @override
  Widget build(BuildContext context) {
    final products = _isUpcoming ? _upcomingProducts : _activeProducts;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildMarketTabs(),
            _buildDateTabs(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _isUpcoming ? _upcomingBanner() : _activeBanner(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        key: ValueKey(_selectedDate),
                        children: [
                          for (int i = 0; i < products.length; i++)
                            _AnimatedEntry(
                              delay: i * 90,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: _ProductCard(
                                  data: products[i],
                                  isUpcoming: _isUpcoming,
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildMarketTabs() {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final selected = _selectedMarket == index;
          final market = _markets[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedMarket = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                  Text(
                    market.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : _t2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _markets.length,
      ),
    );
  }

  Widget _buildDateTabs() {
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
            final selected = _selectedDate == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedDate = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0x26BF9470) : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: selected ? _gold : const Color(0x4DBF9470)),
                ),
                child: Text(
                  _dates[index].label,
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
          itemCount: _dates.length,
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
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.data,
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
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(data.oldPrice, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: t3, decoration: TextDecoration.lineThrough)),
                        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('📍 Çevrendeki BİM Şubeleri', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('Anlık', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(.4))),
            ],
          ),
          const SizedBox(height: 14),
          ...data.branches.map((branch) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BranchRow(branch: branch, gold: gold),
              )),
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

class _BranchRow extends StatefulWidget {
  const _BranchRow({required this.branch, required this.gold});

  final _BranchData branch;
  final Color gold;

  @override
  State<_BranchRow> createState() => _BranchRowState();
}

class _BranchRowState extends State<_BranchRow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final pulse = widget.branch.isCurrent ? Curves.easeInOut.transform(_controller.value) : 0.0;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.branch.isCurrent ? const Color(0x1ABF9470) : Colors.white.withOpacity(.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.branch.isCurrent ? widget.gold : const Color(0x1ABF9470)),
            boxShadow: widget.branch.isCurrent
                ? [BoxShadow(color: widget.gold.withOpacity(.35 * (1 - pulse)), blurRadius: 16 + (10 * pulse), spreadRadius: pulse * 2)]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: const Color(0x26BF9470), borderRadius: BorderRadius.circular(7)),
                    child: Icon(Icons.location_on_outlined, color: widget.gold, size: 12),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.branch.name, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text(widget.branch.distance, style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(.5))),
                    ],
                  ),
                ],
              ),
              _statusPill(widget.branch.status),
            ],
          ),
        );
      },
    );
  }

  Widget _statusPill(_BranchStatus status) {
    final (text, bg, fg, dot) = switch (status) {
      _BranchStatus.bol => ('Bol Var', const Color(0x2627A85A), const Color(0xFFA7F3D0), const Color(0xFFA7F3D0)),
      _BranchStatus.az => ('Az Kaldı', const Color(0x33BF9470), const Color(0xFFD0A882), const Color(0xFFD0A882)),
      _BranchStatus.yok => ('Tükendi', const Color(0x26E53935), const Color(0xFFFCA5A5), const Color(0xFFFCA5A5)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(color: dot),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: fg)),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: .5, end: 1).animate(_controller),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 1.1).animate(_controller),
        child: Container(width: 6, height: 6, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
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

class _BranchData {
  const _BranchData({required this.name, required this.distance, required this.status, this.isCurrent = false});

  final String name;
  final String distance;
  final _BranchStatus status;
  final bool isCurrent;
}

class _ProductData {
  const _ProductData({
    required this.brand,
    required this.name,
    required this.newPrice,
    required this.oldPrice,
    required this.imageUrl,
    this.reportTitle,
    this.reportDisabled = false,
    this.outOfStock = false,
    this.branches = const [],
  });

  final String brand;
  final String name;
  final String newPrice;
  final String oldPrice;
  final String imageUrl;
  final String? reportTitle;
  final bool reportDisabled;
  final bool outOfStock;
  final List<_BranchData> branches;
}

class _DateTabData {
  const _DateTabData({required this.label, required this.isFuture});

  final String label;
  final bool isFuture;
}

class _MarketTabData {
  const _MarketTabData({required this.name, required this.color});

  final String name;
  final Color color;
}
