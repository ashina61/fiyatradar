import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Kendi projendeki yolları kontrol et
import '../../models/brand_model.dart';
import '../../models/store_model.dart';
import '../../providers/product_provider.dart';
import '../../utils/theme.dart';

// --- PREMIUM RENK PALETİ ---
const Color pBrandBrown = Color(0xFF6A442A);
const Color pBrandBrownLight = Color(0x266A442A); 
const Color pBgApp = Color(0xFFF8F6F4);
const Color pSurface = Color(0xFFFFFFFF);
const Color pStudio = Color(0xFFEBE5DF);
const Color pTextMain = Color(0xFF211510);
const Color pTextMuted = Color(0xFF8C7B70);
const Color pSuccess = Color(0xFF34C759);
const Color pSuccessLight = Color(0x2634C759);
const Color pWarning = Color(0xFFFF9500);
const Color pAlert = Color(0xFFFF3B30);
const Color pAlertLight = Color(0x1AFF3B30);
const Color pBorder = Color(0x1F6A442A);

class AdminBrandManagementTab extends ConsumerStatefulWidget {
  const AdminBrandManagementTab({super.key});

  @override
  ConsumerState<AdminBrandManagementTab> createState() => _AdminBrandManagementTabState();
}

class _AdminBrandManagementTabState extends ConsumerState<AdminBrandManagementTab> {
  int _selectedIndex = 0; // 0: Markalar, 1: Şubeler
  String _storeStatusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: pBgApp,
      child: Column(
        children: [
          // 💥 1. LÜKS ÜST KONTROL BARI 💥
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
                        _buildSegmentBtn('Markalar', 0),
                        _buildSegmentBtn('Şubeler', 1),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildAddBtn(),
              ],
            ),
          ),

          // 💥 2. ŞUBE FİLTRELERİ (Sadece Şubeler seçiliyse görünür) 💥
          if (_selectedIndex == 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tümü', 'all'),
                    _buildFilterChip('Aktif', 'active'),
                    _buildFilterChip('Bekleyen', 'pending'),
                    _buildFilterChip('Gizli', 'hidden'),
                  ],
                ),
              ),
            ),

          // 💥 3. DİNAMİK İÇERİK ALANI 💥
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedIndex == 0 ? _buildBrandList(ref) : _buildStoreList(ref),
            ),
          ),
        ],
      ),
    );
  }

  // --- YARDIMCI METODLAR ---

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
            boxShadow: isSelected ? const [BoxShadow(color: Color(0x146A442A), blurRadius: 8)] : [],
          ),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? pTextMain : pTextMuted)),
        ),
      ),
    );
  }

  Widget _buildAddBtn() {
    return GestureDetector(
      onTap: () => _selectedIndex == 0 ? _showBrandBottomSheet(context, ref) : _showStoreEditor(context, ref),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: pBrandBrown, borderRadius: BorderRadius.circular(100), boxShadow: const [BoxShadow(color: Color(0x4D6A442A), blurRadius: 10, offset: Offset(0, 4))]),
        child: const Icon(Icons.add, color: pSurface, size: 20),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _storeStatusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _storeStatusFilter = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: isSelected ? pBrandBrown : pSurface, borderRadius: BorderRadius.circular(100), border: Border.all(color: isSelected ? pBrandBrown : pBorder)),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSelected ? pSurface : pTextMuted)),
      ),
    );
  }

  // --- LİSTE GÖRÜNÜMLERİ ---

  Widget _buildBrandList(WidgetRef ref) {
    final brandsAsync = ref.watch(allBrandsProvider);
    return KeyedSubtree(
      key: const ValueKey('brands_list'),
      child: brandsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: pBrandBrown)),
        error: (_, __) => const Center(child: Text('Hata oluştu')),
        data: (brands) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: brands.length,
          itemBuilder: (context, index) => _PremiumBrandCard(brand: brands[index]),
        ),
      ),
    );
  }

  Widget _buildStoreList(WidgetRef ref) {
    final storesAsync = ref.watch(allStoresStreamProvider);
    return KeyedSubtree(
      key: const ValueKey('stores_list'),
      child: storesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: pBrandBrown)),
        error: (_, __) => const Center(child: Text('Hata oluştu')),
        data: (stores) {
          final filtered = _storeStatusFilter == 'all' ? stores : stores.where((s) => s.status.name == _storeStatusFilter).toList();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final store = filtered[index];
              return _PremiumStoreCard(
                store: store,
                allStores: stores,
                onEdit: () => _showStoreEditor(context, ref, store: store),
              );
            },
          );
        },
      ),
    );
  }

  // --- BOTTOM SHEETLER (Kısa versiyonlar) ---
  void _showBrandBottomSheet(BuildContext context, WidgetRef ref, {BrandModel? brand}) { /* Daha önceki lüks marka bottom sheet kodun */ }
  void _showStoreEditor(BuildContext context, WidgetRef ref, {StoreModel? store}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: store?.displayName ?? '');
    final cityController = TextEditingController(text: store?.city ?? '');
    final districtController = TextEditingController(text: store?.district ?? '');
    final neighborhoodController = TextEditingController(text: store?.neighborhood ?? '');
    final addressController = TextEditingController(text: store?.addressText ?? store?.address ?? '');
    final latController = TextEditingController(text: store != null ? store.lat.toString() : '');
    final lngController = TextEditingController(text: store != null ? store.lng.toString() : '');
    final keywordController = TextEditingController(text: store?.searchKeywords.join(', ') ?? '');

    var selectedType = store?.storeType ?? (store?.isOnline == true ? 'online_store' : 'store');
    var selectedStatus = store?.status.name ?? StoreStatus.active.name;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: pSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store == null ? 'Şube Ekle' : 'Şube Düzenle', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      _field(nameController, label: 'Ad', validator: (v) => (v ?? '').trim().isEmpty ? 'Zorunlu alan' : null),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(labelText: 'Store Type'),
                        items: const [
                          DropdownMenuItem(value: 'store', child: Text('store')),
                          DropdownMenuItem(value: 'online_store', child: Text('online_store')),
                        ],
                        onChanged: (value) => setModalState(() => selectedType = value ?? 'store'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('active')),
                          DropdownMenuItem(value: 'pending', child: Text('pending')),
                          DropdownMenuItem(value: 'hidden', child: Text('hidden')),
                        ],
                        onChanged: (value) => setModalState(() => selectedStatus = value ?? 'active'),
                      ),
                      const SizedBox(height: 10),
                      _field(cityController, label: 'Şehir'),
                      const SizedBox(height: 10),
                      _field(districtController, label: 'İlçe'),
                      const SizedBox(height: 10),
                      _field(neighborhoodController, label: 'Mahalle'),
                      const SizedBox(height: 10),
                      _field(addressController, label: 'Adres'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _field(latController, label: 'Lat')),
                          const SizedBox(width: 10),
                          Expanded(child: _field(lngController, label: 'Lng')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _field(keywordController, label: 'searchKeywords (virgül ile)'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!(formKey.currentState?.validate() ?? false)) return;
                            final payload = <String, dynamic>{
                              'displayName': nameController.text.trim(),
                              'name': nameController.text.trim(),
                              'storeType': selectedType,
                              'type': selectedType == 'online_store' ? 'online' : 'local',
                              'isOnline': selectedType == 'online_store',
                              'status': selectedStatus,
                              'city': cityController.text.trim(),
                              'district': districtController.text.trim(),
                              'neighborhood': neighborhoodController.text.trim(),
                              'address': addressController.text.trim(),
                              'addressText': addressController.text.trim(),
                              'lat': double.tryParse(latController.text.replaceAll(',', '.').trim()) ?? 0,
                              'lng': double.tryParse(lngController.text.replaceAll(',', '.').trim()) ?? 0,
                              'isTemporary': false,
                              'isRecurring': false,
                              'searchKeywords': keywordController.text
                                  .split(',')
                                  .map((e) => e.trim().toLowerCase())
                                  .where((e) => e.isNotEmpty)
                                  .toList(),
                              'updatedAt': FieldValue.serverTimestamp(),
                            };

                            if (store == null) {
                              payload['createdAt'] = FieldValue.serverTimestamp();
                              final model = StoreModel.fromMap(payload);
                              await ref.read(adminBrandManagementDomainServiceProvider).addStore(model);
                            } else {
                              await ref.read(adminBrandManagementDomainServiceProvider).updateStore(store.id, payload);
                            }
                            if (context.mounted) Navigator.of(context).pop();
                          },
                          child: const Text('Kaydet'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _field(
    TextEditingController controller, {
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(labelText: label),
    );
  }
}

// ---------------------------------------------------------------------------
// KART WIDGETLARI
// ---------------------------------------------------------------------------

class _PremiumBrandCard extends ConsumerWidget {
  final BrandModel brand;
  const _PremiumBrandCard({required this.brand});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = brand.isActive;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: pBorder), boxShadow: const [BoxShadow(color: Color(0x0A6A442A), blurRadius: 15)]),
      child: Opacity(
        opacity: isActive ? 1.0 : 0.6,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(width: 50, height: 50, decoration: BoxDecoration(color: isActive ? pBrandBrownLight : pStudio, borderRadius: BorderRadius.circular(14)), alignment: Alignment.center, child: Text(brand.name[0].toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: pBrandBrown))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(brand.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: pTextMain)), const SizedBox(height: 4), Text(isActive ? 'Aktif' : 'Pasif', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isActive ? pSuccess : pTextMuted))])),
              Switch.adaptive(value: isActive, activeTrackColor: pBrandBrown, onChanged: (v) => ref.read(adminBrandManagementDomainServiceProvider).updateBrand(brand.id, {'isActive': v})),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumStoreCard extends ConsumerWidget {
  final StoreModel store;
  final List<StoreModel> allStores;
  final VoidCallback onEdit;
  const _PremiumStoreCard({required this.store, required this.allStores, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: pSurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: pBorder), boxShadow: const [BoxShadow(color: Color(0x0A6A442A), blurRadius: 15)]),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: pBrandBrownLight, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.location_on, color: pBrandBrown, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(store.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)), const SizedBox(height: 2), Text(store.neighborhood.isEmpty ? 'Konum yok' : '${store.neighborhood}, ${store.district}', style: const TextStyle(fontSize: 11, color: pTextMuted))])),
              if (store.status == StoreStatus.pending) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: pWarning.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Text('BEKLEYEN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: pWarning))),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: pBorder),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit, size: 16), label: const Text('Düzenle', style: TextStyle(fontSize: 12)), style: TextButton.styleFrom(foregroundColor: pBrandBrown)),
              TextButton.icon(onPressed: () {}, icon: const Icon(Icons.merge_type, size: 16), label: const Text('Birleştir', style: TextStyle(fontSize: 12)), style: TextButton.styleFrom(foregroundColor: pBrandBrown)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline, color: pAlert, size: 20)),
            ],
          )
        ],
      ),
    );
  }
}
