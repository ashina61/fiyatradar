import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/product_provider.dart';
import '../../utils/theme.dart';

class AdminProductSuggestionsTab extends ConsumerWidget {
  const AdminProductSuggestionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(pendingProductSuggestionsProvider);
    return suggestionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Urun onerileri yuklenemedi')),
      data: (suggestions) {
        if (suggestions.isEmpty) {
          return const Center(child: Text('Bekleyen ürün önerisi yok.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(AppSpacing.md),
                leading: suggestion.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          suggestion.imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.inventory_2_outlined),
                      ),
                title: Text(suggestion.name.isEmpty ? 'İsimsiz ürün' : suggestion.name),
                subtitle: Text(
                  [
                    if (suggestion.barcode.isNotEmpty)
                      'Barkod: ${suggestion.barcode}',
                    if (suggestion.category.isNotEmpty)
                      'Kategori: ${suggestion.category}',
                    if (suggestion.brand.isNotEmpty)
                      'Marka: ${suggestion.brand}',
                  ].join('\n'),
                ),
                trailing: Wrap(
                  spacing: 6,
                  children: [
                    IconButton(
                      tooltip: 'Reddet',
                      onPressed: () async {
                        await ref
                            .read(productSuggestionDomainServiceProvider)
                            .rejectProductSuggestion(suggestion.id);
                      },
                      icon: const Icon(Icons.close, color: AppColors.error),
                    ),
                    IconButton(
                      tooltip: 'Onayla',
                      onPressed: () async {
                        await ref
                            .read(productSuggestionDomainServiceProvider)
                            .approveProductSuggestion(suggestion.id);
                      },
                      icon: const Icon(Icons.check, color: AppColors.success),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
