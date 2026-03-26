import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/fr_colors.dart';
import '../../widgets/staggered_fade_slide.dart';

class CartListDetailScreen extends StatelessWidget {
  const CartListDetailScreen({
    super.key,
    this.data = const SmartBasketDetailData.mock(),
    this.onBack,
    this.onShare,
    this.onCompare,
  });

  final SmartBasketDetailData data;
  final VoidCallback? onBack;
  final VoidCallback? onShare;
  final VoidCallback? onCompare;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEAE3),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(
                    onBack: onBack ?? () => Navigator.of(context).maybePop(),
                    onShare: onShare,
                  ),
                  const SizedBox(height: 10),
                  StaggeredFadeSlide(index: 0, offsetY: 14, child: _SummaryCard(data: data)),
                  const SizedBox(height: 24),
                  _ListHeader(itemCount: data.items.length),
                  const SizedBox(height: 12),
                  for (var i = 0; i < data.items.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: StaggeredFadeSlide(
                        index: i + 1,
                        offsetY: 12,
                        baseDelayMs: 80,
                        stepDelayMs: 80,
                        child: _BasketItemRow(item: data.items[i]),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: SafeArea(
                top: false,
                child: _BottomCompareButton(
                  text: 'Sepeti Kıyasla (${data.items.length} Ürün)',
                  onTap: onCompare,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, this.onShare});

  final VoidCallback onBack;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: [
          _IconButtonShell(icon: Icons.chevron_left_rounded, onTap: onBack, iconSize: 24),
          Expanded(
            child: Text(
              'Liste Detayı',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF18100A),
              ),
            ),
          ),
          _IconButtonShell(icon: Icons.share_outlined, onTap: onShare, iconSize: 18),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final SmartBasketDetailData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF18100A), Color(0xFF2A1A0B)],
        ),
        boxShadow: [
          BoxShadow(
            color: FRColors.espresso.withOpacity(0.20),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [FRColors.camel.withOpacity(0.2), Colors.transparent],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: FRColors.camel.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: FRColors.camel.withOpacity(0.30)),
                    ),
                    child: Text(
                      data.badge,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: FRColors.camel,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.title,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 24,
                      height: 1.1,
                      color: FRColors.white,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: FRColors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: FRColors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: FRColors.white.withOpacity(0.10)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.totalLabel,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: FRColors.white.withOpacity(0.60),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                data.totalPriceText,
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 32,
                                  height: 1,
                                  color: FRColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF27A85A).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                data.savingText,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E8E3E),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.marketInsight,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: FRColors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Sepet İçeriği',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF18100A),
          ),
        ),
        const Spacer(),
        Text(
          '$itemCount Ürün',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: FRColors.camel,
          ),
        ),
      ],
    );
  }
}

class _BasketItemRow extends StatelessWidget {
  const _BasketItemRow({required this.item});

  final SmartBasketItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1418100A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F4EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.network(
              item.imageUrl,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.brand,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    height: 1,
                    color: FRColors.camel,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF18100A),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final tag in item.tags)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDEAE3),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0x1418100A)),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF5E4A38),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.priceText,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 18,
                  height: 1,
                  color: const Color(0xFF18100A),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x0D18100A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: item.marketColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.market,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF18100A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomCompareButton extends StatelessWidget {
  const _BottomCompareButton({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 58,
          decoration: BoxDecoration(
            color: FRColors.camel,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: FRColors.camel.withOpacity(0.4),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_cart_outlined, color: Color(0xFF18100A), size: 22),
                const SizedBox(width: 10),
                Text(
                  text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF18100A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconButtonShell extends StatelessWidget {
  const _IconButtonShell({
    required this.icon,
    required this.onTap,
    this.iconSize = 20,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAF8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1418100A)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: iconSize, color: const Color(0xFF18100A)),
      ),
    );
  }
}

class SmartBasketDetailData {
  const SmartBasketDetailData({
    required this.badge,
    required this.title,
    required this.description,
    required this.totalLabel,
    required this.totalPriceText,
    required this.savingText,
    required this.marketInsight,
    required this.items,
  });

  const SmartBasketDetailData.mock()
      : badge = 'Akıllı Kombin',
        title = 'Haftalık Kahvaltı',
        description = 'Bu sepet temel ihtiyaçlarınıza göre FiyatRadar AI tarafından oluşturulmuştur.',
        totalLabel = 'En İyi Eşleşme (Toplam)',
        totalPriceText = '425,10₺',
        savingText = '65₺ Daha Ucuz',
        marketInsight = 'A-101 Sepeti ile',
        items = const [
          SmartBasketItem(
            imageUrl: 'https://images.openfoodfacts.org/images/products/869/064/403/1202/front_tr.22.400.jpg',
            brand: 'DOĞADAN',
            name: 'Çiçek Balı 460g Kavanoz',
            tags: ['460g', 'Kahvaltılık'],
            priceText: '119,90₺',
            market: 'A-101',
            marketColor: Color(0xFFD44020),
          ),
          SmartBasketItem(
            imageUrl: 'https://images.openfoodfacts.org/images/products/869/081/400/3142/front_tr.26.400.jpg',
            brand: 'SÜTAŞ',
            name: 'Kaşar Peynir 400g Tam Yağlı',
            tags: ['400g'],
            priceText: '74,90₺',
            market: 'BİM',
            marketColor: Color(0xFFD4A000),
          ),
          SmartBasketItem(
            imageUrl: 'https://images.openfoodfacts.org/images/products/301/762/042/2003/front_fr.276.400.jpg',
            brand: 'FERRERO',
            name: 'Nutella 400g Fındık Kreması',
            tags: ['400g', 'Tatlı'],
            priceText: '64,90₺',
            market: 'A-101',
            marketColor: Color(0xFFD44020),
          ),
          SmartBasketItem(
            imageUrl: 'https://images.openfoodfacts.org/images/products/800/184/104/5536/front_fr.23.400.jpg',
            brand: 'MARMARABİRLİK',
            name: 'Siyah Zeytin 500g XS',
            tags: ['500g'],
            priceText: '75,40₺',
            market: 'ŞOK',
            marketColor: Color(0xFF7B3FA0),
          ),
          SmartBasketItem(
            imageUrl: 'https://images.openfoodfacts.org/images/products/761/303/524/2993/front_fr.8.400.jpg',
            brand: 'LİPTON',
            name: 'Sarı Etiket Dökme Çay 500g',
            tags: ['500g'],
            priceText: '90,00₺',
            market: 'Migros',
            marketColor: Color(0xFFE07020),
          ),
        ];

  final String badge;
  final String title;
  final String description;
  final String totalLabel;
  final String totalPriceText;
  final String savingText;
  final String marketInsight;
  final List<SmartBasketItem> items;
}

class SmartBasketItem {
  const SmartBasketItem({
    required this.imageUrl,
    required this.brand,
    required this.name,
    required this.tags,
    required this.priceText,
    required this.market,
    required this.marketColor,
  });

  final String imageUrl;
  final String brand;
  final String name;
  final List<String> tags;
  final String priceText;
  final String market;
  final Color marketColor;
}
