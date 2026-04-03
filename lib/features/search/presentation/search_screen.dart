import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_radius.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _hasSearched = false;
  final List<Map<String, dynamic>> _results = [
    {'title': 'Bluetooth Hoparlör', 'meta': 'Amazon • 1 dk önce', 'price': '₺899', 'icon': Icons.speaker_rounded},
    {'title': 'Protein Tozu', 'meta': 'Trendyol • 4 dk önce', 'price': '₺749', 'icon': Icons.fitness_center_rounded},
    {'title': 'Airfryer', 'meta': 'Hepsiburada • 10 dk önce', 'price': '₺2.599', 'icon': Icons.kitchen_rounded},
  ];

  void _search() {
    setState(() => _hasSearched = true);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Ara', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.border)),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.textSubtle, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                        decoration: const InputDecoration(hintText: 'Ürün, marka, platform', hintStyle: TextStyle(color: AppColors.textSubtle), border: InputBorder.none, isDense: true),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    if (_controller.text.isNotEmpty)
                      GestureDetector(onTap: () => _controller.clear(), child: const Icon(Icons.close_rounded, color: AppColors.textSubtle, size: 20)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: ['Market', 'Elektronik', 'Gıda', 'Bakım', 'Ev']
                    .map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(label: Text(cat), selected: false, onSelected: (_) {}, backgroundColor: AppColors.surface, selectedColor: AppColors.tan, side: BorderSide.none, labelStyle: const TextStyle(color: AppColors.textPrimary)),
                        ))
                    .toList(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: _hasSearched && _results.isNotEmpty
                    ? _results.map((item) => _buildResultItem(item)).toList()
                    : [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.border)),
                          child: Column(
                            children: const [
                              Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSubtle),
                              SizedBox(height: 16),
                              Text('Aradığınız kriterde sonuç bulunamadı.', style: TextStyle(color: AppColors.textSubtle, fontSize: 15), textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/detail'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.border)),
        child: Row(
          children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.md)), child: Icon(Icons.inventory_2_rounded, color: AppColors.tan, size: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(item['meta']!, style: const TextStyle(fontSize: 12, color: AppColors.textSubtle)),
                ],
              ),
            ),
            Text(item['price']!, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.tan)),
          ],
        ),
      ),
    );
  }
}
