import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/fr_colors.dart';

class HelpAndFaqScreen extends StatelessWidget {
  const HelpAndFaqScreen({super.key});

  static const List<_FaqItem> _items = <_FaqItem>[
    _FaqItem(
      question: 'Puan Toplama Sistemi',
      isVip: true,
      startsExpanded: true,
      points: <String>[
        'Her fiyat girişi +10 puan kazandırır.',
        'Fotoğraf eklenen fiyat girişi +20 puan kazandırır.',
        'Doğrulanan katkılarda güven puanınız yükselir, hatalı bildirimlerde düşebilir.',
        'Puanlar rozetleri, seviye ilerlemesini ve liderlik tablosundaki sıranızı etkiler.',
      ],
    ),
    _FaqItem(
      question: 'Puan sistemi nasıl çalışır?',
      answer:
          'Fiyat ekleme, doğrulama ve topluluk etkileşimlerinden puan kazanırsınız. Puanlar seviyenizi, rozetlerinizi ve liderlik tablosundaki sıralamanızı etkiler.',
    ),
    _FaqItem(
      question: 'Güven puanı nasıl kazanılır?',
      answer:
          'Eklediğiniz fiyatlar diğer kullanıcılar ve sistem kontrolleri tarafından doğru bulunduğunda güven puanınız artar. Hatalı veya yanıltıcı girişlerde güven puanı düşebilir.',
    ),
    _FaqItem(
      question: 'Fiyat nasıl eklerim?',
      answer:
          'Ana ekrandaki + butonuna dokunun, ürün/market/fiyat bilgilerini girin ve kaydedin. Fotoğraf eklerseniz katkınız daha hızlı doğrulanır.',
    ),
    _FaqItem(
      question: 'Fiyatın güvenilir olduğunu nasıl anlarım?',
      answer:
          'Ürün detayındaki doğrulama oranına, son güncelleme zamanına ve katkı yapan kullanıcının güven göstergesine bakın. Birden fazla yeni doğrulama varsa fiyat daha güvenilirdir.',
    ),
    _FaqItem(
      question: 'Hesabımı nasıl silerim?',
      answer:
          'Profil > Ayarlar > Güvenlik menüsünden hesap kapatma talebi oluşturabilirsiniz. Güvenlik doğrulaması sonrası hesap kalıcı olarak silinir.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: FRColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, topPadding + 18, 24, 12),
              child: Row(
                children: <Widget>[
                  _TopActionButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _Header()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: index == _items.length - 1 ? 0 : 16),
                    child: _FaqCard(item: _items[index]),
                  );
                },
                childCount: _items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          Text(
            'Yardım ve SSS',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              color: FRColors.espresso,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'AKLINIZA TAKILANLAR',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: FRColors.camel,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqCard extends StatefulWidget {
  const _FaqCard({required this.item});

  final _FaqItem item;

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.item.startsExpanded;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      value: _isExpanded ? 1 : 0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isVip = widget.item.isVip;
    final Color titleColor = isVip ? FRColors.white : FRColors.espresso;
    final Color contentColor = isVip ? FRColors.whiteMuted : FRColors.textMutedSoft;
    final Color collapsedDiamond = isVip ? FRColors.camel : FRColors.espressoOverlay(0.06);
    final Color expandedDiamond = isVip ? FRColors.white : FRColors.camel;
    final Color innerDiamondColor = isVip
        ? (_isExpanded ? FRColors.camel : FRColors.espresso)
        : FRColors.surface;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isVip ? null : FRColors.surface,
        gradient: isVip
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  FRColors.espressoOverlay(0.95),
                  const Color(0xFF0A0604),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isVip ? FRColors.camelOverlay(0.4) : FRColors.border,
        ),
        boxShadow: <BoxShadow>[
          if (isVip) ...<BoxShadow>[
            BoxShadow(
              color: FRColors.espressoOverlay(0.2),
              blurRadius: 50,
              offset: const Offset(0, 20),
            ),
          ] else
            BoxShadow(
              color: FRColors.espressoOverlay(0.02),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: <Widget>[
            if (isVip)
              Positioned(
                top: -50,
                right: -50,
                child: IgnorePointer(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: <Color>[
                          FRColors.camelOverlay(0.25),
                          Colors.transparent,
                        ],
                        stops: const <double>[0, 0.7],
                      ),
                    ),
                  ),
                ),
              ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggle,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              widget.item.question,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          AnimatedRotation(
                            turns: _isExpanded ? 0.25 : 0,
                            duration: const Duration(milliseconds: 360),
                            curve: Curves.easeOutBack,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                              width: 18,
                              height: 18,
                              transform: Matrix4.rotationZ(math.pi / 4),
                              transformAlignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _isExpanded ? expandedDiamond : collapsedDiamond,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: isVip
                                    ? <BoxShadow>[
                                        BoxShadow(
                                          color: FRColors.camelOverlay(0.5),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Transform.rotate(
                                  angle: -math.pi / 4,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: innerDiamondColor,
                                      borderRadius: BorderRadius.circular(1.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      ClipRect(
                        child: SizeTransition(
                          sizeFactor: _expandAnimation,
                          axisAlignment: -1,
                          child: FadeTransition(
                            opacity: _expandAnimation,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 18),
                              child: isVip
                                  ? _VipPointList(points: widget.item.points!, color: contentColor)
                                  : Text(
                                      widget.item.answer!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.6,
                                        fontWeight: FontWeight.w500,
                                        color: contentColor,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VipPointList extends StatelessWidget {
  const _VipPointList({required this.points, required this.color});

  final List<String> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: points
          .map(
            (String point) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8, right: 10),
                    decoration: const BoxDecoration(
                      color: FRColors.camel,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: FRColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: FRColors.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: FRColors.shadowSoft,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: FRColors.espresso, size: 18),
        ),
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({
    required this.question,
    this.answer,
    this.points,
    this.isVip = false,
    this.startsExpanded = false,
  });

  final String question;
  final String? answer;
  final List<String>? points;
  final bool isVip;
  final bool startsExpanded;
}
