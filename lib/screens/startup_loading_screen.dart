import 'package:flutter/material.dart';

class StartupLoadingScreen extends StatelessWidget {
  const StartupLoadingScreen({
    super.key,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final String status = isLoading
        ? 'Loading assets...'
        : 'Loading failed. retry.';

    return ColoredBox(
      color: const Color(0xFF102B28),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF1A403A),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF68A99B), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      const CircularProgressIndicator(color: Color(0xFFD6F4ED))
                    else
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFF7D18A),
                        size: 44,
                      ),
                    const SizedBox(height: 16),
                    Text(
                      status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFD6F4ED),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFB7D9D2),
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (!isLoading && onRetry != null) ...[
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: onRetry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
