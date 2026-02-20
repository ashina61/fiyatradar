import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/category_model.dart';
import '../../../models/product_model.dart';
import '../../../utils/constants.dart';

class ProductSelectionSection extends StatelessWidget {
  const ProductSelectionSection({
    super.key,
    required this.productController,
    required this.categoriesAsync,
    required this.selectedCategory,
    required this.productSuggestions,
    required this.showProductSuggestions,
    required this.decorationBuilder,
    required this.onCategoryChanged,
    required this.onProductChanged,
    required this.onProductSuggestionTap,
    required this.onBarcodeTap,
  });

  final TextEditingController productController;
  final AsyncValue<List<CategoryModel>> categoriesAsync;
  final String? selectedCategory;
  final List<ProductModel> productSuggestions;
  final bool showProductSuggestions;
  final InputDecoration Function({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) decorationBuilder;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String> onProductChanged;
  final ValueChanged<ProductModel> onProductSuggestionTap;
  final VoidCallback onBarcodeTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EDE4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ürün ve Kategori',
            style: TextStyle(
              fontFamily: 'Google Sans',
              fontSize: 18,
              color: Color(0xFF5D4037),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: productController,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: Color(0xFF5D4037),
            ),
            decoration: decorationBuilder(
              hintText: 'Ürün Adı',
              prefixIcon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF795548)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFC8956C)),
                onPressed: onBarcodeTap,
              ),
            ),
            onChanged: onProductChanged,
            validator: (value) => value == null || value.isEmpty ? 'Ürün adı gerekli' : null,
          ),
          if (showProductSuggestions)
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.xs),
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F0),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: const Color(0xFFEDE0D4)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: productSuggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final product = productSuggestions[index];
                  return ListTile(
                    dense: true,
                    title: Text(product.name),
                    subtitle: Text(product.brand),
                    onTap: () => onProductSuggestionTap(product),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          categoriesAsync.when(
            data: (categories) => DropdownButtonFormField<String>(
              value: selectedCategory,
              dropdownColor: const Color(0xFFFFF8F0),
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF5D4037),
                fontSize: 15,
              ),
              decoration: decorationBuilder(
                hintText: 'Kategori',
                prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF795548)),
              ),
              iconEnabledColor: const Color(0xFF795548),
              items: categories
                  .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                  .toList(),
              onChanged: onCategoryChanged,
              validator: (v) => v == null ? 'Kategori seçin' : null,
            ),
            loading: () => const LinearProgressIndicator(color: Color(0xFFC8956C)),
            error: (e, _) => Text('Kategori yüklenemedi: $e'),
          ),
        ],
      ),
    );
  }
}
