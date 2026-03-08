import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/actual_item_model.dart';
import '../../models/actual_model.dart';
import '../../models/brand_model.dart';
import '../../providers/actual_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/theme.dart';

// --- PREMIUM RENK PALETİ ---
const Color pBrandBrown = Color(0xFF6A442A);
const Color pBrandBrownLight = Color(0x266A442A); // %15 Opacity
const Color pBgApp = Color(0xFFF8F6F4);
const Color pSurface = Color(0xFFFFFFFF);
const Color pStudio = Color(0xFFEBE5DF);
const Color pGold = Color(0xFFC29B78);
const Color pTextMain = Color(0xFF211510);
const Color pTextMuted = Color(0xFF8C7B70);
const Color pAlert = Color(0xFFFF3B30);
const Color pBorder = Color(0x1F6A442A);

class ActualManagementTab extends ConsumerWidget {
  const ActualManagementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actualsAsync = ref.watch(adminActualsProvider);
    final filter = ref.watch(actualAdminFilterProvider);

    // Filtre index'ini belirleme (0: Tümü, 1: Aktif, 2: Pasif)
    int selectedFilterIndex = 0;
    if (filter == true) selectedFilterIndex = 1;
    if (filter == false) selectedFilterIndex = 2;

    return Container(
      color: pBgApp,
      child: Column(
        children: [
          // LÜKS FİLTRE VE EKLEME BARI
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: _PremiumSegmentedControl(
                    labels: const ['Tümü', 'Aktif', 'Pasif'],
                    selectedIndex: selectedFilterIndex,
                    onSelected: (index) {
                      bool? newFilter;
                      if (index == 1) newFilter = true;
                      if (index == 2) newFilter = false;
                      ref.read(actualAdminFilterProvider.notifier).state = newFilter;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _showActualBottomSheet(context, ref),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: pBrandBrown,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: const [BoxShadow(color: Color(0x4D6A442A), blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, color: pSurface, size: 18),
                        SizedBox(width: 4),
                        Text('Ekle', style: TextStyle(color: pSurface, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // LİSTE ALANI
          Expanded(
            child: actualsAsync.when(
              data: (actuals) {
                if (actuals.isEmpty) {
                  return const Center(child: Text('Henüz aktüel kaydı yok.', style: TextStyle(color: pTextMuted)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: actuals.length,
                  itemBuilder: (context, index) {
                    final actual = actuals[index];
                    final date = DateFormat('dd.MM.yyyy').format;
                    final isPasif = !actual.isActive;

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
                        opacity: isPasif ? 0.6 : 1.0,
                        child: Row(
                          children: [
                            // KARTIN SOL KISMI (İçine girilebilir alan)
                            Expanded(
                              child: InkWell(
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => ActualItemsAdminScreen(actual: actual)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44, height: 44,
                                        decoration: BoxDecoration(
                                          color: isPasif ? pStudio : pBrandBrownLight,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(Icons.auto_stories, color: isPasif ? pTextMuted : pBrandBrown, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(actual.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isPasif ? pTextMuted : pTextMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 2),
                                            Text('${actual.marketName} • ${date(actual.startDate)} - ${date(actual.endDate)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isPasif ? pTextMuted.withOpacity(0.8) : pTextMuted)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // KARTIN SAĞ KISMI (Aksiyonlar)
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showActualBottomSheet(context, ref, current: actual),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: pBgApp, borderRadius: BorderRadius.circular(8)),
                                      child: Icon(Icons.edit, size: 18, color: isPasif ? pTextMuted : pBrandBrown),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // ÖZEL KARAMEL SWITCH
                                  Switch.adaptive(
                                    value: actual.isActive,
                                    activeColor: pSurface,
                                    activeTrackColor: pBrandBrown,
                                    inactiveThumbColor: pSurface,
                                    inactiveTrackColor: pStudio,
                                    onChanged: (value) => ref.read(actualAdminDomainServiceProvider).setActualActive(actual.id, value),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: pBrandBrown)),
              error: (_, __) => Center(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: pBrandBrown),
                  onPressed: () => ref.invalidate(adminActualsProvider),
                  child: const Text('Tekrar dene'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- LÜKS BOTTOM SHEET (Dialog Yerine) ---
  Future<void> _showActualBottomSheet(BuildContext context, WidgetRef ref, {ActualModel? current}) async {
    final titleController = TextEditingController(text: current?.title ?? '');
    final coverController = TextEditingController(text: current?.coverImageUrl ?? '');
    final descriptionController = TextEditingController(text: current?.description ?? '');
    DateTime startDate = current?.startDate ?? DateTime.now();
    DateTime endDate = current?.endDate ?? DateTime.now().add(const Duration(days: 7));
    bool isActive = current?.isActive ?? true;
    String? selectedMarketId = current?.marketId;
    String? selectedMarketName = current?.marketName;

    final markets = await ref.read(allBrandsProvider.future);
    if ((selectedMarketId ?? '').isEmpty && markets.isNotEmpty) {
      selectedMarketId = markets.first.id;
      selectedMarketName = markets.first.name;
    }

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> pickDate(bool isStart) async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: isStart ? startDate : endDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(primary: pBrandBrown, onPrimary: pSurface, onSurface: pTextMain),
                ),
                child: child!,
              ),
            );
            if (picked == null) return;
            setState(() {
              if (isStart) {
                startDate = picked;
                if (endDate.isBefore(startDate)) endDate = startDate;
              } else {
                endDate = picked;
              }
            });
          }

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            decoration: const BoxDecoration(
              color: pBgApp,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              children: [
                // Modal Handle
                Container(width: 40, height: 4, decoration: BoxDecoration(color: pBorder, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Text(current == null ? 'Aktüel Ekle' : 'Aktüel Düzenle', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: pTextMain)),
                const SizedBox(height: 24),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Şık Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: pBorder)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedMarketId,
                              icon: const Icon(Icons.expand_more, color: pTextMuted),
                              items: markets.map((brand) => DropdownMenuItem(value: brand.id, child: Text(brand.name, style: const TextStyle(fontWeight: FontWeight.w600, color: pTextMain)))).toList(),
                              onChanged: (value) {
                                final market = markets.firstWhere((m) => m.id == value);
                                setState(() {
                                  selectedMarketId = value;
                                  selectedMarketName = market.name;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PremiumTextInput(controller: titleController, hint: 'Başlık (Örn: Haftanın Yıldızları)'),
                        const SizedBox(height: 12),
                        _PremiumTextInput(controller: coverController, hint: 'Kapak Görsel URL'),
                        const SizedBox(height: 12),
                        _PremiumTextInput(controller: descriptionController, hint: 'Açıklama (Opsiyonel)', maxLines: 2),
                        const SizedBox(height: 16),
                        
                        // Lüks Tarih Seçici Satırı
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => pickDate(true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: pBorder)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.event, size: 16, color: pBrandBrown),
                                      const SizedBox(width: 6),
                                      Text(DateFormat('dd.MM.yyyy').format(startDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: pBrandBrown)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.arrow_forward, color: pTextMuted, size: 16)),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => pickDate(false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: pBorder)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.event, size: 16, color: pBrandBrown),
                                      const SizedBox(width: 6),
                                      Text(DateFormat('dd.MM.yyyy').format(endDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: pBrandBrown)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Aktif/Pasif Kutusu
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: pBorder)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Aktif / Yayında', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: pTextMain)),
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
                      ],
                    ),
                  ),
                ),
                
                // Kaydet Butonu
                GestureDetector(
                  onTap: () async {
                    if (selectedMarketId == null || titleController.text.trim().isEmpty || coverController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Zorunlu alanları doldurun.', style: TextStyle(color: pSurface)), backgroundColor: pBrandBrown));
                      return;
                    }
                    final now = DateTime.now();
                    final payload = {
                      'marketId': selectedMarketId,
                      'marketName': selectedMarketName ?? '',
                      'title': titleController.text.trim(),
                      'startDate': startDate,
                      'endDate': endDate,
                      'coverImageUrl': coverController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'isActive': isActive,
                    };

                    if (current == null) {
                      final actual = ActualModel(
                        id: '',
                        title: payload['title']! as String,
                        marketId: payload['marketId']! as String,
                        marketName: payload['marketName']! as String,
                        startDate: payload['startDate']! as DateTime,
                        endDate: payload['endDate']! as DateTime,
                        coverImageUrl: payload['coverImageUrl']! as String,
                        description: payload['description']! as String,
                        isActive: payload['isActive']! as bool,
                        createdAt: now,
                        updatedAt: now,
                      );
                      await ref.read(actualAdminDomainServiceProvider).addActual(actual);
                    } else {
                      await ref.read(actualAdminDomainServiceProvider).updateActual(current.id, payload);
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
          );
        },
      ),
    );
  }
}

// ==============================================================================
// ALT SAYFA: AKTÜEL ÜRÜNLERİ LİSTESİ (Sub-page)
// ==============================================================================
class ActualItemsAdminScreen extends ConsumerWidget {
  const ActualItemsAdminScreen({super.key, required this.actual});

  final ActualModel actual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(adminActualItemsProvider(actual.id));
    
    return Scaffold(
      backgroundColor: pBgApp,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Lüks Alt Sayfa Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(100), border: Border.all(color: pBorder)),
                      child: const Row(
                        children: [
                          Icon(Icons.chevron_left, color: pBrandBrown, size: 20),
                          SizedBox(width: 4),
                          Text('Geri', style: TextStyle(color: pBrandBrown, fontWeight: FontWeight.w800, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text(actual.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: pTextMain), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
            
            // Geniş Ürün Ekle Butonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => _showItemBottomSheet(context, ref),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(color: pBrandBrownLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: pBrandBrown, style: BorderStyle.solid, width: 1.5)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, color: pBrandBrown, size: 20),
                      SizedBox(width: 8),
                      Text('Bu Kataloğa Ürün Ekle', style: TextStyle(color: pBrandBrown, fontSize: 14, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Ürün Listesi
            Expanded(
              child: itemsAsync.when(
                data: (items) {
                  if (items.isEmpty) return const Center(child: Text('Bu aktüelde henüz ürün yok.', style: TextStyle(color: pTextMuted)));
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isPasif = !item.isActive;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: pSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: pBorder),
                          boxShadow: const [BoxShadow(color: Color(0x0A6A442A), blurRadius: 15, offset: Offset(0, 4))],
                        ),
                        child: Opacity(
                          opacity: isPasif ? 0.6 : 1.0,
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(color: pStudio, borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.shopping_bag_outlined, color: pTextMuted, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: pTextMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text('₺${item.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: pBrandBrown)),
                                        if (item.oldPrice != null && item.oldPrice! > 0) ...[
                                          const SizedBox(width: 6),
                                          Text('₺${item.oldPrice!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pTextMuted, decoration: TextDecoration.lineThrough)),
                                        ]
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showItemBottomSheet(context, ref, item: item),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: pBgApp, borderRadius: BorderRadius.circular(10)),
                                      child: const Icon(Icons.edit, size: 18, color: pBrandBrown),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => ref.read(actualAdminDomainServiceProvider).deleteActualItem(actual.id, item.id),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: pAlert.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                      child: const Icon(Icons.delete_outline, size: 18, color: pAlert),
                                    ),
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
                loading: () => const Center(child: CircularProgressIndicator(color: pBrandBrown)),
                error: (_, __) => Center(child: FilledButton(style: FilledButton.styleFrom(backgroundColor: pBrandBrown), onPressed: () => ref.invalidate(adminActualItemsProvider(actual.id)), child: const Text('Tekrar dene'))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LÜKS BOTTOM SHEET (Ürün Ekleme/Düzenleme) ---
  Future<void> _showItemBottomSheet(BuildContext context, WidgetRef ref, {ActualItemModel? item}) async {
    final nameController = TextEditingController(text: item?.name ?? '');
    final priceController = TextEditingController(text: item == null ? '' : item.price.toString());
    final oldPriceController = TextEditingController(text: item?.oldPrice?.toString() ?? '');
    final imageController = TextEditingController(text: item?.imageUrl ?? '');
    final noteController = TextEditingController(text: item?.note ?? '');
    bool isActive = item?.isActive ?? true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom), // Klavye açılınca yukarı kaysın
          child: Container(
            decoration: const BoxDecoration(color: pBgApp, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: pBorder, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  Text(item == null ? 'Ürün Ekle' : 'Ürün Düzenle', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: pTextMain)),
                  const SizedBox(height: 24),
                  
                  _PremiumTextInput(controller: nameController, hint: 'Ürün Adı'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _PremiumTextInput(controller: priceController, hint: 'Fiyat (₺)', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                      const SizedBox(width: 12),
                      Expanded(child: _PremiumTextInput(controller: oldPriceController, hint: 'Eski Fiyat (Opsiyonel)', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PremiumTextInput(controller: imageController, hint: 'Görsel URL (Opsiyonel)'),
                  const SizedBox(height: 12),
                  _PremiumTextInput(controller: noteController, hint: 'Not (Opsiyonel)'),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: pBorder)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Aktif / Yayında', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: pTextMain)),
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
                      final price = double.tryParse(priceController.text.replaceAll(',', '.'));
                      final oldPrice = double.tryParse(oldPriceController.text.replaceAll(',', '.'));
                      if (nameController.text.trim().isEmpty || price == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ürün adı ve fiyat zorunludur.', style: TextStyle(color: pSurface)), backgroundColor: pBrandBrown));
                        return;
                      }

                      final payload = {
                        'name': nameController.text.trim(),
                        'price': price,
                        'oldPrice': oldPrice,
                        'imageUrl': imageController.text.trim(),
                        'note': noteController.text.trim(),
                        'isActive': isActive,
                      };

                      if (item == null) {
                        await ref.read(actualAdminDomainServiceProvider).addActualItem(
                              actual.id,
                              ActualItemModel(
                                id: '',
                                name: payload['name']! as String,
                                price: payload['price']! as double,
                                oldPrice: payload['oldPrice'] as double?,
                                imageUrl: payload['imageUrl']! as String,
                                note: payload['note']! as String,
                                type: '',
                                category: '',
                                isActive: payload['isActive']! as bool,
                                createdAt: DateTime.now(),
                              ),
                            );
                      } else {
                        await ref.read(actualAdminDomainServiceProvider).updateActualItem(actual.id, item.id, payload);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(color: pBrandBrown, borderRadius: BorderRadius.circular(100), boxShadow: const [BoxShadow(color: Color(0x666A442A), blurRadius: 20, offset: Offset(0, 8))]),
                      alignment: Alignment.center,
                      child: const Text('Ürünü Kaydet', style: TextStyle(color: pSurface, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
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
}

// --- YARDIMCI WIDGETLAR ---

class _PremiumSegmentedControl extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _PremiumSegmentedControl({required this.labels, required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: pStudio, borderRadius: BorderRadius.circular(100), border: Border.all(color: pBorder)),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? pSurface : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: isSelected ? const [BoxShadow(color: Color(0x146A442A), blurRadius: 8, offset: Offset(0, 2))] : [],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSelected) const Icon(Icons.check, size: 14, color: pBrandBrown),
                    if (isSelected) const SizedBox(width: 4),
                    Text(labels[index], style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? pTextMain : pTextMuted)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PremiumTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _PremiumTextInput({required this.controller, required this.hint, this.maxLines = 1, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: pBorder)),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: pTextMain),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: pTextMuted, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
