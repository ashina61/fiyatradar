import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/brand_model.dart';
import '../../providers/product_provider.dart';
import '../../utils/theme.dart';

// --- PREMIUM RENK PALETİ ---
const Color pBrandBrown = Color(0xFF6A442A);
const Color pBrandBrownLight = Color(0x266A442A); // %15 Opacity
const Color pBgApp = Color(0xFFF8F6F4);
const Color pSurface = Color(0xFFFFFFFF);
const Color pStudio = Color(0xFFEBE5DF);
const Color pTextMain = Color(0xFF211510);
const Color pTextMuted = Color(0xFF8C7B70);
const Color pSuccess = Color(0xFF34C759);
const Color pSuccessLight = Color(0x2634C759);
const Color pBorder = Color(0x1F6A442A);

class AdminBrandManagementTab extends ConsumerWidget {
  const AdminBrandManagementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(allBrandsProvider);

    return Container(
      color: pBgApp,
      child: brandsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: pBrandBrown)),
        error: (_, __) => const Center(child: Text('Ana mağazalar yüklenemedi', style: TextStyle(color: pTextMuted))),
        data: (brands) {
          return Column(
            children: [
              // LÜKS ALT HEADER (Başlık ve Ekle Butonu)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kayıtlı Markalar (${brands.length})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: pBrandBrown),
                    ),
                    GestureDetector(
                      onTap: () => _showBrandBottomSheet(context, ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: pBrandBrown,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: const [BoxShadow(color: Color(0x4D6A442A), blurRadius: 10, offset: Offset(0, 4))],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add, color: pSurface, size: 16),
                            SizedBox(width: 4),
                            Text('Marka Ekle', style: TextStyle(color: pSurface, fontWeight: FontWeight.w800, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // LİSTE ALANI
              Expanded(
                child: brands.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: brands.length,
                        itemBuilder: (context, index) {
                          final brand = brands[index];
                          return _PremiumBrandCard(brand: brand);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: pStudio, borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.storefront, color: pTextMuted, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Henüz Marka Yok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: pTextMain)),
          const SizedBox(height: 4),
          const Text('İlk zincir mağazayı ekleyerek başlayın.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: pTextMuted)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PREMIUM KART WIDGET'I
// ---------------------------------------------------------------------------
class _PremiumBrandCard extends ConsumerWidget {
  final BrandModel brand;
  const _PremiumBrandCard({required this.brand});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = brand.isActive;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: pSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pBorder),
        boxShadow: const [BoxShadow(color: Color(0x0A6A442A), blurRadius: 15, offset: Offset(0, 4))],
      ),
      child: Opacity(
        opacity: isActive ? 1.0 : 0.6,
        child: Row(
          children: [
            // Tıklanabilir Sol Kısım (Detaya/Düzenlemeye Gidiş)
            Expanded(
              child: InkWell(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                onTap: () => _showBrandBottomSheet(context, ref, brand: brand),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Squircle (Karesel Yuvarlak) Logo
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: isActive ? pBrandBrownLight : pStudio,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: pBorder),
                        ),
                        alignment: Alignment.center,
                        child: (brand.logoUrl != null && brand.logoUrl!.trim().isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Image.network(
                                  brand.logoUrl!.trim(),
                                  width: 50, height: 50, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(Icons.storefront, color: isActive ? pBrandBrown : pTextMuted),
                                ),
                              )
                            : Text(
                                brand.name.isNotEmpty ? brand.name[0].toUpperCase() : 'M',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isActive ? pBrandBrown : pTextMuted),
                              ),
                      ),
                      const SizedBox(width: 16),
                      // Bilgiler
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(brand.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isActive ? pTextMain : pTextMuted, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            _StatusPill(isActive: isActive),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Sağ Kısım: Aksiyonlar (Edit + Switch)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showBrandBottomSheet(context, ref, brand: brand),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: pBgApp, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.edit, size: 18, color: isActive ? pBrandBrown : pTextMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: isActive,
                    activeColor: pSurface,
                    activeTrackColor: pBrandBrown,
                    inactiveThumbColor: pSurface,
                    inactiveTrackColor: pStudio,
                    onChanged: (value) => ref.read(adminBrandManagementDomainServiceProvider).updateBrand(brand.id, {'isActive': value}),
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

// ---------------------------------------------------------------------------
// LÜKS BOTTOM SHEET (Dialog Yerine)
// ---------------------------------------------------------------------------
Future<void> _showBrandBottomSheet(BuildContext context, WidgetRef ref, {BrandModel? brand}) async {
  final nameController = TextEditingController(text: brand?.name ?? '');
  final logoController = TextEditingController(text: brand?.logoUrl ?? '');
  bool isActive = brand?.isActive ?? true;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: pBgApp, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: pBorder, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Text(brand == null ? 'Marka Ekle' : 'Marka Düzenle', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: pTextMain)),
                const SizedBox(height: 24),

                _PremiumIconInput(icon: Icons.business, hint: 'Mağaza Adı (Örn: BİM)', controller: nameController),
                const SizedBox(height: 12),
                _PremiumIconInput(icon: Icons.link, hint: 'Logo URL (Opsiyonel)', controller: logoController),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: pBorder)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sistemde Aktif', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: pTextMain)),
                      Switch.adaptive(
                        value: isActive,
                        activeColor: pSurface,
                        activeTrackColor: pBrandBrown,
                        inactiveThumbColor: pSurface,
                        inactiveTrackColor: pStudio,
                        onChanged: (value) => setState(() => isActive = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mağaza adı zorunludur.', style: TextStyle(color: pSurface)), backgroundColor: pBrandBrown));
                      return;
                    }
                    if (brand == null) {
                      await ref.read(adminBrandManagementDomainServiceProvider).addBrand(
                        BrandModel(
                          id: '',
                          name: nameController.text.trim(),
                          type: BrandType.chain, // Kendi projendeki BrandType'a göre düzenle
                          logoUrl: logoController.text.trim().isEmpty ? null : logoController.text.trim(),
                          isActive: isActive,
                          createdAt: DateTime.now(),
                        ),
                      );
                    } else {
                      await ref.read(adminBrandManagementDomainServiceProvider).updateBrand(brand.id, {
                        'name': nameController.text.trim(),
                        'logoUrl': logoController.text.trim(),
                        'isActive': isActive,
                      });
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(color: pBrandBrown, borderRadius: BorderRadius.circular(100), boxShadow: const [BoxShadow(color: Color(0x666A442A), blurRadius: 20, offset: Offset(0, 8))]),
                    alignment: Alignment.center,
                    child: const Text('Kaydet', style: TextStyle(color: pSurface, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// YARDIMCI WIDGETLAR
// ---------------------------------------------------------------------------
class _StatusPill extends StatelessWidget {
  final bool isActive;
  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? pSuccessLight : pStudio,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: isActive ? pSuccess.withOpacity(0.2) : pBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isActive ? Icons.check_circle : Icons.cancel, size: 12, color: isActive ? pSuccess : pTextMuted),
          const SizedBox(width: 4),
          Text(isActive ? 'Aktif' : 'Pasif', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isActive ? pSuccess : pTextMuted)),
        ],
      ),
    );
  }
}

class _PremiumIconInput extends StatelessWidget {
  final IconData icon;
  final String hint;
  final TextEditingController controller;

  const _PremiumIconInput({required this.icon, required this.hint, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: pBorder)),
      child: Row(
        children: [
          Icon(icon, color: pTextMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: pTextMain),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(color: pTextMuted, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
