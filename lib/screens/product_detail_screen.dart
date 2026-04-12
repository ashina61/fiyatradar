import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import '../widgets/prototype_ui.dart';
import 'main_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final isFav = state.isFavorite(product.id);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Ürün Detay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  const Icon(Icons.share, color: ProtoColors.textSecondary, size: 20),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            borderRadius: FRRadii.xxl,
                            border: Border.all(color: ProtoColors.border),
                            gradient: const LinearGradient(colors: [ProtoColors.surface, ProtoColors.surfaceAlt]),
                          ),
                          alignment: Alignment.center,
                          child: Text(product.emoji, style: const TextStyle(fontSize: 72)),
                        ),
                        const SizedBox(height: 16),
                        Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text('${product.brand} • ${product.category}', style: const TextStyle(fontSize: 13, color: ProtoColors.textSubtle)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                          decoration: protoSurface(radius: ProtoRadius.pill),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: ProtoColors.tan, size: 14),
                              SizedBox(width: 4),
                              Text('4.3', style: TextStyle(color: ProtoColors.tan, fontWeight: FontWeight.w700, fontSize: 12)),
                              SizedBox(width: 5),
                              Text('• 128 yorum', style: TextStyle(color: ProtoColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: FRRadii.xl,
                      border: Border.all(color: ProtoColors.tan.withOpacity(0.25)),
                      gradient: const LinearGradient(colors: [ProtoColors.surfaceAlt, ProtoColors.surface]),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.workspace_premium, size: 13, color: ProtoColors.tan),
                            SizedBox(width: 5),
                            Text('En İyi Fiyat', style: TextStyle(fontSize: 11, color: ProtoColors.tan, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('₺${(product.lowestPrice ?? 1299).toStringAsFixed(0)}', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1)),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: protoSurface(radius: ProtoRadius.pill),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.storefront, size: 13, color: ProtoColors.textSecondary),
                              SizedBox(width: 6),
                              Text('Trendyol', style: TextStyle(fontSize: 12, color: ProtoColors.textSecondary)),
                              SizedBox(width: 8),
                              SizedBox(width: 1, height: 10, child: DecoratedBox(decoration: BoxDecoration(color: Color(0x33FFFFFF)))),
                              SizedBox(width: 8),
                              Icon(Icons.access_time, size: 13, color: ProtoColors.textSecondary),
                              SizedBox(width: 4),
                              Text('2s önce', style: TextStyle(fontSize: 12, color: ProtoColors.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: ProtoColors.success, borderRadius: FRRadii.pill),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.white, size: 13),
                              SizedBox(width: 5),
                              Text('Doğrulandı', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 38,
                                child: FilledButton.icon(
                                  onPressed: () => state.toggleFavorite(product.id),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: ProtoColors.tan,
                                    foregroundColor: ProtoColors.bgPrimary,
                                    shape: RoundedRectangleBorder(borderRadius: FRRadii.md),
                                  ),
                                  icon: Icon(isFav ? Icons.star : Icons.star_border, size: 14),
                                  label: const Text('Listeye Ekle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 38,
                                child: OutlinedButton.icon(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: ProtoColors.border),
                                    shape: RoundedRectangleBorder(borderRadius: FRRadii.md),
                                  ),
                                  icon: const Icon(Icons.notifications_none, size: 14),
                                  label: const Text('Alarm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    padding: const EdgeInsets.all(18),
                    decoration: protoSurface(radius: ProtoRadius.lg),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [Icon(Icons.check_circle, color: ProtoColors.success, size: 16), SizedBox(width: 8), Text('Fiyat Doğrulama', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))]),
                      const SizedBox(height: 14),
                      const Row(
                        children: [
                          Expanded(child: _VerifyStat('47', 'Doğru', ProtoColors.success)),
                          Expanded(child: _VerifyStat('3', 'Yanlış', ProtoColors.danger)),
                          Expanded(child: _VerifyStat('50', 'Toplam Oy', ProtoColors.tan)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(children: const [Expanded(child: _Vote('Doğru', true)), SizedBox(width: 10), Expanded(child: _Vote('Yanlış', false))]),
                    ]),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    padding: const EdgeInsets.all(18),
                    decoration: protoSurface(radius: ProtoRadius.lg),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
                        Row(children: [Icon(Icons.shield, size: 15, color: ProtoColors.success), SizedBox(width: 6), Text('Güven Analizi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))]),
                        Row(children: [Text('94%', style: TextStyle(fontSize: 18, color: ProtoColors.success, fontWeight: FontWeight.w700)), SizedBox(width: 4), Text('Güvenilir', style: TextStyle(fontSize: 10, color: ProtoColors.textSubtle))]),
                      ]),
                      const SizedBox(height: 14),
                      const Row(children: [Expanded(child: _Trust('✓', 'Doğrulanmış', 'Topluluk onayı')), Expanded(child: _Trust('⚡', 'Canlı Veri', 'Son 5 dakika'))]),
                      const SizedBox(height: 10),
                      const Row(children: [Expanded(child: _Trust('📈', 'Trend', 'Ortalamadan %12 düşük')), Expanded(child: _Trust('👥', 'Kaynak', '12 farklı platform'))]),
                    ]),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    padding: const EdgeInsets.all(18),
                    decoration: protoSurface(radius: ProtoRadius.lg),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
                        Text('30 Günlük Değişim', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        _ChartFilter(),
                      ]),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 100,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            _Bar(0.40, false),
                            _Bar(0.55, false),
                            _Bar(0.45, false),
                            _Bar(0.70, false),
                            _Bar(0.60, false),
                            _Bar(0.80, true),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: Column(
                      children: const [
                        _Seller('H', 'Hepsiburada', '91% Güven • 5s önce', '₺1.349', '+₺50'),
                        _Seller('A', 'Amazon', '96% Güven • 1s önce', '₺1.399', '+₺100'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, ProtoColors.bgPrimary]),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: ProtoColors.border),
                          shape: RoundedRectangleBorder(borderRadius: FRRadii.lg),
                        ),
                        icon: const Icon(Icons.notifications_none),
                        label: const Text('Alarm', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: ProtoColors.tan,
                          foregroundColor: ProtoColors.bgPrimary,
                          shape: RoundedRectangleBorder(borderRadius: FRRadii.lg),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Fiyat Ekle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
}

class _VerifyStat extends StatelessWidget {
  const _VerifyStat(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, color: color, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(fontSize: 10, color: ProtoColors.textSubtle, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ChartFilter extends StatelessWidget {
  const _ChartFilter();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Text('7G', style: TextStyle(fontSize: 10, color: ProtoColors.textSubtle, fontWeight: FontWeight.w600)),
      const SizedBox(width: 5),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: ProtoColors.surfaceAlt, borderRadius: FRRadii.sm),
        child: const Text('30G', style: TextStyle(fontSize: 10, color: ProtoColors.tan, fontWeight: FontWeight.w600)),
      ),
      const SizedBox(width: 5),
      const Text('90G', style: TextStyle(fontSize: 10, color: ProtoColors.textSubtle, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _Bar extends StatelessWidget {
  const _Bar(this.heightRatio, this.active);
  final double heightRatio;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: Container(
          height: 100 * heightRatio,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            color: active ? null : ProtoColors.surfaceAlt,
            gradient: active ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [ProtoColors.tan, ProtoColors.tanDark]) : null,
            boxShadow: active ? [BoxShadow(color: ProtoColors.tan.withOpacity(0.3), blurRadius: 8)] : null,
          ),
        ),
      ),
    );
  }
}

class _Seller extends StatelessWidget {
  const _Seller(this.logo, this.name, this.meta, this.price, this.diff);
  final String logo;
  final String name;
  final String meta;
  final String price;
  final String diff;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: ProtoColors.borderLight))),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: ProtoColors.surfaceAlt, borderRadius: FRRadii.pill, border: Border.all(color: ProtoColors.border)),
            child: Text(logo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ProtoColors.tan)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(meta, style: const TextStyle(fontSize: 10, color: ProtoColors.textSubtle)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(price, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(diff, style: const TextStyle(fontSize: 10, color: ProtoColors.success, fontWeight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }
}

class _Trust extends StatelessWidget {
  const _Trust(this.icon, this.title, this.desc);
  final String icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: ProtoColors.surfaceAlt, border: Border.all(color: ProtoColors.border), borderRadius: FRRadii.sm),
        child: Text(icon, style: const TextStyle(fontSize: 12)),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          Text(desc, style: const TextStyle(fontSize: 10, color: ProtoColors.textSubtle)),
        ]),
      ),
    ]);
  }
}

class _Vote extends StatelessWidget {
  const _Vote(this.label, this.ok);
  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok ? ProtoColors.success : ProtoColors.danger;
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: FRRadii.md, border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
