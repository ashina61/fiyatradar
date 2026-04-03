import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, this.productId = ''});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textSecondary, size: 20),
            onPressed: () => _showToast(context, 'Paylaşım linki kopyalandı!'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: AppColors.textSecondary, size: 20),
            onPressed: () => _showToast(context, 'Listeye eklendi!'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  children: [
                    // 1. Hero Section
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        children: [
                          Container(
                            width: 160,                            height: 160,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Center(
                              child: Icon(Icons.headphones_rounded, size: 72, color: AppColors.tan),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Sony WH-1000XM5',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Sony • Elektronik',
                            style: TextStyle(fontSize: 13, color: AppColors.textSubtle),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.star_rounded, size: 14, color: AppColors.tan),
                                SizedBox(width: 5),
                                Text('4.3', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.tan)),
                                SizedBox(width: 6),
                                Text('• 128 yorum', style: TextStyle(fontSize: 12, color: AppColors.textSubtle)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Best Price Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,                            end: Alignment.bottomRight,
                            colors: [AppColors.surfaceAlt, AppColors.surface],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(color: const Color(0x40C4A57B)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 4)),
                          ],
                        ),
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.workspace_premium_rounded, size: 16, color: AppColors.tan),
                                SizedBox(width: 5),
                                Text(
                                  'EN İYİ FİYAT',
                                  style: TextStyle(fontSize: 11, color: AppColors.tan, letterSpacing: 0.8, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              '₺1.299',
                              style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -1),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.full),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.store_outlined, size: 14, color: AppColors.textSecondary),
                                  SizedBox(width: 7),
                                  Text('Trendyol', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  SizedBox(width: 6),
                                  SizedBox(width: 1, height: 10, child: VerticalDivider(color: Color(0x33FFFFFF), thickness: 1, width: 1)),
                                  SizedBox(width: 6),
                                  Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                                  SizedBox(width: 4),
                                  Text('2s önce', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                                  SizedBox(width: 5),
                                  Text('Doğrulandı', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showToast(context, 'Listeye eklendi!'),
                                    icon: const Icon(Icons.star_rounded, size: 16),
                                    label: const Text('Listeye Ekle'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.tan,
                                      foregroundColor: AppColors.bgPrimary,
                                      minimumSize: const Size(0, 38),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showToast(context, 'Alarm kuruldu!'),
                                    icon: const Icon(Icons.notifications_none_rounded, size: 16),
                                    label: const Text('Alarm'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.textPrimary,
                                      side: const BorderSide(color: AppColors.border),
                                      minimumSize: const Size(0, 38),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                                    ),
                                  ),
                                ),
                              ],
                            ),                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Trust Block
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.shield_rounded, size: 17, color: AppColors.success),
                                    SizedBox(width: 6),
                                    Text('Güven Analizi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  ],
                                ),
                                Row(
                                  children: const [
                                    Text('94%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.success)),
                                    SizedBox(width: 6),
                                    Text('Güvenilir', style: TextStyle(fontSize: 10, color: AppColors.textSubtle, letterSpacing: 0.3, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(height: 1, color: AppColors.border),
                            const SizedBox(height: 14),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 2.8,
                              children: const [
                                _TrustItem(icon: Icons.check_rounded, title: 'Doğrulanmış', subtitle: 'Topluluk onayı'),                                _TrustItem(icon: Icons.bolt_rounded, title: 'Canlı Veri', subtitle: 'Son 5 dakika'),
                                _TrustItem(icon: Icons.trending_up_rounded, title: 'Trend', subtitle: 'Ortalamadan %12 düşük'),
                                _TrustItem(icon: Icons.group_outlined, title: 'Kaynak', subtitle: '12 farklı platform'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Contributor Spotlight
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [AppColors.surfaceAlt, AppColors.surface]),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Center(child: Icon(Icons.person, size: 17, color: AppColors.textSecondary)),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Mehmet Y.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text('L12', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.bgPrimary, backgroundColor: AppColors.tan)),
                                      SizedBox(width: 5),
                                      Text('• %96 Güven', style: TextStyle(fontSize: 10, color: AppColors.textSubtle)),
                                    ],
                                  ),
                                ],
                              ),
                            ),                            GestureDetector(
                              onTap: () => _showToast(context, 'Kullanıcı takip edildi!'),
                              child: const Text('+ Takip', style: TextStyle(fontSize: 11, color: AppColors.tan, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Chart
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('30 Günlük Değişim', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                Row(
                                  children: [
                                    _ChartButton('7G'),
                                    _ChartButton('30G', isActive: true),
                                    _ChartButton('90G'),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _ChartBar(height: 40),
                                  _ChartBar(height: 55),
                                  _ChartBar(height: 45),
                                  _ChartBar(height: 70),
                                  _ChartBar(height: 60),
                                  _ChartBar(height: 80, isActive: true),
                                ],                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 6. Seller List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Diğer Platformlar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              GestureDetector(
                                onTap: () => _showToast(context, 'Tümünü Gör'),
                                child: const Text('Tümünü Gör', style: TextStyle(fontSize: 12, color: AppColors.tan, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _SellerItem(logo: 'H', name: 'Hepsiburada', meta: '91% Güven • 5s önce', price: '₺1.349', diff: '+₺50'),
                          _SellerItem(logo: 'A', name: 'Amazon', meta: '96% Güven • 1s önce', price: '₺1.399', diff: '+₺100'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // 7. Sticky Bottom Action Bar
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.bgPrimary.withOpacity(0.95)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(                      onPressed: () => _showToast(context, 'Alarm kuruldu!'),
                      icon: const Icon(Icons.notifications_none_rounded, size: 18),
                      label: const Text('Alarm'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/add-price'),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Fiyat Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tan,
                        foregroundColor: AppColors.bgPrimary,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                        elevation: 0,
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

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.surfaceAlt,
      ),
    );
  }
}

// --- HELPER WIDGETS ---

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _TrustItem({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 14, color: AppColors.tan),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSubtle, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartButton extends StatelessWidget {
  final String label;
  final bool isActive;
  const _ChartButton(this.label, {this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      margin: const EdgeInsets.only(left: 5),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surfaceAlt : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.tan : AppColors.textSubtle,
        ),
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  final double height;
  final bool isActive;
  const _ChartBar({required this.height, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: isActive ? AppColors.tan : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _SellerItem extends StatelessWidget {
  final String logo;
  final String name;
  final String meta;
  final String price;
  final String diff;
  const _SellerItem({required this.logo, required this.name, required this.meta, required this.price, required this.diff});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Center(child: Text(logo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.tan))),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(meta, style: const TextStyle(fontSize: 10, color: AppColors.textSubtle)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text(diff, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success)),
            ],
          ),
        ),
      ),
    );
  }
}
