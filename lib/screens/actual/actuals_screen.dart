import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/actual_model.dart';
import '../../providers/actual_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/theme.dart';

class ActualsScreen extends ConsumerWidget {
  const ActualsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actualsAsync = ref.watch(activeActualsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Aktüel')),
      body: actualsAsync.when(
        data: (actuals) {
          if (actuals.isEmpty) {
            return _StateBox(
              icon: Icons.auto_awesome,
              title: 'Şu an aktif bir aktüel bulunmuyor.',
              subtitle: 'Yeni aktüeller yakında burada görünecek.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
            itemCount: actuals.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final actual = actuals[index];
              return _ActualCard(actual: actual);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(activeActualsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar dene'),
          ),
        ),
      ),
    );
  }
}

class _ActualCard extends StatelessWidget {
  const _ActualCard({required this.actual});
  final ActualModel actual;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM', 'tr_TR');
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ActualDetailScreen(actual: actual)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: actual.coverImageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: AppColors.surfaceVariant),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${actual.marketName} • ${date.format(actual.startDate)} - ${date.format(actual.endDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(actual.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class ActualDetailScreen extends ConsumerWidget {
  const ActualDetailScreen({super.key, required this.actual});

  final ActualModel actual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(actualItemsProvider(actual.id));
    final date = DateFormat('d MMMM y', 'tr_TR');

    return Scaffold(
      appBar: AppBar(title: Text(actual.marketName)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
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
          const SizedBox(height: AppSpacing.lg),
          Text('Ürünler', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          itemsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const _StateBox(
                  icon: Icons.inventory_2_outlined,
                  title: 'Bu aktüelde henüz ürün eklenmedi.',
                );
              }
              return Column(
                children: items
                    .map(
                      (item) => Card(
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
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            error: (_, __) => FilledButton(
              onPressed: () => ref.invalidate(actualItemsProvider(actual.id)),
              child: const Text('Tekrar dene'),
            ),
          ),
        ],
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
