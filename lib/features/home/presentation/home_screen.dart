import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Üst Karşılama ve Bildirim
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Merhaba, Adem', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSubtle)),
                    Row(
                      children: const [
                        Text('Fiyat', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text('Radar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.tan)),
                      ],
                    ),
                  ],
                ),
                Stack(
                  children: [
                    const Icon(FontAwesomeIcons.bell, color: AppColors.textPrimary, size: 22),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.tan,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.bgPrimary, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadii.xl,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(FontAwesomeIcons.magnifyingGlass, color: AppColors.tan, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Ürün, marka veya kategori ara...', style: TextStyle(color: AppColors.textSubtle.withOpacity(0.6), fontSize: 14)),
                  ),
                  const Icon(FontAwesomeIcons.qrcode, color: AppColors.textSubtle, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Canlı Fiyatlar Başlık
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(FontAwesomeIcons.bolt, color: AppColors.tan, size: 16),
                    SizedBox(width: 8),
                    Text('Canlı Fiyatlar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ],
                ),
                const Text('Tümü', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.tan)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Feed Listesi
          _buildLiveFeedItem('🎧', 'Sony WH-1000XM5', 'Trendyol • 2s', '₺1.299'),
          _buildLiveFeedItem('📚', 'Simyacı', 'D&R • 12s', '₺89'),
          _buildLiveFeedItem('☕', 'Nespresso Vertuo', 'Amazon • 1m', '₺3.499'),
          
          const SizedBox(height: 24),

          // Seçkiler (Trendler)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: const [
                Icon(FontAwesomeIcons.compass, color: AppColors.tan, size: 16),
                SizedBox(width: 8),
                Text('Seçkiler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Yatay Kaydırılabilir Kartlar
          SizedBox(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildTrendCard('💻', 'MacBook Pro M3', '₺45.000 - ₺52.000'),
                const SizedBox(width: 12),
                _buildTrendCard('📱', 'iPhone 15 Pro', '₺38.000 - ₺42.000'),
                const SizedBox(width: 12),
                _buildTrendCard('⌚', 'Apple Watch', '₺8.500 - ₺11.000'),
              ],
            ),
          ),
          const SizedBox(height: 80), // Alt menü arkasında kalmaması için boşluk
        ],
      ),
    );
  }

  // Ortak Widget: Canlı Fiyat Kartı
  Widget _buildLiveFeedItem(String emoji, String name, String meta, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, left: 24, right: 24),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.lg,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: AppRadii.md,
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(FontAwesomeIcons.shop, color: AppColors.textSubtle, size: 10),
                    const SizedBox(width: 4),
                    Text(meta, style: const TextStyle(fontSize: 10, color: AppColors.textSubtle)),
                  ],
                ),
              ],
            ),
          ),
          Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.tan)),
        ],
      ),
    );
  }

  // Ortak Widget: Trend Kartı
  Widget _buildTrendCard(String emoji, String title, String price) {
    return Container(
      width: 155,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.xl,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 95,
            decoration: const BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(17), topRight: Radius.circular(17)),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 42))),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(price, style: const TextStyle(fontSize: 10, color: AppColors.textSubtle)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
