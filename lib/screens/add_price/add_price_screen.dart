import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/price_report_provider.dart';
import '../../widgets/barcode_scanner_sheet.dart';
import '../../models/store.dart';

class AddPriceScreen extends ConsumerStatefulWidget {
  const AddPriceScreen({super.key});

  @override
  ConsumerState<AddPriceScreen> createState() => _AddPriceScreenState();
}

class _AddPriceScreenState extends ConsumerState<AddPriceScreen> {
  final _priceController = TextEditingController();
  final _productController = TextEditingController();
  final _searchController = TextEditingController();

  static const _brown900 = Color(0xFF5D4037);
  static const _brown700 = Color(0xFF795548);
  static const _brown500 = Color(0xFF8D6E63);
  static const _amber600 = Color(0xFFC8956C);
  static const _amber400 = Color(0xFFD4A574);
  static const _cream100 = Color(0xFFFFF8F0);
  static const _cream200 = Color(0xFFF5EDE4);
  static const _cream300 = Color(0xFFEDE0D4);

  static const _categories = ['Gıda', 'Kişisel Bakım', 'Temizlik', 'Teknoloji'];

  @override
  void dispose() {
    _priceController.dispose();
    _productController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(addPriceProvider.select((s) => s.error), (_, next) {
      if (next != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      }
    });

    final state = ref.watch(addPriceProvider);
    if (_priceController.text != state.price) _priceController.text = state.price;
    if (_productController.text != state.productName) {
      _productController.text = state.productName;
    }
    if (_searchController.text != state.searchQuery) {
      _searchController.text = state.searchQuery;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      body: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 414),
          height: 896,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: _cream100,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white, width: 8),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.25),
                blurRadius: 50,
                spreadRadius: -12,
                offset: Offset(0, 25),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                Column(
                  children: [
                    _Header(onInfoPressed: _showInfoModal),
                    Expanded(
                      child: DefaultTabController(
                        length: 2,
                        initialIndex: state.activeTab,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPriceSection(state),
                              _buildDetailsSection(state),
                              const SizedBox(height: 32),
                              _buildStoreSection(state),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                _buildBottomAction(state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSection(AddPriceState state) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      child: Center(
        child: Column(
          children: [
            const Text(
              'ÜRÜN FİYATI',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _brown500,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    '₺',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: _brown500,
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _priceController,
                    onChanged: ref.read(addPriceProvider.notifier).setPrice,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))],
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      color: _brown900,
                      letterSpacing: -2,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0,00',
                      hintStyle: TextStyle(color: _cream300),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(AddPriceState state) {
    return Column(
      children: [
        _InputBox(
          child: Row(
            children: [
              const Icon(Icons.qr_code_scanner_rounded, size: 24, color: _brown900),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _productController,
                  onChanged: ref.read(addPriceProvider.notifier).setProductName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _brown900,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Ürün adını yazın veya barkod okutun',
                    hintStyle: TextStyle(color: _brown500),
                  ),
                ),
              ),
              IconButton(
                onPressed: _scanBarcode,
                icon: const Icon(Icons.center_focus_strong, color: _brown500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InputBox(
          child: Row(
            children: [
              const Icon(Icons.category_outlined, size: 24, color: _brown500),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: state.selectedCategory,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _brown500),
                  decoration: const InputDecoration(border: InputBorder.none),
                  hint: const Text(
                    'Kategori Seçin',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _brown500,
                    ),
                  ),
                  items: _categories
                      .map(
                        (category) => DropdownMenuItem(value: category, child: Text(category)),
                      )
                      .toList(),
                  onChanged: ref.read(addPriceProvider.notifier).setCategory,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoreSection(AddPriceState state) {
    final notifier = ref.read(addPriceProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nerede Gördün?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _brown900,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: _cream200, borderRadius: BorderRadius.circular(12)),
          child: TabBar(
            onTap: notifier.setActiveTab,
            indicator: BoxDecoration(
              color: _amber600,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(200, 149, 108, 0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: _brown700,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
            tabs: const [
              Tab(icon: Icon(Icons.location_on_outlined, size: 18), text: 'Yakınımda'),
              Tab(icon: Icon(Icons.language_rounded, size: 18), text: 'Online'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InputBox(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.search, size: 20, color: _brown500),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: notifier.setSearchQuery,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Market veya platform ara...',
                    hintStyle: TextStyle(color: _brown500),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.visibleStores.length,
          itemBuilder: (context, index) {
            final store = state.visibleStores[index];
            final selected = state.selectedStore?.id == store.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StoreCard(
                store: store,
                selected: selected,
                onTap: () => notifier.setSelectedStore(store),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomAction(AddPriceState state) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [_cream100, _cream100, Colors.transparent],
            stops: [0, .85, 1],
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _amber600,
              elevation: 0,
              shadowColor: const Color.fromRGBO(200, 149, 108, 0.3),
              padding: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: state.isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Fiyatı Kaydet',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final barcode = await BarcodeScannerSheet.scan(context, title: 'Barkod Tara');
    if (barcode != null && mounted) {
      ref.read(addPriceProvider.notifier).setBarcode(barcode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Barkod okundu: $barcode')),
      );
    }
  }

  Future<void> _submit() async {
    final user = ref.read(authStateProvider).value;
    final userId = user?.uid ?? 'guest-user';

    try {
      await ref.read(addPriceProvider.notifier).submitPrice(userId: userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fiyat başarıyla kaydedildi. +10 puan hesabına eklendi!'),
        ),
      );
    } catch (_) {}
  }

  Future<void> _showInfoModal() async {
    await showDialog<void>(
      context: context,
      barrierColor: const Color.fromRGBO(93, 64, 55, 0.6),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              decoration: const BoxDecoration(
                color: _cream100,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.2),
                    blurRadius: 40,
                    offset: Offset(0, 20),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Material(
                      color: _cream200,
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 18, color: _brown700),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      _ModalHeader(),
                      SizedBox(height: 24),
                      _ModalInfo(icon: Icons.star, text: 'Her fiyat girişi +10 Puan kazandırır!'),
                      SizedBox(height: 16),
                      _ModalInfo(
                        icon: Icons.group,
                        text: 'Fiyatlar tamamen kullanıcılar tarafından bildirilmektedir.',
                        dark: true,
                      ),
                    ],
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

class _Header extends StatelessWidget {
  const _Header({required this.onInfoPressed});

  final VoidCallback onInfoPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
      child: Row(
        children: [
          _IconBtn(icon: Icons.arrow_back_rounded, onTap: () => Navigator.maybePop(context)),
          const Expanded(
            child: Text(
              'Fiyat Ekle',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _AddPriceScreenState._brown900,
              ),
            ),
          ),
          _IconBtn(icon: Icons.info_outline_rounded, onTap: onInfoPressed),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 24, color: _AddPriceScreenState._brown900),
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _AddPriceScreenState._cream200,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
      ),
      child: child,
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store, required this.selected, required this.onTap});

  final Store store;
  final bool selected;
  final VoidCallback onTap;

  Color _storeColor() {
    switch (store.id) {
      case 'bim':
        return const Color(0xFFE31837);
      case 'a101':
        return const Color(0xFF00B1E7);
      case 'migros':
        return const Color(0xFFFF7B00);
      case 'sok':
        return const Color(0xFFFFD200);
      case 'trendyol':
        return const Color(0xFFF27A1A);
      case 'getir':
        return const Color(0xFF5D3EBC);
      default:
        return _AddPriceScreenState._brown500;
    }
  }

  Color _logoTextColor() {
    if (store.id == 'sok') return const Color(0xFFE31837);
    if (store.id == 'getir') return const Color(0xFFFFCC00);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? _AddPriceScreenState._cream100 : _AddPriceScreenState._cream200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _AddPriceScreenState._amber400 : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _storeColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  store.logoUrl,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _logoTextColor(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _AddPriceScreenState._brown900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    store.type == 'online'
                        ? (store.subtitle ?? '')
                        : '${store.distanceMeters}m • ${store.subtitle ?? ''}',
                    style: const TextStyle(fontSize: 13, color: _AddPriceScreenState._brown500),
                  ),
                ],
              ),
            ),
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: selected ? 1 : .8,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: selected ? 1 : 0,
                child: const Icon(
                  Icons.check_circle,
                  size: 24,
                  color: _AddPriceScreenState._amber600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalHeader extends StatelessWidget {
  const _ModalHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SizedBox(
          width: 56,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _AddPriceScreenState._cream200,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Icon(Icons.info, color: _AddPriceScreenState._amber600, size: 28),
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Bilgilendirme',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            color: _AddPriceScreenState._brown900,
          ),
        ),
      ],
    );
  }
}

class _ModalInfo extends StatelessWidget {
  const _ModalInfo({required this.icon, required this.text, this.dark = false});

  final IconData icon;
  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AddPriceScreenState._cream200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: dark ? _AddPriceScreenState._brown500 : _AddPriceScreenState._amber600,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: _AddPriceScreenState._brown700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
