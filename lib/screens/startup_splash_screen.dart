import 'package:flutter/material.dart';
import 'package:game_jam/core/config/asset_paths.dart';

class StartupSplashScreen extends StatelessWidget {
  const StartupSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF3F7D73),
      child: Center(
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
    );
  }
}
