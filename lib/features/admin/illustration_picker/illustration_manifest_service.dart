import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/illustration_asset.dart';

/// Loads the static illustration manifest from the bundled asset.
/// Result is cached in-memory; manifest is immutable per app session.
class IllustrationManifestService {
  IllustrationManifestService._();

  static const String _manifestPath = 'assets/illustrations/manifest.json';
  static IllustrationManifest? _cache;
  static Future<IllustrationManifest>? _inflight;

  static Future<IllustrationManifest> load() {
    if (_cache != null) return Future.value(_cache);
    return _inflight ??= _loadOnce().then((m) {
      _cache = m;
      _inflight = null;
      return m;
    });
  }

  static Future<IllustrationManifest> _loadOnce() async {
    final raw = await rootBundle.loadString(_manifestPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final rawList = (json['illustrations'] as List?) ?? const [];
    final rawCategories = (json['categories'] as List?) ?? const [];
    final illustrations = rawList
        .whereType<Map>()
        .map((e) => IllustrationAsset.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
    final categories = rawCategories
        .whereType<Map>()
        .map((e) => IllustrationCategory.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
    return IllustrationManifest(
      version: (json['version'] ?? '1.0.0') as String,
      illustrations: illustrations,
      categories: categories,
    );
  }

  /// Look up a single illustration by id — useful for restoring the
  /// currently-assigned visual in the picker.
  static Future<IllustrationAsset?> findById(String id) async {
    if (id.isEmpty) return null;
    final manifest = await load();
    for (final a in manifest.illustrations) {
      if (a.id == id) return a;
    }
    return null;
  }
}
