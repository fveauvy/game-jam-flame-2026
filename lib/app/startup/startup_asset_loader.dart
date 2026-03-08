import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:game_jam/core/config/asset_paths.dart';

class StartupAssetLoader {
  Future<void> preloadAll() async {
    debugPrint('[startup] preload begin');

    for (final String imageCacheKey in AssetPaths.preloadImageCacheKeys) {
      try {
        await Flame.images.load(imageCacheKey);
        debugPrint('[startup] image ok: $imageCacheKey');
      } catch (error, stackTrace) {
        throw StartupPreloadException(
          asset: imageCacheKey,
          category: 'image',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    for (final String audioCacheKey in AssetPaths.preloadAudioCacheKeys) {
      try {
        await FlameAudio.audioCache.load(audioCacheKey);
        debugPrint('[startup] audio ok: $audioCacheKey');
      } catch (error, stackTrace) {
        throw StartupPreloadException(
          asset: audioCacheKey,
          category: 'audio',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    for (final String bundleAsset in AssetPaths.preloadBundleAssets) {
      try {
        await rootBundle.load(bundleAsset);
        debugPrint('[startup] bundle ok: $bundleAsset');
      } catch (error, stackTrace) {
        throw StartupPreloadException(
          asset: bundleAsset,
          category: 'bundle',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    debugPrint('[startup] preload complete');
  }
}

class StartupPreloadException implements Exception {
  StartupPreloadException({
    required this.asset,
    required this.category,
    required this.error,
    required this.stackTrace,
  });

  final String asset;
  final String category;
  final Object error;
  final StackTrace stackTrace;

  @override
  String toString() {
    return 'StartupPreloadException(category: $category, asset: $asset, error: $error)';
  }
}
