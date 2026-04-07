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
  Product? _selectedProduct;
  String? _selectedStore;
  final _priceCtrl = TextEditingController();
  final _newProductCtrl = TextEditingController();
  bool _newProductMode = false;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _newProductCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Market seç')),
      );
      return;
    }
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
      // Newly added product will stream in; skip price add this round.
    } else {
      if (_selectedProduct == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ürün seç')),
        );
        return;
      }
      await state.addPrice(
        productId: _selectedProduct!.id,
        store: _selectedStore!,
        price: price,
      );
    }
    if (!mounted) return;

    _priceCtrl.clear();
    _newProductCtrl.clear();
    setState(() {
      _selectedProduct = null;
      _selectedStore = null;
      _newProductMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teşekkürler ☕ Katkın için puan kazandın'),
        backgroundColor: CoffeeColors.darkRoast,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
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
                        Text('Fiyat Ekle',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                                color: CoffeeColors.espresso)),
                        Text(
                          'Markette gördüğünü paylaş, puan kazan.',
                          style: TextStyle(color: CoffeeColors.cocoa),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: CoffeeColors.caramel,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add_circle_outline,
                            color: CoffeeColors.espresso, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '+5',
                          style: TextStyle(
                            color: CoffeeColors.espresso,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          ' puan',
                          style: TextStyle(
                            color: CoffeeColors.espresso,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Contribution callout
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(FR.radiusL),
                  border: Border.all(color: CoffeeColors.crema),
                  boxShadow: FR.softShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: CoffeeColors.caramel.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.verified_outlined,
                          color: CoffeeColors.caramel, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Eklediğin fiyat anında topluluk verisine düşer ve diğer kullanıcıların kararına yardım eder.',
                        style: TextStyle(
                          color: CoffeeColors.darkRoast,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Step pills
              Row(
                children: [
                  _StepDot(n: 1, label: 'Ürün', active: true),
                  _StepLine(),
                  _StepDot(
                    n: 2,
                    label: 'Market',
                    active: _selectedStore != null,
                  ),
                  _StepLine(),
                  _StepDot(
                    n: 3,
                    label: 'Fiyat',
                    active: _priceCtrl.text.isNotEmpty,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _Label('1. Ürün'),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Mevcut ürün'),
                    selected: !_newProductMode,
                    onSelected: (_) =>
                        setState(() => _newProductMode = false),
                    selectedColor: CoffeeColors.espresso,
                    labelStyle: TextStyle(
                      color: !_newProductMode
                          ? CoffeeColors.cream
                          : CoffeeColors.darkRoast,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Yeni ürün'),
                    selected: _newProductMode,
                    onSelected: (_) =>
                        setState(() => _newProductMode = true),
                    selectedColor: CoffeeColors.espresso,
                    labelStyle: TextStyle(
                      color: _newProductMode
                          ? CoffeeColors.cream
                          : CoffeeColors.darkRoast,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_newProductMode)
                TextFormField(
                  controller: _newProductCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Ürün adı (örn: Süt 1L)',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                )
              else
                DropdownButtonFormField<Product>(
                  value: _selectedProduct,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      hintText: 'Ürün seç'),
                  items: state.products
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text('${p.emoji}  ${p.name}'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedProduct = v),
                ),
              const SizedBox(height: 20),
              _Label('2. Market'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.stores.map((s) {
                  final selected = s == _selectedStore;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedStore = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? CoffeeColors.espresso
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: selected
                                ? CoffeeColors.espresso
                                : CoffeeColors.crema),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          color: selected
                              ? CoffeeColors.cream
                              : CoffeeColors.darkRoast,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _Label('3. Fiyat (₺)'),
              TextFormField(
                controller: _priceCtrl,
                onChanged: (_) => setState(() {}),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: 'örn: 24,90'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Zorunlu';
                  final p =
                      double.tryParse(v.replaceAll(',', '.'));
                  if (p == null || p <= 0) return 'Geçerli fiyat gir';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Fiyatı Paylaş ve Puan Kazan'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Doğrulanan her katkı topluluğu güçlendirir.',
                  style: TextStyle(
                    color: CoffeeColors.cocoa,
                    fontSize: 11,
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

class _StepDot extends StatelessWidget {
  const _StepDot({required this.n, required this.label, required this.active});
  final int n;
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: active ? CoffeeColors.espresso : CoffeeColors.foam,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? CoffeeColors.espresso : CoffeeColors.crema,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$n',
            style: TextStyle(
              color: active ? CoffeeColors.cream : CoffeeColors.cocoa,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: active ? CoffeeColors.espresso : CoffeeColors.cocoa,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Divider(color: CoffeeColors.crema, thickness: 1),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              color: CoffeeColors.darkRoast,
              fontWeight: FontWeight.w700,
              fontSize: 14)),
    );
  }
}
