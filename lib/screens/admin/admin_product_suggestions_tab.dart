import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
const Color pAlert = Color(0xFFFF3B30);
const Color pAlertLight = Color(0x1AFF3B30);
const Color pBorder = Color(0x1F6A442A);

class AdminProductSuggestionsTab extends ConsumerWidget {
  const AdminProductSuggestionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(pendingProductSuggestionsProvider);

    return Container(
      color: pBgApp,
      child: suggestionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: pBrandBrown)),
        error: (_, __) => const Center(child: Text('Ürün önerileri yüklenemedi', style: TextStyle(color: pAlert))),
        data: (suggestions) {
          if (suggestions.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Text(
                  'Bekleyen Öneriler (${suggestions.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: pBrandBrown),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = suggestions[index];
                    return _PremiumSuggestionCard(suggestion: suggestion);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Jilet gibi Empty State (Boş Durum) Ekranı
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: pStudio,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.done_all, color: pTextMuted, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('Her şey tertemiz!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: pTextMain)),
          const SizedBox(height: 4),
          const Text('Bekleyen ürün önerisi bulunmuyor.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: pTextMuted)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PREMIUM ÖNERİ KARTI (İkiye Bölünmüş Aksiyon Barı ile)
// ---------------------------------------------------------------------------
class _PremiumSuggestionCard extends ConsumerWidget {
  final dynamic suggestion; // Modelin tam adını projene göre ayarlayabilirsin (örn: ProductSuggestionModel)
  const _PremiumSuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: pSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pBorder),
        boxShadow: const [BoxShadow(color: Color(0x0A6A442A), blurRadius: 15, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          // ÜST KISIM: GÖRSEL VE BİLGİLER
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ürün Görseli
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: pStudio,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: pBorder),
                  ),
                  alignment: Alignment.center,
                  child: suggestion.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.network(
                            suggestion.imageUrl, 
                            width: 64, height: 64, fit: BoxFit.cover, 
                            errorBuilder: (_,__,___) => const Icon(Icons.inventory_2, color: pTextMuted)
                          ),
                        )
                      : const Icon(Icons.inventory_2, color: pTextMuted, size: 28),
                ),
                const SizedBox(width: 16),
                // Ürün Bilgileri & Etiketler
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.name.isEmpty ? 'İsimsiz Ürün' : suggestion.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: pTextMain, height: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6, runSpacing: 6,
                        children: [
                          if (suggestion.barcode.isNotEmpty)
                            _InfoPill(icon: Icons.qr_code_2, text: suggestion.barcode),
                          if (suggestion.category.isNotEmpty)
                            _InfoPill(icon: Icons.category, text: suggestion.category),
                          if (suggestion.brand.isNotEmpty)
                            _InfoPill(icon: Icons.branding_watermark, text: suggestion.brand),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // ALT KISIM: 50/50 AKSİYON BARI (Reddet / Onayla)
          Container(
            height: 48,
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: pBorder))),
            child: Row(
              children: [
                // Reddet Butonu
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20)),
                      onTap: () async {
                        await ref.read(productSuggestionDomainServiceProvider).rejectProductSuggestion(suggestion.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Öneri reddedildi'), backgroundColor: pAlert, behavior: SnackBarBehavior.floating));
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, color: pAlert, size: 18),
                          SizedBox(width: 6),
                          Text('Reddet', style: TextStyle(color: pAlert, fontSize: 13, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ),
                // Dikey Ayırıcı Çizgi
                Container(width: 1, color: pBorder),
                // Onayla Butonu (Karamel Vurgulu)
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20)),
                      onTap: () async {
                        await ref.read(productSuggestionDomainServiceProvider).approveProductSuggestion(suggestion.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Öneri başarıyla onaylandı', style: TextStyle(color: pSurface)), backgroundColor: pBrandBrown, behavior: SnackBarBehavior.floating));
                        }
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: pBrandBrown, size: 18),
                          SizedBox(width: 6),
                          Text('Onayla', style: TextStyle(color: pBrandBrown, fontSize: 13, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// YARDIMCI WIDGET: Bilgi Hapları (Pills)
// ---------------------------------------------------------------------------
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: pBgApp,
        border: Border.all(color: pBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: pBrandBrown),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: pTextMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
