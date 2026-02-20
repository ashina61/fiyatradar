import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/store_model.dart';
import '../../../utils/constants.dart';

class PriceInputSection extends StatelessWidget {
  const PriceInputSection({
    super.key,
    required this.priceController,
    required this.selectedStore,
    required this.onStoreTap,
  });

  final TextEditingController priceController;
  final StoreModel? selectedStore;
  final VoidCallback onStoreTap;

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
            'Fiyat ve Konum',
            style: TextStyle(
              fontFamily: 'Google Sans',
              fontSize: 18,
              color: Color(0xFF5D4037),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE0D4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text(
                  '₺',
                  style: TextStyle(
                    color: Color(0xFF795548),
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'DM Sans',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^[0-9]+([.,][0-9]{0,2})?$')),
                    ],
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5D4037),
                    ),
                    decoration: const InputDecoration(
                      hintText: '0,00',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Color(0xFF8D6E63),
                        fontFamily: 'DM Sans',
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Fiyat gerekli';
                      final parsed = double.tryParse(value.replaceAll(',', '.'));
                      if (parsed == null || parsed <= 0) return 'Geçerli fiyat girin';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onStoreTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE0D4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: Color(0xFF795548)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedStore?.displayName ?? 'Mağaza Seçin',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        color: selectedStore == null ? const Color(0xFF8D6E63) : const Color(0xFF5D4037),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF795548)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
