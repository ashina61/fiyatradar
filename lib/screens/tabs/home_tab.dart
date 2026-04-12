import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../widgets/prototype_ui.dart';
import '../admin_screen.dart';
import '../main_screen.dart';
import '../notifications_screen.dart';
import '../product_detail_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final products = state.products.take(6).toList();

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: FRInsets.pageTopBar,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 4)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [ProtoColors.tan, ProtoColors.tanDark]),
                                borderRadius: FRRadii.pill,
                                border: Border.all(color: ProtoColors.tan.withOpacity(0.3), width: 2),
                              ),
                              alignment: Alignment.center,
                              child: const Text('FK', style: TextStyle(fontWeight: FontWeight.w800, color: ProtoColors.bgPrimary)),
                            ),
                            const SizedBox(width: 10),
                            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Merhaba,', style: TextStyle(fontSize: 10, color: ProtoColors.textSubtle, fontWeight: FontWeight.w500)),
                              Text('Adem', style: TextStyle(fontSize: 14, color: ProtoColors.textPrimary, fontWeight: FontWeight.w700)),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    NotificationButton(
                      badge: state.unreadNotificationCount,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: ProtoColors.tan,
                          borderRadius: FRRadii.pill,
                          border: Border.all(color: ProtoColors.tan),
                        ),
                        child: const Icon(Icons.settings, color: ProtoColors.bgPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              ProtoSearchField(
                hint: 'Ürün, market veya kategori ara...',
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
                ),
              ),
              SizedBox(
                height: 38,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _Chip('Tümü', Icons.grid_view_rounded, true),
                    _Chip('Elektronik', Icons.laptop, false),
                    _Chip('Gıda', Icons.restaurant, false),
                    _Chip('Bakım', Icons.spa, false),
                    _Chip('Ev', Icons.home, false),
                    _Chip('Spor', Icons.fitness_center, false),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: FRRadii.xl,
                  gradient: const LinearGradient(colors: [ProtoColors.flashStart, ProtoColors.flashEnd]),
                ),
                child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('⚡ FLASH DEAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  SizedBox(height: 4),
                  Text('Sony WH-1000XM5', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      _Timer('02', 'Saat'),
                      SizedBox(width: 8),
                      _Timer('45', 'Dk'),
                      SizedBox(width: 8),
                      _Timer('30', 'Sn'),
                    ],
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 100),
                  children: [
                    SizedBox(
                      height: 120,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        scrollDirection: Axis.horizontal,
                        children: const [
                          _Banner('🔥 Fırsat', 'Haftanın Fırsatları', 'En çok düşen fiyatları keşfet', [Color(0xFF8B6914), Color(0xFFB8956A)]),
                          SizedBox(width: 10),
                          _Banner('✅ Güvenilir', 'Doğrulanmış Düşüşler', 'Topluluk tarafından onaylananlar', [Color(0xFF4A6B5A), Color(0xFF6B8A7A)]),
                          SizedBox(width: 10),
                          _Banner('⭐ Popüler', 'Popüler Ürünler', 'Bu hafta en çok arananlar', [Color(0xFF6B4A8A), Color(0xFF8A6BAA)]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Dot(true),
                        SizedBox(width: 6),
                        _Dot(false),
                        SizedBox(width: 6),
                        _Dot(false),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text('✨ Senin İçin Öneriler', style: TextStyle(color: ProtoColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: _Suggestion('🎧', 'Sony WH-1000XM5', 'Son aradığın üründe ₺200 düşüş!', '₺1.299', ProtoColors.purple)),
                    const SizedBox(height: 8),
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: _Suggestion('☕', 'Lavazza Kahve', 'Sık satın aldığın kategoride fırsat', '₺329', ProtoColors.success)),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(child: Text('🔥 Canlı Fiyatlar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                          Text('Tümü', style: TextStyle(color: ProtoColors.tan, fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      itemCount: products.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemBuilder: (_, i) {
                        final p = products[i];
                        return InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
                          child: Container(
                            decoration: protoSurface(),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                                      gradient: LinearGradient(colors: [ProtoColors.surfaceAlt, ProtoColors.surfaceElevated]),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(p.emoji, style: const TextStyle(fontSize: 40)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    Text('₺${(p.lowestPrice ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, color: ProtoColors.tan)),
                                  ]),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 24,
            bottom: 86,
            child: InkWell(
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
              ),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: FRRadii.pill,
                  gradient: const LinearGradient(colors: [ProtoColors.tan, ProtoColors.tanLight]),
                  boxShadow: [
                    BoxShadow(color: ProtoColors.tan.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.add, color: ProtoColors.bgPrimary, size: 28),
              ),
            ),
          ),
          Positioned(
            top: 104,
            right: 20,
            child: Container(
              width: 220,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: FRRadii.lg,
                gradient: const LinearGradient(colors: [ProtoColors.success, Color(0xFF6B8A6B)]),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12)],
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(Icons.arrow_downward, size: 14, color: Colors.white), SizedBox(width: 8), Text('Fiyat Düştü!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white))]),
                SizedBox(height: 4),
                Text('Sony WH-1000XM5', style: TextStyle(fontSize: 11, color: Colors.white)),
                Text('₺1.299 TL   ₺1.499', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, this.icon, this.active);
  final String text;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? ProtoColors.tan : ProtoColors.surface,
        borderRadius: FRRadii.pill,
        border: Border.all(color: active ? ProtoColors.tan : ProtoColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: active ? ProtoColors.bgPrimary : ProtoColors.textSecondary),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? ProtoColors.bgPrimary : ProtoColors.textSecondary)),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner(this.tag, this.title, this.desc, this.colors);
  final String tag;
  final String title;
  final String desc;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: FRRadii.xl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tag, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ]),
    );
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion(this.icon, this.name, this.reason, this.price, this.tone);
  final String icon;
  final String name;
  final String reason;
  final String price;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return ProtoCard(
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: tone.withOpacity(0.12), borderRadius: FRRadii.md), alignment: Alignment.center, child: Text(icon)),
        const SizedBox(width: 10),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(reason, style: const TextStyle(fontSize: 10, color: ProtoColors.textSubtle)),
        ])),
        RichText(
          text: TextSpan(children: [
            TextSpan(text: price, style: const TextStyle(color: ProtoColors.tan, fontWeight: FontWeight.w800, fontSize: 15)),
            const TextSpan(text: 'TL', style: TextStyle(color: ProtoColors.textSubtle, fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

class _Timer extends StatelessWidget {
  const _Timer(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.22), borderRadius: FRRadii.md),
      child: Column(children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9)),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.active);
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? ProtoColors.tan : ProtoColors.surfaceElevated,
        borderRadius: FRRadii.pill,
      ),
    );
  }
}
