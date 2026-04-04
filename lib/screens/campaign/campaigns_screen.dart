import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/campaign_provider.dart';
import '../../utils/theme.dart';
import 'campaign_detail_screen.dart';

class CampaignsScreen extends ConsumerWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(activeCampaignsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kampanyalar')),
      body: campaignsAsync.when(
        data: (campaigns) {
          if (campaigns.isEmpty) {
            return const Center(child: Text('Aktif kampanya bulunamadı'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemBuilder: (context, index) {
              final campaign = campaigns[index];
              return InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CampaignDetailScreen(campaignId: campaign.id),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.outlineVariant.withOpacity(0.7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppRadius.lg),
                          topRight: Radius.circular(AppRadius.lg),
                        ),
                        child: AspectRatio(
                          aspectRatio: 16 / 7,
                          child: (campaign.imageUrl ?? '').trim().isEmpty
                              ? Container(decoration: const BoxDecoration(gradient: AppColors.gradient))
                              : CachedNetworkImage(
                                  imageUrl: campaign.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    decoration: const BoxDecoration(gradient: AppColors.gradient),
                                  ),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              campaign.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              campaign.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ürün sayısı: ${campaign.itemProductIds.length} • Özet: Kampanya sepeti',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemCount: campaigns.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Kampanyalar yüklenemedi')),
      ),
    );
  }
}
