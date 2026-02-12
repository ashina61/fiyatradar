import 'package:flutter/material.dart';

import '../../../utils/formatters.dart';
import '../../../utils/theme.dart';
import '../basket_pricing.dart';

class BasketResultPanel extends StatefulWidget {
  final BasketPricingSummary summary;
  final Map<String, String> marketNames;

  const BasketResultPanel({
    super.key,
    required this.summary,
    required this.marketNames,
  });

  @override
  State<BasketResultPanel> createState() => _BasketResultPanelState();
}

class _BasketResultPanelState extends State<BasketResultPanel> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final rankedMarkets = widget.summary.perMarketTotals.entries.toList()
      ..sort((a, b) {
        final missingCompare = a.value.missingKeys.length.compareTo(b.value.missingKeys.length);
        if (missingCompare != 0) return missingCompare;
        return a.value.total.compareTo(b.value.total);
      });

    final winner = rankedMarkets.isNotEmpty ? rankedMarkets.first : null;
    final winnerName = winner != null
        ? (widget.marketNames[winner.key] ?? winner.key)
        : 'Market bulunamadı';
    final winnerPrice = winner?.value.total ?? 0;

    final alternatives = rankedMarkets.length > 1 ? rankedMarkets.sublist(1) : <MapEntry<String, BasketMarketTotal>>[];
    final visibleAlternatives = _showAll ? alternatives : alternatives.take(3).toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow.withOpacity(0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('En Uygun Market', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          _WinnerCard(
            marketName: winnerName,
            totalPrice: winnerPrice,
            missingCount: winner?.value.missingKeys.length ?? 0,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _InfoChip(
                icon: Icons.auto_awesome,
                label: 'Tahmini sepet',
              ),
              _InfoChip(
                icon: Icons.shopping_bag_outlined,
                label: 'Karma toplam: ${formatTRY(widget.summary.mixedResult.total)}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Alternatifler', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (visibleAlternatives.isEmpty)
            Text('Alternatif market sonucu yok.', style: Theme.of(context).textTheme.bodySmall)
          else
            ...visibleAlternatives.map(
              (entry) => _AlternativeTile(
                marketName: widget.marketNames[entry.key] ?? entry.key,
                totalPrice: entry.value.total,
                missingCount: entry.value.missingKeys.length,
                diff: entry.value.total - winnerPrice,
              ),
            ),
          if (alternatives.length > 3)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _showAll = !_showAll),
                child: Text(_showAll ? 'Daha az göster' : 'Tümünü gör'),
              ),
            ),
        ],
      ),
    );
  }
}

class _WinnerCard extends StatelessWidget {
  final String marketName;
  final double totalPrice;
  final int missingCount;

  const _WinnerCard({
    required this.marketName,
    required this.totalPrice,
    required this.missingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFFAF2), Color(0xFFF9FFFB)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.withOpacity(0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  marketName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  'En Uygun',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            formatTRY(totalPrice),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (missingCount > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('$missingCount eksik ürün var', style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _AlternativeTile extends StatelessWidget {
  final String marketName;
  final double totalPrice;
  final int missingCount;
  final double diff;

  const _AlternativeTile({
    required this.marketName,
    required this.totalPrice,
    required this.missingCount,
    required this.diff,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.7),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(marketName, style: Theme.of(context).textTheme.titleMedium),
                Text(
                  missingCount == 0 ? 'Tüm ürünler mevcut' : '$missingCount eksik ürün',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            formatTRY(totalPrice),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            diff <= 0 ? '—' : '+${formatTRY(diff)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
