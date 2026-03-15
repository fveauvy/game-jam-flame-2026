import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_jam/core/config/asset_paths.dart';

class StartupSplashScreen extends StatelessWidget {
  const StartupSplashScreen({
    super.key,
    required this.isLoading,
    this.progress = 0,
    this.loadedAssets = 0,
    this.totalAssets = 0,
    this.statusLabel,
    this.errorMessage,
    this.onRetry,
  });

  final bool isLoading;
  final double progress;
  final int loadedAssets;
  final int totalAssets;
  final String? statusLabel;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final bool isLoadingComplete =
        isLoading && totalAssets > 0 && loadedAssets >= totalAssets;

    return ColoredBox(
      color: const Color(0xFF3F7D73),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AssetPaths.startupSplashBackground,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          ),
          SizedBox.expand(
            child: _OneShotGif(
              assetPath: AssetPaths.startupSplashAnimation,
              frameDurationMultiplier: 1.8,
              fit: BoxFit.contain,
              fallback: Image.asset(
                AssetPaths.splashScreen,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    'Gronouy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
            ),
          ),
          if (!isLoadingComplete)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xCC102B28),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF68A99B),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isLoading ? 'Loading assets...' : 'Loading failed',
                            style: const TextStyle(
                              color: Color(0xFFD6F4ED),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(8),
                            backgroundColor: const Color(0xFF274E47),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFD6F4ED),
                            ),
                            value: isLoading ? progress.clamp(0, 1) : 1,
                          ),
                          if (isLoading) ...[
                            const SizedBox(height: 8),
                            Text(
                              totalAssets > 0
                                  ? '$loadedAssets / $totalAssets'
                                  : 'Preparing...',
                              style: const TextStyle(
                                color: Color(0xFFB7D9D2),
                                fontSize: 13,
                              ),
                            ),
                            if (statusLabel != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                statusLabel!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFB7D9D2),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                          if (!isLoading) ...[
                            if (errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFB7D9D2),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (onRetry != null) ...[
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: onRetry,
                                child: const Text('Retry'),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OneShotGif extends StatefulWidget {
  const _OneShotGif({
    required this.assetPath,
    required this.fallback,
    this.frameDurationMultiplier = 1,
    this.fit,
    this.width,
    this.height,
  }) : assert(frameDurationMultiplier > 0);

  final String assetPath;
  final Widget fallback;
  final double frameDurationMultiplier;
  final BoxFit? fit;
  final double? width;
  final double? height;

  @override
  State<_OneShotGif> createState() => _OneShotGifState();
}

class _OneShotGifState extends State<_OneShotGif> {
  final List<_GifFrame> _frames = <_GifFrame>[];
  Timer? _frameTimer;
  int _currentFrameIndex = 0;
  bool _isLoading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadFrames();
  }

  @override
  void didUpdateWidget(covariant _OneShotGif oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _loadFrames();
    }
  }

  Future<void> _loadFrames() async {
    _frameTimer?.cancel();
    _disposeFrames();
    _currentFrameIndex = 0;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadFailed = false;
      });
    }

    try {
      final data = await rootBundle.load(widget.assetPath);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final List<_GifFrame> decodedFrames = <_GifFrame>[];

      for (int index = 0; index < codec.frameCount; index++) {
        final frame = await codec.getNextFrame();
        decodedFrames.add(
          _GifFrame(image: frame.image, duration: frame.duration),
        );
      }
      codec.dispose();

      if (!mounted) {
        for (final frame in decodedFrames) {
          frame.image.dispose();
        }
        return;
      }

      _frames.addAll(decodedFrames);
      setState(() {
        _isLoading = false;
        _loadFailed = _frames.isEmpty;
      });
      _scheduleNextFrame();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  void _scheduleNextFrame() {
    _frameTimer?.cancel();
    if (_frames.isEmpty || _currentFrameIndex >= _frames.length - 1) {
      return;
    }

    final frameDuration = _frames[_currentFrameIndex].duration;
    final safeDuration = frameDuration > Duration.zero
        ? frameDuration
        : const Duration(milliseconds: 100);
    final effectiveDuration = Duration(
      microseconds:
          (safeDuration.inMicroseconds * widget.frameDurationMultiplier)
              .round(),
    );

    _frameTimer = Timer(effectiveDuration, () {
      if (!mounted || _currentFrameIndex >= _frames.length - 1) {
        return;
      }
      setState(() {
        _currentFrameIndex += 1;
      });
      _scheduleNextFrame();
    });
  }

  void _disposeFrames() {
    for (final frame in _frames) {
      frame.image.dispose();
    }
    _frames.clear();
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _disposeFrames();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.expand();
    }
    if (_loadFailed || _frames.isEmpty) {
      return widget.fallback;
    }

    return RawImage(
      image: _frames[_currentFrameIndex].image,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      filterQuality: FilterQuality.high,
    );
  }
}

class _GifFrame {
  const _GifFrame({required this.image, required this.duration});

  final ui.Image image;
  final Duration duration;
}
