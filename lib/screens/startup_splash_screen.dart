import 'package:flutter/material.dart';
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
          Center(
            child: Image.asset(
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
