import 'dart:ui';

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
    final scheme = Theme.of(context).colorScheme;
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

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Sepet Sonucu', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              _WinnerCard(marketName: winnerName, totalPrice: winnerPrice, missingCount: winner?.value.missingKeys.length ?? 0),
              const SizedBox(height: AppSpacing.md),
              _BreakdownCard(summary: widget.summary),
              const SizedBox(height: AppSpacing.md),
              Text('Market Sıralaması', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView(
                  children: [
                    if (winner != null)
                      _AnimatedMarketRow(
                        marketName: winnerName,
                        totalPrice: winnerPrice,
                        missingCount: winner.value.missingKeys.length,
                        isWinner: true,
                        diff: 0,
                      ),
                    ...visibleAlternatives.map((entry) => _AnimatedMarketRow(
                          marketName: widget.marketNames[entry.key] ?? entry.key,
                          totalPrice: entry.value.total,
                          missingCount: entry.value.missingKeys.length,
                          diff: entry.value.total - winnerPrice,
                        )),
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
              ),
            ],
          ),
        ),
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
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withOpacity(0.7),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('En uygun market', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.primary)),
              const SizedBox(height: AppSpacing.xs),
              Text(marketName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.xs),
              Text(formatTRY(totalPrice), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              if (missingCount > 0)
                Text('$missingCount eksik ürün', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final BasketPricingSummary summary;

  const _BreakdownCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Breakdown', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text('Karma toplam: ${formatTRY(summary.mixedResult.total)}'),
          Text('Eksik ürün: ${summary.mixedResult.missingKeys.length}'),
        ],
      ),
    );
  }
}

class _AnimatedMarketRow extends StatelessWidget {
  final String marketName;
  final double totalPrice;
  final int missingCount;
  final bool isWinner;
  final double diff;

  const _AnimatedMarketRow({
    required this.marketName,
    required this.totalPrice,
    required this.missingCount,
    this.isWinner = false,
    required this.diff,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isWinner ? scheme.primaryContainer.withOpacity(0.5) : scheme.surfaceVariant.withOpacity(0.45),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isWinner ? scheme.primary.withOpacity(0.35) : scheme.outlineVariant.withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 280),
            scale: isWinner ? 1 : 0.85,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 280),
              opacity: isWinner ? 1 : 0.45,
              child: Icon(Icons.check_circle, color: isWinner ? scheme.primary : scheme.outline),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(marketName, style: Theme.of(context).textTheme.titleMedium),
                Text(missingCount == 0 ? 'Tüm ürünler var' : '$missingCount eksik ürün', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatTRY(totalPrice), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              if (diff > 0) Text('+${formatTRY(diff)}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
