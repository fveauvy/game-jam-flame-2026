import 'package:game_jam/core/constants/gameplay_tuning.dart';

abstract final class AssetPaths {
  static const String splashScreen = 'assets/images/splash_screen.png';
  static const String plank = 'assets/images/plank.png';
  static const String waterLily = 'assets/images/water_lily.png';
  static const String waterLilyAlt = 'assets/images/water_lily_1.png';
  static const String fly = 'assets/images/fly.png';
  static const String eggs = 'assets/images/eggs.png';

  static const String uiTooltip = 'assets/images/ui/tooltip.png';
  static const String uiHeartLogo = 'assets/images/ui/health_logo.png';
  static const String uiIntelligenceLogo =
      'assets/images/ui/intelligence_logo.png';
  static const String uiSpeedLogo = 'assets/images/ui/speed_logo.png';

  static const String characterPools = 'assets/data/character_pools.json';

  static const String splashScreenCacheKey = 'splash_screen.png';
  static const String plankCacheKey = 'plank.png';
  static const String waterLilyCacheKey = 'water_lily.png';
  static const String waterLilyAltCacheKey = 'water_lily_1.png';
  static const String flyCacheKey = 'fly.png';
  static const String eggsCacheKey = 'eggs.png';

  static const String splashAudioEffect = 'sound_effects/whawhawhawhoua.wav';

  static String frogSpriteAssetPath(int number) {
    return 'assets/images/gronouy/frog-$number.png';
  }

  static String frogSpriteCacheKey(int number) {
    return 'gronouy/frog-$number.png';
  }

  static String imageCacheKeyFromAssetPath(String path) {
    const String imageAssetPrefix = 'assets/images/';
    if (path.startsWith(imageAssetPrefix)) {
      return path.substring(imageAssetPrefix.length);
    }
    return path;
  }

  static List<String> get preloadImageCacheKeys => <String>[
    plankCacheKey,
    waterLilyCacheKey,
    waterLilyAltCacheKey,
    flyCacheKey,
    eggsCacheKey,
    ...List<String>.generate(
      GameplayTuning.frogSpriteCount,
      (int index) => frogSpriteCacheKey(index + 1),
      growable: false,
    ),
  ];

  static List<String> get preloadAudioCacheKeys => <String>[splashAudioEffect];

  static List<String> get preloadBundleAssets => <String>[
    splashScreen,
    uiTooltip,
    uiHeartLogo,
    uiIntelligenceLogo,
    uiSpeedLogo,
    characterPools,
  ];
}
