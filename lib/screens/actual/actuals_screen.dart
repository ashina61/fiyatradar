import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/actual_item_model.dart';
import '../../models/actual_model.dart';
import '../../providers/actual_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';

class ActualsScreen extends ConsumerStatefulWidget {
  const ActualsScreen({super.key});

  @override
  ConsumerState<ActualsScreen> createState() => _ActualsScreenState();
}

class _ActualsScreenState extends ConsumerState<ActualsScreen> {
  String? _selectedType;
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final actualAsync = ref.watch(latestActiveActualProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Aktüel')),
      body: actualAsync.when(
        data: (actual) {
          if (actual == null) {
            return const _StateBox(
              icon: Icons.auto_awesome,
              title: 'Şu an aktif bir aktüel bulunmuyor.',
              subtitle: 'Yeni aktüeller yakında burada görünecek.',
            );
          }

          final itemsAsync = ref.watch(actualItemsProvider(actual.id));
          return itemsAsync.when(
            data: (items) {
              final visibleItems = items
                  .where((item) => item.isActive)
                  .where((item) => _selectedType == null || item.type == _selectedType)
                  .where((item) => _selectedCategory == null || item.category == _selectedCategory)
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              final typeOptions = items
                  .map((e) => e.type)
                  .where((e) => e.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
              final categoryOptions = items
                  .map((e) => e.category)
                  .where((e) => e.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();

              return ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
                children: [
                  _ActualHeader(actual: actual),
                  const SizedBox(height: AppSpacing.md),
                  if (typeOptions.isNotEmpty || categoryOptions.isNotEmpty)
                    _FilterBar(
                      typeOptions: typeOptions,
                      categoryOptions: categoryOptions,
                      selectedType: _selectedType,
                      selectedCategory: _selectedCategory,
                      onTypeSelected: (value) => setState(() => _selectedType = value),
                      onCategorySelected: (value) => setState(() => _selectedCategory = value),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Ürünler', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.sm),
                  if (visibleItems.isEmpty)
                    const _StateBox(
                      icon: Icons.inventory_2_outlined,
                      title: 'Bu aktüelde gösterilecek ürün bulunamadı.',
                      subtitle: 'Filtreleri temizleyip tekrar deneyin.',
                    )
                  else
                    ...visibleItems.map(_ActualItemCard.new),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _ErrorBox(onRetry: () => ref.invalidate(actualItemsProvider(actual.id))),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorBox(onRetry: () => ref.invalidate(latestActiveActualProvider)),
      ),
    );
  }
}

class _ActualHeader extends StatelessWidget {
  const _ActualHeader({required this.actual});

  final ActualModel actual;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMMM y', 'tr_TR');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImage(
              imageUrl: actual.coverImageUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: AppColors.surfaceVariant),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(actual.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('${date.format(actual.startDate)} - ${date.format(actual.endDate)}', style: Theme.of(context).textTheme.bodySmall),
        if (actual.description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(actual.description),
        ],
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.typeOptions,
    required this.categoryOptions,
    required this.selectedType,
    required this.selectedCategory,
    required this.onTypeSelected,
    required this.onCategorySelected,
  });

  final List<String> typeOptions;
  final List<String> categoryOptions;
  final String? selectedType;
  final String? selectedCategory;
  final ValueChanged<String?> onTypeSelected;
  final ValueChanged<String?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (typeOptions.isNotEmpty)
          DropdownMenu<String?>(
            width: 180,
            initialSelection: selectedType,
            hintText: 'Tür',
            onSelected: onTypeSelected,
            dropdownMenuEntries: [
              const DropdownMenuEntry<String?>(value: null, label: 'Tümü'),
              ...typeOptions.map((e) => DropdownMenuEntry<String?>(value: e, label: e)),
            ],
          ),
        if (categoryOptions.isNotEmpty)
          DropdownMenu<String?>(
            width: 180,
            initialSelection: selectedCategory,
            hintText: 'Kategori',
            onSelected: onCategorySelected,
            dropdownMenuEntries: [
              const DropdownMenuEntry<String?>(value: null, label: 'Tümü'),
              ...categoryOptions.map((e) => DropdownMenuEntry<String?>(value: e, label: e)),
            ],
          ),
      ],
    );
  }
}

class _ActualItemCard extends StatelessWidget {
  const _ActualItemCard(this.item);

  final ActualItemModel item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(item.name),
        subtitle: item.note.isEmpty ? null : Text(item.note),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formatTRY(item.price), style: const TextStyle(fontWeight: FontWeight.w700)),
            if (item.oldPrice != null)
              Text(
                formatTRY(item.oldPrice!),
                style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.sm),
            const Text('Aktüel verileri şu anda yüklenemiyor.'),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateBox extends StatelessWidget {
  const _StateBox({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.sm),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
