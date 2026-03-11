import 'package:game_jam/core/config/gameplay_tuning.dart';

abstract final class AssetPaths {
  // World and menu sprites.
  static const String splashScreen = 'assets/images/splash_screen.png';
  static const String plank = 'assets/images/plank.png';
  static const String plankLight = 'assets/images/plank_light.png';
  static const String plankDark = 'assets/images/plank_dark.png';
  static const String plankPanel1CacheKey = 'planks_panel_1.png';
  static const String plankPanel2CacheKey = 'planks_panel_2.png';
  static const String waterLily = 'assets/images/water_lily.png';
  static const String waterLilyAlt = 'assets/images/water_lily_1.png';
  static const String fly = 'assets/images/fly.png';
  static const String eggs = 'assets/images/eggs.png';
  static const String thorns1 = 'assets/images/environment/Ronces1.png';
  static const String thorns2 = 'assets/images/environment/Ronces2.png';
  static const String thorns3 = 'assets/images/environment/Ronces3.png';

  // HUD and overlay art.
  static const String uiTooltip = 'assets/images/ui/tooltip.png';
  static const String uiHeartLogo = 'assets/images/ui/health_logo.png';
  static const String uiRefreshLogo = 'assets/images/ui/refresh_logo.png';
  static const String uiIntelligenceLogo =
      'assets/images/ui/intelligence_logo.png';
  static const String uiSpeedLogo = 'assets/images/ui/speed_logo.png';

  // Data and audio assets.
  static const String characterPools = 'assets/data/character_pools.json';
  static const String splashAudioEffect = 'sound_effects/whawhawhawhoua.wav';
  static const String victoryMusic = 'victory.mp3';
  static const String jumpSfx1 = 'sound_effects/jump1.wav';
  static const String jumpSfx2 = 'sound_effects/jump2.wav';
  static const String waterSplashMidSfx = 'sound_effects/water-splash-mid.wav';

  // Flame image cache keys.
  static const String uiRefreshLogoCacheKey = 'ui/refresh_logo.png';
  static const String splashScreenCacheKey = 'splash_screen.png';
  static const String plankCacheKey = 'plank.png';
  static const String plankLightCacheKey = 'plank_light.png';
  static const String plankDarkCacheKey = 'plank_dark.png';
  static const String waterLilyCacheKey = 'water_lily.png';
  static const String waterLilyAltCacheKey = 'water_lily_1.png';
  static const String flyCacheKey = 'fly.png';
  static const String eggsCacheKey = 'eggs.png';
  static const String thorns1CacheKey = 'environment/Ronces1.png';
  static const String thorns2CacheKey = 'environment/Ronces2.png';
  static const String thorns3CacheKey = 'environment/Ronces3.png';

  static List<String> get thornsAnimationCacheKeys => <String>[
    thorns1CacheKey,
    thorns2CacheKey,
    thorns3CacheKey,
  ];

  //texture Assets
  static const String waterTexture = 'water_texture.png';

  static String frogSpriteAssetPath(int number) {
    return 'assets/images/gronouy/frog-$number.png';
  }

  static String frogSpriteCacheKey(int number) {
    return 'gronouy/frog-$number.png';
  }

  static List<String> frogAnimatedSpriteCacheKey(int number) {
    return [
      'gronouy/frog-$number/Saut1.png',
      'gronouy/frog-$number/Saut2.png',
      'gronouy/frog-$number/Chill.png',
      'gronouy/frog-$number/Nage1.png',
      'gronouy/frog-$number/Nage2.png',
      if (number == 14) 'gronouy/frog-$number/Chillsousleau.png',
      if (number == 14) 'gronouy/frog-$number/Nage1sousleau.png',
      if (number == 14) 'gronouy/frog-$number/Nage2sousleau.png',
    ];
  }

  static String imageCacheKeyFromAssetPath(String path) {
    const String imageAssetPrefix = 'assets/images/';
    if (path.startsWith(imageAssetPrefix)) {
      return path.substring(imageAssetPrefix.length);
    }
    return path;
  }

  static List<int> animatedFrogSpriteId = [10, 11, 12, 13, 14];

  static List<String> get preloadImageCacheKeys => <String>[
    plankCacheKey,
    plankLightCacheKey,
    plankDarkCacheKey,
    plankPanel1CacheKey,
    plankPanel2CacheKey,
    waterLilyCacheKey,
    waterLilyAltCacheKey,
    flyCacheKey,
    eggsCacheKey,
    ...thornsAnimationCacheKeys,
    uiRefreshLogoCacheKey,
    ...animatedFrogSpriteId.expand((id) => frogAnimatedSpriteCacheKey(id)),
    ...List<String>.generate(GameplayTuning.frogSpriteCount, (int index) {
      if (animatedFrogSpriteId.contains(index + 1)) {
        return '';
      }
      return frogSpriteCacheKey(index + 1);
    }, growable: false).where((path) => path.isNotEmpty),
    waterTexture,
  ];

  static List<String> get preloadAudioCacheKeys => <String>[
    splashAudioEffect,
    victoryMusic,
    jumpSfx1,
    jumpSfx2,
    waterSplashMidSfx,
  ];

  static List<String> get preloadBundleAssets => <String>[
    splashScreen,
    uiTooltip,
    uiHeartLogo,
    uiIntelligenceLogo,
    uiSpeedLogo,
    characterPools,
  ];
}
