import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/store_model.dart';
import '../../../providers/product_provider.dart';
import '../../../utils/constants.dart';
import '../../../utils/theme.dart';
import 'store_location_status_banner.dart';

enum StorePickerTab { nearby, online }

class StorePickerSheet extends ConsumerStatefulWidget {
  const StorePickerSheet({
    super.key,
    required this.userPosition,
    required this.storeDistanceMeters,
    required this.isResolvingUserPosition,
    required this.locationPermissionDenied,
    required this.locationPermissionDeniedForever,
    required this.locationServiceDisabled,
    required this.locationUnavailable,
    required this.onRetryLocation,
    required this.onSelectStore,
    required this.onDistanceMapChanged,
    required this.onAddNewStore,
  });

  final Position? userPosition;
  final Map<String, double> storeDistanceMeters;
  final bool isResolvingUserPosition;
  final bool locationPermissionDenied;
  final bool locationPermissionDeniedForever;
  final bool locationServiceDisabled;
  final bool locationUnavailable;
  final VoidCallback onRetryLocation;
  final ValueChanged<StoreModel> onSelectStore;
  final ValueChanged<Map<String, double>> onDistanceMapChanged;
  final VoidCallback onAddNewStore;

  @override
  ConsumerState<StorePickerSheet> createState() => _StorePickerSheetState();
}

class _StorePickerSheetState extends ConsumerState<StorePickerSheet> {
  StorePickerTab _activeTab = StorePickerTab.nearby;

  @override
  Widget build(BuildContext context) {
    final nearbyStoresAsync = ref.watch(nearbyStoresProvider);
    final onlineStoresAsync = ref.watch(onlineStoresProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text('Mağaza Seç', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('📍 Yakınımda'),
                      selected: _activeTab == StorePickerTab.nearby,
                      onSelected: (_) => setState(() => _activeTab = StorePickerTab.nearby),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('🌐 Online'),
                      selected: _activeTab == StorePickerTab.online,
                      onSelected: (_) => setState(() => _activeTab = StorePickerTab.online),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _activeTab == StorePickerTab.nearby
                  ? StoreLocationStatusBanner(
                      isResolving: widget.isResolvingUserPosition,
                      locationPermissionDenied: widget.locationPermissionDenied,
                      locationPermissionDeniedForever: widget.locationPermissionDeniedForever,
                      locationServiceDisabled: widget.locationServiceDisabled,
                      locationUnavailable: widget.locationUnavailable,
                      hasUserPosition: widget.userPosition != null,
                      onOpenLocationSettings: Geolocator.openLocationSettings,
                      onOpenAppSettings: Geolocator.openAppSettings,
                      onRetry: widget.onRetryLocation,
                    )
                  : _onlineInfoBanner(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: _activeTab == StorePickerTab.nearby
                  ? _buildNearbyStoreList(nearbyStoresAsync, scrollController)
                  : _buildOnlineStoreList(onlineStoresAsync, scrollController),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNearbyStoreList(AsyncValue<List<StoreModel>> storesAsync, ScrollController scrollController) {
    return storesAsync.when(
      loading: _buildStoreSkeletonList,
      error: (e, st) {
        debugPrint('[AddPrice] nearby stores load error: $e');
        debugPrintStack(stackTrace: st);
        return const Center(child: Text('Yakındaki mağazalar yüklenemedi.'));
      },
      data: (stores) {
        final distanceMap = _buildStoreDistanceMap(stores);
        if (_hasDistanceMapChanged(distanceMap)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onDistanceMapChanged(distanceMap);
          });
        }

        final nearbyStores = List<StoreModel>.from(stores)
          ..sort((a, b) => (distanceMap[a.id] ?? double.infinity).compareTo(distanceMap[b.id] ?? double.infinity));

        const maxRadiusMeters = 20000.0;
        final filteredStores = nearbyStores.where((store) {
          if (widget.userPosition == null || _isStoreLocationMissing(store)) return true;
          final distance = distanceMap[store.id];
          if (distance == null) return true;
          return distance <= maxRadiusMeters;
        }).toList();

        final visibleStores = filteredStores.isEmpty ? nearbyStores : filteredStores;

        if (visibleStores.isEmpty) {
          return const Center(child: Text('Yakındaki mağaza bulunamadı.'));
        }

        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: visibleStores.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == visibleStores.length) {
              return _buildAddNewStoreItem();
            }
            final store = visibleStores[index];
            final distanceText = _distanceText(store, widget.storeDistanceMeters.isEmpty ? distanceMap : widget.storeDistanceMeters);
            return ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.store, color: AppColors.secondary, size: 22),
              ),
              title: Text(store.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${store.neighborhood.isEmpty ? '-' : store.neighborhood} mah.', style: const TextStyle(fontSize: 12)),
                  if (_isStoreLocationMissing(store))
                    const Text('Admin uyarisi: Bu sube icin konum bilgisi eksik.', style: TextStyle(fontSize: 11, color: AppColors.error)),
                ],
              ),
              trailing: Text(distanceText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              onTap: () {
                widget.onSelectStore(store);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOnlineStoreList(AsyncValue<List<StoreModel>> storesAsync, ScrollController scrollController) {
    return storesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        debugPrint('Online stores load error: $e');
        debugPrintStack(stackTrace: st);
        if (e is FirebaseException && e.code == 'failed-precondition') {
          return const Center(child: Text('Online mağazalar yüklenemedi, tekrar deneyin'));
        }
        return const Center(child: Text('Online mağazalar yüklenemedi, tekrar deneyin'));
      },
      data: (stores) {
        final onlineStores = List<StoreModel>.from(stores)..sort((a, b) => a.displayName.compareTo(b.displayName));
        if (onlineStores.isEmpty) {
          return const Center(child: Text('Henüz online mağaza eklenmemiş.'));
        }
        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: onlineStores.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final store = onlineStores[index];
            return ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.language, color: AppColors.info, size: 22),
              ),
              title: Text('🌐 ${store.displayName}', style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
              onTap: () {
                widget.onSelectStore(store.copyWith(type: StoreType.online));
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStoreSkeletonList() {
    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => Container(
        height: 68,
        decoration: BoxDecoration(
          color: scheme.surfaceVariant.withOpacity(0.55),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  Widget _onlineInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: const Text(
        '🌐 Online mağazalar konumdan bağımsızdır',
        style: TextStyle(fontSize: 12, color: AppColors.info),
      ),
    );
  }

  Widget _buildAddNewStoreItem() {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 1.5),
        ),
        child: const Icon(Icons.add_business, color: AppColors.accent, size: 22),
      ),
      title: const Text('Bu mağaza listede yok +', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.accent)),
      subtitle: const Text('Yeni mağaza önerisi gönder', style: TextStyle(fontSize: 12)),
      onTap: () {
        Navigator.pop(context);
        widget.onAddNewStore();
      },
    );
  }

  bool _isStoreLocationMissing(StoreModel store) =>
      store.lat == 0 || store.lng == 0 || store.lat.abs() > 90 || store.lng.abs() > 180;

  Map<String, double> _buildStoreDistanceMap(List<StoreModel> stores) {
    if (widget.userPosition == null) return const {};
    final distances = <String, double>{};
    for (final store in stores) {
      if (_isStoreLocationMissing(store)) continue;
      distances[store.id] = Geolocator.distanceBetween(
        widget.userPosition!.latitude,
        widget.userPosition!.longitude,
        store.lat,
        store.lng,
      );
    }
    return distances;
  }

  bool _hasDistanceMapChanged(Map<String, double> next) {
    if (widget.storeDistanceMeters.length != next.length) return true;
    for (final entry in next.entries) {
      final current = widget.storeDistanceMeters[entry.key];
      if (current == null || (current - entry.value).abs() > 0.5) return true;
    }
    return false;
  }

  String _distanceText(StoreModel store, Map<String, double> distanceMap) {
    if (_isStoreLocationMissing(store)) return 'Konum bilgisi eksik';
    if (widget.locationServiceDisabled) return 'Servis kapalı';
    if (widget.locationPermissionDenied || widget.locationPermissionDeniedForever) return 'İzin gerekli';
    if (widget.locationUnavailable && widget.userPosition == null) return 'Konum alınamadı';

    final dist = distanceMap[store.id];
    if (dist == null || dist.isInfinite) return '—';
    return dist < 1000 ? '${dist.round()} m' : '${(dist / 1000).toStringAsFixed(1)} km';
  }
}
