import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/banner_model.dart';
import '../../../models/campaign_basket_model.dart';
import '../../../models/product_model.dart';
import '../../../providers/banner_provider.dart';
import '../../../providers/campaign_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../utils/theme.dart';

// --- PREMIUM RENK PALETİ ---
const Color pBrandBrown = Color(0xFF6A442A);
const Color pBrandBrownLight = Color(0x266A442A); // %15 Opacity
const Color pBgApp = Color(0xFFF8F6F4);
const Color pSurface = Color(0xFFFFFFFF);
const Color pStudio = Color(0xFFEBE5DF);
const Color pTextMain = Color(0xFF211510);
const Color pTextMuted = Color(0xFF8C7B70);
const Color pAlert = Color(0xFFFF3B30);
const Color pAlertLight = Color(0x1AFF3B30);
const Color pSuccess = Color(0xFF34C759);
const Color pSuccessLight = Color(0x2634C759);
const Color pBorder = Color(0x1F6A442A);

// ---------------------------------------------------------------------------
// ANA WIDGET: PAZARLAMA YÖNETİMİ (Bannerlar + Kampanyalar)
// ---------------------------------------------------------------------------
class AdminMarketingTab extends ConsumerStatefulWidget {
  const AdminMarketingTab({super.key});

  @override
  ConsumerState<AdminMarketingTab> createState() => _AdminMarketingTabState();
}

class _AdminMarketingTabState extends ConsumerState<AdminMarketingTab> {
  int _selectedIndex = 0; // 0: Bannerlar, 1: Kampanyalar

  @override
  Widget build(BuildContext context) {
    return Container(
      color: pBgApp,
      child: Column(
        children: [
          // 💥 1. LÜKS SEGMENT VE EKLE BUTONU 💥
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: pStudio, borderRadius: BorderRadius.circular(100), border: Border.all(color: pBorder)),
                    child: Row(
                      children: [
                        _buildSegmentBtn('Bannerlar', 0),
                        _buildSegmentBtn('Kampanyalar', 1),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (_selectedIndex == 0) {
                      _showBannerBottomSheet(context, ref);
                    } else {
                      final products = ref.read(allProductsProvider).valueOrNull ?? [];
                      _showCampaignBottomSheet(context, ref, products: products);
                    }
                  },
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: pBrandBrown, borderRadius: BorderRadius.circular(100), boxShadow: const [BoxShadow(color: Color(0x4D6A442A), blurRadius: 10, offset: Offset(0, 4))]),
                    child: Row(
                      children: [
                        const Icon(Icons.add, color: pSurface, size: 18),
                        const SizedBox(width: 4),
                        Text(_selectedIndex == 0 ? 'Banner Ekle' : 'Kampanya Ekle', style: const TextStyle(color: pSurface, fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 💥 2. DİNAMİK İÇERİK ALANI 💥
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedIndex == 0 ? _buildBannersView(ref) : _buildCampaignsView(ref),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentBtn(String title, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? pSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            boxShadow: isSelected ? const [BoxShadow(color: Color(0x146A442A), blurRadius: 8, offset: Offset(0, 2))] : [],
          ),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? pTextMain : pTextMuted)),
        ),
      ),
    );
  }

  // =========================================================================
  // BANNERLAR GÖRÜNÜMÜ (Sinematik Kartlar)
  // =========================================================================
  Widget _buildBannersView(WidgetRef ref) {
    final bannersAsync = ref.watch(allBannersProvider);

    return bannersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: pBrandBrown)),
      error: (_, __) => const Center(child: Text('Bannerlar yüklenemedi', style: TextStyle(color: pAlert))),
      data: (banners) {
        if (banners.isEmpty) {
          return const Center(child: Text('Henüz banner yok.', style: TextStyle(color: pTextMuted, fontWeight: FontWeight.w600)));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: banners.length,
          itemBuilder: (context, index) {
            final banner = banners[index];
            final isActive = banner.isActive;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: pSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: pBorder),
                boxShadow: const [BoxShadow(color: Color(0x0A6A442A), blurRadius: 15, offset: Offset(0, 4))],
              ),
              child: Opacity(
                opacity: isActive ? 1.0 : 0.6,
                child: Column(
                  children: [
                    // Görsel Kısmı (Üst)
                    SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                            child: banner.imageUrl.isNotEmpty
                                ? Image.network(banner.imageUrl, fit: BoxFit.cover, errorBuilder: (_,__,___)=> Container(color: pStudio, child: const Icon(Icons.image_not_supported, color: pTextMuted)))
                                : Container(color: pStudio, child: const Icon(Icons.image, color: pTextMuted, size: 40)),
                          ),
                          // Statü Rozeti (Cam Efektli)
                          Positioned(
                            top: 12, left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: isActive ? pSuccessLight.withOpacity(0.8) : pStudio.withOpacity(0.8), borderRadius: BorderRadius.circular(100), border: Border.all(color: isActive ? pSuccess.withOpacity(0.3) : pBorder)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(isActive ? Icons.visibility : Icons.visibility_off, color: isActive ? pSuccess : pTextMuted, size: 14),
                                  const SizedBox(width: 4),
                                  Text(isActive ? 'Yayında' : 'Gizli', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isActive ? pSuccess : pTextMuted)),
                                ],
                              ),
                            ),
                          ),
                          // Aksiyon İkonları (Sağ Üst)
                          Positioned(
                            top: 12, right: 12,
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _showBannerBottomSheet(context, ref, banner: banner),
                                  child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]), child: const Icon(Icons.edit, size: 16, color: pTextMain)),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => ref.read(bannerNotifierProvider.notifier).deleteBanner(banner.id),
                                  child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]), child: const Icon(Icons.delete, size: 16, color: pAlert)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bilgi ve Switch (Alt)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(banner.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isActive ? pTextMain : pTextMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text('Hedef: ${banner.targetType ?? 'Yok'} • ${banner.targetId ?? '-'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pTextMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: isActive,
                            activeColor: pSurface,
                            activeTrackColor: pBrandBrown,
                            inactiveThumbColor: pSurface,
                            inactiveTrackColor: pStudio,
                            onChanged: (val) => ref.read(bannerNotifierProvider.notifier).toggleBannerActive(banner.id, val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // KAMPANYALAR GÖRÜNÜMÜ
  // =========================================================================
  Widget _buildCampaignsView(WidgetRef ref) {
    final campaignsAsync = ref.watch(allCampaignsProvider);
    final productsAsync = ref.watch(allProductsProvider);

    return campaignsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: pBrandBrown)),
      error: (_, __) => const Center(child: Text('Kampanyalar yüklenemedi', style: TextStyle(color: pAlert))),
      data: (campaigns) {
        final products = productsAsync.valueOrNull ?? [];
        if (campaigns.isEmpty) {
          return const Center(child: Text('Henüz kampanya yok.', style: TextStyle(color: pTextMuted, fontWeight: FontWeight.w600)));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: campaigns.length,
          itemBuilder: (context, index) {
            final c = campaigns[index];
            final isActive = c.isActive;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: pBorder), boxShadow: const [BoxShadow(color: Color(0x0A6A442A), blurRadius: 15, offset: Offset(0, 4))]),
              child: Opacity(
                opacity: isActive ? 1.0 : 0.6,
                child: Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: pBrandBrownLight, borderRadius: BorderRadius.circular(14)),
                      child: c.imageUrl != null && c.imageUrl!.isNotEmpty
                          ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(c.imageUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___)=> const Icon(Icons.celebration, color: pBrandBrown)))
                          : const Icon(Icons.celebration, color: pBrandBrown, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isActive ? pTextMain : pTextMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isActive ? pSuccessLight : pStudio, borderRadius: BorderRadius.circular(6)), child: Text(isActive ? 'Aktif' : 'Pasif', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isActive ? pSuccess : pTextMuted))),
                              const SizedBox(width: 6),
                              Text('${c.itemProductIds.length} Ürün', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pTextMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showCampaignBottomSheet(context, ref, products: products, campaign: c),
                          child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: pBgApp, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.edit, size: 18, color: pBrandBrown)),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => ref.read(adminCampaignManagementDomainServiceProvider).deleteCampaign(c.id),
                          child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: pAlertLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.delete_outline, size: 18, color: pAlert)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // BOTTOM SHEETS (FORM MODALLARI)
  // =========================================================================

  Future<void> _showBannerBottomSheet(BuildContext context, WidgetRef ref, {BannerModel? banner}) async {
    final badgeTextController = TextEditingController(text: banner?.badgeText ?? '');
    final titleController = TextEditingController(text: banner?.title ?? '');
    final descriptionController = TextEditingController(text: banner?.description ?? '');
    final imageUrlController = TextEditingController(text: banner?.imageUrl ?? '');
    final ctaController = TextEditingController(text: banner?.ctaText ?? 'Keşfet');

    String selectedTargetType = 'campaign';
    String? selectedCampaignId = banner?.targetId;
    bool isActive = banner?.isActive ?? true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final campaignsAsync = ref.watch(activeCampaignsProvider);
          return StatefulBuilder(
            builder: (ctx, setState) => Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(ctx).size.height * 0.85,
                decoration: const BoxDecoration(color: pBgApp, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: pBorder, borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 20),
                      Center(child: Text(banner == null ? 'Banner Ekle' : 'Banner Düzenle', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: pTextMain))),
                      const SizedBox(height: 24),

                      _PremiumInput(icon: Icons.sell_outlined, hint: 'Etiket / Rozet Yazısı (Örn: Topluluk, Kampanya)', controller: badgeTextController),
                      const SizedBox(height: 12),
                      _PremiumInput(icon: Icons.title, hint: 'Başlık', controller: titleController),
                      const SizedBox(height: 12),
                      _PremiumInput(icon: Icons.link, hint: 'Görsel URL', controller: imageUrlController),
                      const SizedBox(height: 12),
                      _PremiumInput(icon: Icons.smart_button, hint: 'CTA Buton Yazısı (Örn: Keşfet)', controller: ctaController),
                      const SizedBox(height: 12),
                      _PremiumInput(icon: Icons.description, hint: 'Açıklama (Opsiyonel)', controller: descriptionController, maxLines: 2),
                      const SizedBox(height: 24),

                      const Text('Hedef (Tıklanınca nereye gidecek?)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: pTextMuted)),
                      const SizedBox(height: 8),
                      
                      // Hedef Kampanya Seçici
                      campaignsAsync.when(
                        data: (campaigns) {
                          if(campaigns.isEmpty) return const Text('Aktif kampanya bulunamadı.', style: TextStyle(color: pAlert, fontSize: 12));
                          return Wrap(
                            spacing: 8, runSpacing: 8,
                            children: campaigns.take(8).map((c) {
                              final isSelected = selectedCampaignId == c.id;
                              return GestureDetector(
                                onTap: () => setState(() => selectedCampaignId = c.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: isSelected ? pBrandBrown : pSurface, border: Border.all(color: isSelected ? pBrandBrown : pBorder), borderRadius: BorderRadius.circular(100)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if(isSelected) const Icon(Icons.check, color: pSurface, size: 14),
                                      if(isSelected) const SizedBox(width: 4),
                                      Text(c.title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSelected ? pSurface : pTextMuted)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const CircularProgressIndicator(strokeWidth: 2),
                        error: (_,__) => const SizedBox(),
                      ),
                      const SizedBox(height: 24),

                      // Sistemde Yayında Switch'i
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: pBorder)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Sistemde Yayında', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: pTextMain)),
                            Switch.adaptive(value: isActive, activeColor: pSurface, activeTrackColor: pBrandBrown, inactiveThumbColor: pSurface, inactiveTrackColor: pStudio, onChanged: (v) => setState(() => isActive = v)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      GestureDetector(
                        onTap: () async {
                          if (titleController.text.trim().isEmpty) return;
                          final payload = {
                            'badgeText': badgeTextController.text.trim().isEmpty ? null : badgeTextController.text.trim(),
                            'title': titleController.text.trim(),
                            'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                            'imageUrl': imageUrlController.text.trim(),
                            'ctaText': ctaController.text.trim().isEmpty ? 'Keşfet' : ctaController.text.trim(),
                            'targetType': selectedTargetType,
                            'targetId': selectedTargetType == 'campaign' ? selectedCampaignId : null,
                            'isActive': isActive,
                            'order': banner?.order ?? 0,
                            'aspectRatio': 'wide',
                          };

                          if (banner == null) {
                            final model = BannerModel(id: '', badgeText: payload['badgeText'] as String?, title: payload['title']! as String, description: payload['description'] as String?, imageUrl: payload['imageUrl']! as String, targetType: payload['targetType']! as String, targetId: payload['targetId'] as String?, ctaText: payload['ctaText']! as String, aspectRatio: 'wide', isActive: isActive, createdAt: DateTime.now());
                            await ref.read(adminBannerManagementDomainServiceProvider).addBanner(model);
                          } else {
                            await ref.read(adminBannerManagementDomainServiceProvider).updateBanner(banner.id, payload);
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18), decoration: BoxDecoration(color: pBrandBrown, borderRadius: BorderRadius.circular(100)), alignment: Alignment.center, child: const Text('Bannerı Kaydet', style: TextStyle(color: pSurface, fontSize: 16, fontWeight: FontWeight.w800))),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCampaignBottomSheet(BuildContext context, WidgetRef ref, {required List<ProductModel> products, CampaignBasketModel? campaign}) async {
    final titleController = TextEditingController(text: campaign?.title ?? '');
    final descriptionController = TextEditingController(text: campaign?.description ?? '');
    final imageUrlController = TextEditingController(text: campaign?.imageUrl ?? '');
    bool isActive = campaign?.isActive ?? true;
    final selectedIds = <String>{...?campaign?.itemProductIds};
    String searchQuery = '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          // Arama Filtresi
          final filtered = products.where((p) {
            if (searchQuery.trim().isEmpty) return true;
            final q = searchQuery.toLowerCase();
            return p.name.toLowerCase().contains(q) || p.brand.toLowerCase().contains(q) || (p.barcode?.contains(searchQuery) ?? false);
          }).take(30).toList();

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.88, // Yüksek modal (ürün listesi için)
              decoration: const BoxDecoration(color: pBgApp, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: pBorder, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  Text(campaign == null ? 'Kampanya Ekle' : 'Kampanya Düzenle', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: pTextMain)),
                  const SizedBox(height: 16),

                  // Temel Bilgiler
                  _PremiumInput(icon: Icons.title, hint: 'Kampanya Adı', controller: titleController),
                  const SizedBox(height: 8),
                  _PremiumInput(icon: Icons.link, hint: 'Görsel URL (Opsiyonel)', controller: imageUrlController),
                  const SizedBox(height: 16),

                  // Seçili Ürünler (Haplar)
                  if (selectedIds.isNotEmpty) ...[
                    Align(alignment: Alignment.centerLeft, child: Text('Seçili Ürünler (${selectedIds.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: pTextMuted))),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 80),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6, runSpacing: 6,
                          children: selectedIds.map((id) {
                            final p = products.firstWhere((prod) => prod.id == id, orElse: () => ProductModel(id: id, name: 'Bilinmiyor', brand: '', categories: [], createdAt: DateTime.now(), updatedAt: DateTime.now()));
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: pBrandBrown, borderRadius: BorderRadius.circular(100)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(p.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: pSurface)),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => setState(() => selectedIds.remove(id)),
                                    child: const Icon(Icons.close, size: 14, color: pSurface),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Arama Kutusu
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: pBrandBrown.withOpacity(0.5))),
                    child: TextField(
                      onChanged: (v) => setState(() => searchQuery = v),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: pTextMain),
                      decoration: const InputDecoration(border: InputBorder.none, hintText: 'Ürün Ara (Nutella, Fairy vs.)', hintStyle: TextStyle(color: pTextMuted, fontWeight: FontWeight.w500), icon: Icon(Icons.search, color: pBrandBrown, size: 20)),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Arama Sonuçları Listesi
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: pBorder)),
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_,__) => Container(height: 1, color: pStudio),
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          final isSelected = selectedIds.contains(p.id);
                          return ListTile(
                            dense: true,
                            title: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: pTextMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(p.brand, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: pTextMuted)),
                            trailing: Icon(isSelected ? Icons.check_circle : Icons.add_circle_outline, color: isSelected ? pBrandBrown : pTextMuted),
                            onTap: () => setState(() {
                              isSelected ? selectedIds.remove(p.id) : selectedIds.add(p.id);
                            }),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Kaydet Butonu
                  GestureDetector(
                    onTap: () async {
                      if (titleController.text.trim().isEmpty) return;
                      final data = {
                        'title': titleController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'imageUrl': imageUrlController.text.trim().isEmpty ? null : imageUrlController.text.trim(),
                        'isActive': isActive,
                        'itemProductIds': selectedIds.toList(),
                      };

                      if (campaign == null) {
                        await ref.read(adminCampaignManagementDomainServiceProvider).addCampaign(CampaignBasketModel(id: '', title: titleController.text.trim(), description: descriptionController.text.trim(), imageUrl: imageUrlController.text.trim().isEmpty ? null : imageUrlController.text.trim(), isActive: isActive, itemProductIds: selectedIds.toList(), createdAt: DateTime.now(), updatedAt: DateTime.now()));
                      } else {
                        await ref.read(adminCampaignManagementDomainServiceProvider).updateCampaign(campaign.id, data);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18), decoration: BoxDecoration(color: pBrandBrown, borderRadius: BorderRadius.circular(100)), alignment: Alignment.center, child: const Text('Kampanyayı Kaydet', style: TextStyle(color: pSurface, fontSize: 16, fontWeight: FontWeight.w800))),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// YARDIMCI WIDGET: PREMIUM INPUT
// ---------------------------------------------------------------------------
class _PremiumInput extends StatelessWidget {
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final int maxLines;

  const _PremiumInput({required this.icon, required this.hint, required this.controller, this.maxLines = 1});

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
              maxLines: maxLines,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: pTextMain),
              decoration: InputDecoration(border: InputBorder.none, hintText: hint, hintStyle: const TextStyle(color: pTextMuted, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}
