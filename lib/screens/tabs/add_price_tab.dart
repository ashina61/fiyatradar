import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/design.dart';

class AddPriceTab extends StatefulWidget {
  const AddPriceTab({super.key});

  @override
  State<AddPriceTab> createState() => _AddPriceTabState();
}

class _AddPriceTabState extends State<AddPriceTab> {
  final _formKey = GlobalKey<FormState>();
  final _productSearchCtrl = TextEditingController();
  Product? _selectedProduct;
  String? _selectedStore;
  final _priceCtrl = TextEditingController();
  final _newProductCtrl = TextEditingController();
  bool _newProductMode = false;
  bool _submitting = false;

  @override
  void dispose() {
    _productSearchCtrl.dispose();
    _priceCtrl.dispose();
    _newProductCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir market seç'),
          backgroundColor: CoffeeColors.darkRoast,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_newProductMode && _selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir ürün seç'),
          backgroundColor: CoffeeColors.darkRoast,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final state = AppStateScope.of(context);
    final price = double.parse(_priceCtrl.text.replaceAll(',', '.'));

    if (_newProductMode) {
      await state.addProduct(
        name: _newProductCtrl.text.trim(),
        brand: '-',
        category: 'Tümü',
        emoji: '🛒',
        unit: '1 adet',
      );
    } else {
      await state.addPrice(
        productId: _selectedProduct!.id,
        store: _selectedStore!,
        price: price,
      );
    }

    if (!mounted) return;

    _priceCtrl.clear();
    _newProductCtrl.clear();
    _productSearchCtrl.clear();
    setState(() {
      _selectedProduct = null;
      _selectedStore = null;
      _newProductMode = false;
      _submitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teşekkürler ☕  Katkın için puan kazandın'),
        backgroundColor: CoffeeColors.darkRoast,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final q = _productSearchCtrl.text.trim().toLowerCase();
    final filteredProducts = state.products.where((p) {
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q);
    }).toList();

    final step2Active = _selectedStore != null ||
        (_newProductMode
            ? _newProductCtrl.text.isNotEmpty
            : _selectedProduct != null);
    final step3Active = _priceCtrl.text.isNotEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fiyat Ekle',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: CoffeeColors.espresso),
                        ),
                        Text(
                          'Markette gördüğünü paylaş',
                          style: TextStyle(
                              color: CoffeeColors.cocoa, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: CoffeeColors.caramel,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: CoffeeColors.caramel.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline,
                            color: CoffeeColors.espresso, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '+10 puan',
                          style: TextStyle(
                            color: CoffeeColors.espresso,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(FR.radiusL),
                  border: Border.all(color: CoffeeColors.crema),
                  boxShadow: FR.softShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: CoffeeColors.caramel.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.verified_outlined,
                          color: CoffeeColors.caramel, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Eklediğin fiyat anında topluluk verisine düşer. Diğer kullanıcıların kararını güçlendirir.',
                        style: TextStyle(
                          color: CoffeeColors.darkRoast,
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _StepDot(n: 1, label: 'Ürün', active: true, done: step2Active),
                  _StepLine(active: step2Active),
                  _StepDot(
                    n: 2,
                    label: 'Market',
                    active: step2Active,
                    done: step3Active,
                  ),
                  _StepLine(active: step3Active),
                  _StepDot(
                    n: 3,
                    label: 'Fiyat',
                    active: step3Active,
                    done: false,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _StepLabel('1. Ürün'),
              Row(
                children: [
                  _ModeChip(
                    label: 'Mevcut ürün',
                    selected: !_newProductMode,
                    onTap: () => setState(() => _newProductMode = false),
                  ),
                  const SizedBox(width: 8),
                  _ModeChip(
                    label: 'Yeni ürün ekle',
                    selected: _newProductMode,
                    onTap: () => setState(() => _newProductMode = true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_newProductMode)
                TextFormField(
                  controller: _newProductCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Ürün adı (örn: Süt 1L)',
                    prefixIcon: Icon(Icons.inventory_2_outlined,
                        color: CoffeeColors.cocoa, size: 20),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                )
              else
                Column(
                  children: [
                    TextFormField(
                      controller: _productSearchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Ürün veya marka ara',
                        prefixIcon: const Icon(Icons.search,
                            color: CoffeeColors.cocoa, size: 20),
                        suffixIcon: _productSearchCtrl.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _productSearchCtrl.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close, size: 18),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 230),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: CoffeeColors.crema),
                        boxShadow: FR.softShadow,
                      ),
                      child: filteredProducts.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: Text(
                                'Eşleşen ürün bulunamadı',
                                style: TextStyle(
                                  color: CoffeeColors.cocoa,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final p = filteredProducts[index];
                                final selected = p.id == _selectedProduct?.id;
                                return ListTile(
                                  onTap: () =>
                                      setState(() => _selectedProduct = p),
                                  dense: true,
                                  leading: Text(p.emoji,
                                      style: const TextStyle(fontSize: 18)),
                                  title: Text(
                                    p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                      color: CoffeeColors.espresso,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: Text(
                                    p.lowestPrice == null
                                        ? p.brand
                                        : '₺${p.lowestPrice!.toStringAsFixed(2)} · ${p.cheapestStore ?? ''}',
                                    style: const TextStyle(
                                        color: CoffeeColors.cocoa,
                                        fontSize: 11),
                                  ),
                                  trailing: selected
                                      ? const Icon(Icons.check_circle,
                                          color: CoffeeColors.caramel,
                                          size: 18)
                                      : null,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              const SizedBox(height: 22),
              _StepLabel('2. Market'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.stores.map((s) {
                  final selected = s == _selectedStore;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedStore = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? CoffeeColors.espresso : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? CoffeeColors.espresso
                              : CoffeeColors.crema,
                        ),
                        boxShadow: selected ? FR.softShadow : null,
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          color: selected
                              ? CoffeeColors.cream
                              : CoffeeColors.darkRoast,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(child: _StepLabel('3. Fiyat (₺)')),
                  if (_selectedProduct?.lowestPrice != null)
                    Text(
                      'mevcut en iyi: ₺${_selectedProduct!.lowestPrice!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: CoffeeColors.caramel,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              TextFormField(
                controller: _priceCtrl,
                onChanged: (_) => setState(() {}),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: CoffeeColors.espresso,
                  letterSpacing: -0.5,
                ),
                decoration: const InputDecoration(
                  hintText: '0,00',
                  prefixText: '₺  ',
                  prefixStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: CoffeeColors.cocoa,
                  ),
                  hintStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: CoffeeColors.crema,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Zorunlu';
                  final p = double.tryParse(v.replaceAll(',', '.'));
                  if (p == null || p <= 0) return 'Geçerli fiyat gir';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: _submitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: CoffeeColors.cream),
                          ),
                          SizedBox(width: 12),
                          Text('Paylaşılıyor…'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 20),
                          SizedBox(width: 10),
                          Text('Fiyatı Paylaş ve Puan Kazan'),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Her katkı topluluğu güçlendirir.',
                  style: TextStyle(
                    color: CoffeeColors.cocoa,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? CoffeeColors.espresso : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? CoffeeColors.espresso : CoffeeColors.crema),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? CoffeeColors.cream : CoffeeColors.darkRoast,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.n,
    required this.label,
    required this.active,
    required this.done,
  });
  final int n;
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: active ? CoffeeColors.espresso : CoffeeColors.foam,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? CoffeeColors.espresso : CoffeeColors.crema,
              width: active ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : Text(
                  '$n',
                  style: TextStyle(
                    color: active ? CoffeeColors.cream : CoffeeColors.cocoa,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: active ? CoffeeColors.espresso : CoffeeColors.cocoa,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({this.active = false});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 2,
          decoration: BoxDecoration(
            color: active
                ? CoffeeColors.caramel.withOpacity(0.5)
                : CoffeeColors.crema,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
            color: CoffeeColors.espresso,
            fontWeight: FontWeight.w800,
            fontSize: 14),
      ),
    );
  }
}
