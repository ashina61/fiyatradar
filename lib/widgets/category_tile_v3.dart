import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import 'premium_pressable.dart';

class CategoryTileV3 extends StatelessWidget {
  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryTileV3({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Modelden gelen başlığa göre ikon atama
    IconData catIcon = Icons.category;
    final catTitle = category.title.toLowerCase();
    
    if(catTitle.contains('market')) catIcon = Icons.shopping_cart_outlined;
    if(catTitle.contains('tekno')) catIcon = Icons.laptop_mac;
    if(catTitle.contains('kozmetik')) catIcon = Icons.face_retouching_natural;
    if(catTitle.contains('spor') || catTitle.contains('hobi')) catIcon = Icons.sports_esports;
    if(catTitle.contains('tümü')) catIcon = Icons.grid_view_rounded;

    return PremiumPressable(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              // Seçiliyse Acı Kahve, değilse Beyaz
              color: isSelected ? const Color(0xFF2D1B12) : Colors.white,
              // Tümü butonu karemsi, diğerleri yuvarlak (Fotoğraftaki yapı)
              borderRadius: isSelected ? BorderRadius.circular(16) : BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03), 
                  blurRadius: 8, 
                  offset: const Offset(0, 4)
                )
              ],
            ),
            child: Icon(
              catIcon, 
              // Seçiliyse ikon beyaz, değilse gri
              color: isSelected ? Colors.white : Colors.grey.shade600, 
              size: 28
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.title, 
            style: TextStyle(
              fontSize: 12, 
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, 
              color: const Color(0xFF2A1A10)
            )
          ),
        ],
      ),
    );
  }
}
