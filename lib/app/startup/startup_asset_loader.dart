import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:game_jam/core/config/asset_paths.dart';

class StartupAssetLoader {
  static const int _maxConcurrentLoads = 8;

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

    final List<_PreloadTask> tasks = <_PreloadTask>[
      ...AssetPaths.preloadImageCacheKeys.map(
        (String imageCacheKey) => _PreloadTask(
          category: 'image',
          asset: imageCacheKey,
          load: () async {
            await Flame.images.load(imageCacheKey);
          },
        ),
      ),
      ...AssetPaths.preloadAudioCacheKeys.map(
        (String audioCacheKey) => _PreloadTask(
          category: 'audio',
          asset: audioCacheKey,
          load: () async {
            await FlameAudio.audioCache.load(audioCacheKey);
          },
        ),
      ),
      ...AssetPaths.preloadBundleAssets.map(
        (String bundleAsset) => _PreloadTask(
          category: 'bundle',
          asset: bundleAsset,
          load: () async {
            await rootBundle.load(bundleAsset);
          },
        ),
      ),
    ];

    int nextIndex = 0;

    Future<void> worker() async {
      while (nextIndex < tasks.length) {
        final _PreloadTask task = tasks[nextIndex++];
        try {
          await task.load();
          loadedAssets += 1;
          emitProgress(
            category: task.category,
            asset: task.asset,
            loaded: loadedAssets,
          );
        } catch (error, stackTrace) {
          throw StartupPreloadException(
            asset: task.asset,
            category: task.category,
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
    }

    final int workerCount = tasks.length < _maxConcurrentLoads
        ? tasks.length
        : _maxConcurrentLoads;
    await Future.wait(
      List<Future<void>>.generate(workerCount, (_) => worker()),
      eagerError: true,
    );

    debugPrint('[startup] preload complete');
  }
}

class _PreloadTask {
  const _PreloadTask({
    required this.category,
    required this.asset,
    required this.load,
  });

  final String category;
  final String asset;
  final Future<void> Function() load;
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
