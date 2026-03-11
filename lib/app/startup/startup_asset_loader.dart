import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:game_jam/core/config/asset_paths.dart';

class StartupAssetLoader {
  Future<void> preloadAll({
    void Function(StartupPreloadProgress progress)? onProgress,
  }) async {
    debugPrint('[startup] preload begin');

    final int totalAssets =
        AssetPaths.preloadImageCacheKeys.length +
        AssetPaths.preloadAudioCacheKeys.length +
        AssetPaths.preloadBundleAssets.length;
    int loadedAssets = 0;

    void emitProgress({
      required String category,
      required String asset,
      required int loaded,
    }) {
      onProgress?.call(
        StartupPreloadProgress(
          loaded: loaded,
          total: totalAssets,
          category: category,
          asset: asset,
        ),
      );
    }

    emitProgress(category: 'startup', asset: 'prepare', loaded: loadedAssets);

    for (final String imageCacheKey in AssetPaths.preloadImageCacheKeys) {
      try {
        await Flame.images.load(imageCacheKey);
        loadedAssets += 1;
        emitProgress(
          category: 'image',
          asset: imageCacheKey,
          loaded: loadedAssets,
        );
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
        loadedAssets += 1;
        emitProgress(
          category: 'audio',
          asset: audioCacheKey,
          loaded: loadedAssets,
        );
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
        loadedAssets += 1;
        emitProgress(
          category: 'bundle',
          asset: bundleAsset,
          loaded: loadedAssets,
        );
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

class StartupPreloadProgress {
  const StartupPreloadProgress({
    required this.loaded,
    required this.total,
    required this.category,
    required this.asset,
  });

  final int loaded;
  final int total;
  final String category;
  final String asset;

  double get fraction {
    if (total == 0) {
      return 1;
    }
    return loaded / total;
  }
}
