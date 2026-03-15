import 'package:game_jam/core/config/gameplay_tuning.dart';

abstract final class AssetPaths {
  // World and menu sprites.
  static const String splashScreen = 'assets/images/splash_screen.png';
  static const String plank = 'assets/images/plank.png';
  static const String plankLight = 'assets/images/plank_light.png';
  static const String plankDark = 'assets/images/plank_dark.png';
  static const String plankPanel1CacheKey = 'planks_panel_1.png';
  static const String plankPanel2CacheKey = 'planks_panel_2.png';
  static const String fly = 'assets/images/fly.png';
  static const String eggs = 'assets/images/eggs.png';
  static const String bigEgg = 'assets/images/big_egg.png';
  static const String thorns1 = 'assets/images/environment/Ronces1.png';
  static const String thorns2 = 'assets/images/environment/Ronces2.png';
  static const String thorns3 = 'assets/images/environment/Ronces3.png';
  static const String leaf = 'assets/images/environment/Feuille.png';

  // HUD and overlay art.
  static const String uiTooltip = 'assets/images/ui/tooltip.png';
  static const String uiHeartLogo = 'assets/images/ui/health_logo.png';
  static const String uiRefreshLogo = 'assets/images/ui/refresh_logo.png';
  static const String uiIntelligenceLogo =
      'assets/images/ui/intelligence_logo.png';
  static const String uiSpeedLogo = 'assets/images/ui/speed_logo.png';
  static const String uiTitle = 'assets/images/ui/title.png';

  // Data and audio assets.
  static const String characterPools = 'assets/data/character_pools.json';
  static const String splashAudioEffect = 'sound_effects/whawhawhawhoua.wav';
  static const String victoryMusic = 'victory.mp3';
  static const String jumpSfx1 = 'sound_effects/jump1.wav';
  static const String jumpSfx2 = 'sound_effects/jump2.wav';
  static const String waterSplashMidSfx = 'sound_effects/water-splash-mid.wav';
  static const String tongueLickSfx = 'sound_effects/coup-de-langue.mp3';
  static const String birdDiveSfx = 'sound_effects/bird-dive.mp3';
  static const String frogCroakSfx = 'sound_effects/frog-croaks.mp3';
  static const String frogMenuSfx1 = 'sound_effects/gronouy1.mp3';
  static const String frogMenuSfx2 = 'sound_effects/gronouy2.mp3';
  static const String frogMenuSfx3 = 'sound_effects/gronouy3.mp3';
  static const String frogMenuSfx4 = 'sound_effects/gronouy4.mp3';
  static const String frogMenuSfx5 = 'sound_effects/gronouy5.mp3';
  static const String frogMenuSfx6 = 'sound_effects/gronouy6.mp3';
  static const String frogMenuSfx7 = 'sound_effects/gronouy7.mp3';

  // Flame image cache keys.
  static const String titleCacheKey = 'ui/title.png';
  static const String uiRefreshLogoCacheKey = 'ui/refresh_logo.png';
  static const String splashScreenCacheKey = 'splash_screen.png';
  static const String plankCacheKey = 'plank.png';
  static const String plankLightCacheKey = 'plank_light.png';
  static const String plankDarkCacheKey = 'plank_dark.png';
  static const String waterLilyCacheKey = 'environment/water-lily.webp';
  static const String flyCacheKey = 'fly.png';
  static const String eggsCacheKey = 'eggs.png';
  static const String bigEggCacheKey = 'big_egg.png';
  static const String thorns1CacheKey = 'environment/Ronces1.png';
  static const String thorns2CacheKey = 'environment/Ronces2.png';
  static const String thorns3CacheKey = 'environment/Ronces3.png';
  static const String leafCacheKey = 'environment/Feuille.png';
  static const String tongue1CacheKey = 'gronouy/Langue1.png';
  static const String tongue2CacheKey = 'gronouy/Langue2.png';
  static const String tongue3CacheKey = 'gronouy/Langue3.png';

  // Mud components (tiles).
  static const mudInvertedCornerTopLeft =
      'environment/mud/mud-inverted-corner-top-left.png';
  static const mudInvertedCornerTopRight =
      'environment/mud/mud-inverted-corner-top-right.png';
  static const mudInvertedCornerBottomLeft =
      'environment/mud/mud-inverted-corner-bottom-left.png';
  static const mudInvertedCornerBottomRight =
      'environment/mud/mud-inverted-corner-bottom-right.png';
  static const mudLeft = 'environment/mud/mud-flat-left.png';
  static const mudRight = 'environment/mud/mud-flat-right.png';
  static const mudUp = 'environment/mud/mud-flat-top.png';
  static const mudDown = 'environment/mud/mud-flat-bottom.png';
  static const mudPlain1 = 'environment/mud/mud-plain-1.png';
  static const mudPlain2 = 'environment/mud/mud-plain-2.png';
  static const mudPlain3 = 'environment/mud/mud-plain-3.png';

  static List<String> get mudTilesCacheKeys => <String>[
    mudInvertedCornerTopLeft,
    mudInvertedCornerTopRight,
    mudInvertedCornerBottomLeft,
    mudInvertedCornerBottomRight,
    mudLeft,
    mudRight,
    mudUp,
    mudDown,
    mudPlain1,
    mudPlain2,
    mudPlain3,
  ];

  // Water components.
  static const waterCornerTopLeft =
      'environment/water/water-corner-top-left.png';
  static const waterCornerTopRight =
      'environment/water/water-corner-top-right.png';
  static const waterCornerBottomLeft =
      'environment/water/water-corner-bottom-left.png';
  static const waterCornerBottomRight =
      'environment/water/water-corner-bottom-right.png';
  static const waterInvertedCornerTopLeft =
      'environment/water/water-inverted-top-left.png';
  static const waterInvertedCornerTopRight =
      'environment/water/water-inverted-top-right.png';
  static const waterInvertedCornerBottomLeft =
      'environment/water/water-inverted-bottom-left.png';
  static const waterInvertedCornerBottomRight =
      'environment/water/water-inverted-bottom-right.png';
  static const waterLeft = 'environment/water/water-flat-left.png';
  static const waterRight = 'environment/water/water-flat-right.png';
  static const waterUp = 'environment/water/water-flat-top.png';
  static const waterDown = 'environment/water/water-flat-bottom.png';

  static List<String> get waterAnimationCacheKeys => <String>[
    waterCornerTopLeft,
    waterCornerTopRight,
    waterCornerBottomLeft,
    waterCornerBottomRight,
    waterInvertedCornerTopLeft,
    waterInvertedCornerTopRight,
    waterInvertedCornerBottomLeft,
    waterInvertedCornerBottomRight,
    waterLeft,
    waterRight,
    waterUp,
    waterDown,
  ];

  // ground components.
  static const ground = 'environment/ground/ground.webp';
  static const ground1 = 'environment/ground/ground2.webp';
  static const ground2 = 'environment/ground/ground3.webp';

  static List<String> get groundAnimationCacheKeys => <String>[
    ground,
    ground1,
    ground2,
  ];

  static const int croqueAnimationFrames = 20;
  static const String croqueAnimationPrefix = "croque/croque_";

  static List<String> get thornsAnimationCacheKeys => <String>[
    thorns1CacheKey,
    thorns2CacheKey,
    thorns3CacheKey,
  ];

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
      if (animatedFrogSpriteId.contains(number))
        'gronouy/frog-$number/Chillsousleau.png',
      if (animatedFrogSpriteId.contains(number))
        'gronouy/frog-$number/Nage1sousleau.png',
      if (animatedFrogSpriteId.contains(number))
        'gronouy/frog-$number/Nage2sousleau.png',
    ];
  }

  static String birdAnimatedSpriteCacheKey(int number) {
    return 'birds/oiseau$number.webp';
  }

  static String birdShadowAnimatedSpriteCacheKey(int number) {
    return 'birds/ombre$number.webp';
  }

  static String birdFloutixMaxAnimatedSpriteCacheKey(int number) {
    return 'birds/floutixmax$number.webp';
  }

  static String birdFloutixAnimatedSpriteCacheKey(int number) {
    return 'birds/floutix$number.webp';
  }

  static String imageCacheKeyFromAssetPath(String path) {
    const String imageAssetPrefix = 'assets/images/';
    if (path.startsWith(imageAssetPrefix)) {
      return path.substring(imageAssetPrefix.length);
    }
    return path;
  }

  static List<int> animatedFrogSpriteId = [10, 11, 12, 13, 14];

  static List<int> birdSpriteId = [1, 2];
  static List<int> birdShadowSpriteId = [1, 2];
  static List<int> birdFloutixMaxSpriteId = [1, 2];
  static List<int> birdFloutixSpriteId = [1, 2];

  static List<String> get preloadImageCacheKeys => <String>[
    plankCacheKey,
    plankLightCacheKey,
    plankDarkCacheKey,
    plankPanel1CacheKey,
    plankPanel2CacheKey,
    waterLilyCacheKey,
    flyCacheKey,
    eggsCacheKey,
    bigEggCacheKey,
    titleCacheKey,
    ...thornsAnimationCacheKeys,
    leafCacheKey,
    tongue1CacheKey,
    tongue2CacheKey,
    tongue3CacheKey,
    uiRefreshLogoCacheKey,
    ...waterAnimationCacheKeys,
    ...mudTilesCacheKeys,
    ...groundAnimationCacheKeys,
    ...animatedFrogSpriteId.expand((id) => frogAnimatedSpriteCacheKey(id)),
    ...List<String>.generate(GameplayTuning.frogSpriteCount, (int index) {
      if (animatedFrogSpriteId.contains(index + 1)) {
        return '';
      }
      return frogSpriteCacheKey(index + 1);
    }, growable: false).where((path) => path.isNotEmpty),
    ...birdSpriteId.map((id) => birdAnimatedSpriteCacheKey(id)),
    ...birdShadowSpriteId.map((id) => birdShadowAnimatedSpriteCacheKey(id)),
    ...birdFloutixMaxSpriteId.map(
      (id) => birdFloutixMaxAnimatedSpriteCacheKey(id),
    ),
    ...birdFloutixSpriteId.map((id) => birdFloutixAnimatedSpriteCacheKey(id)),
    ...List<String>.generate(croqueAnimationFrames, (index) {
      final frameNumber = index;
      return 'croque/croque_$frameNumber.png';
    }),
  ];

  static List<String> get preloadAudioCacheKeys => <String>[
    splashAudioEffect,
    victoryMusic,
    jumpSfx1,
    jumpSfx2,
    waterSplashMidSfx,
    tongueLickSfx,
    birdDiveSfx,
    frogCroakSfx,
    frogMenuSfx1,
    frogMenuSfx2,
    frogMenuSfx3,
    frogMenuSfx4,
    frogMenuSfx5,
    frogMenuSfx6,
    frogMenuSfx7,
  ];

  static List<String> get frogMenuVoiceSfx => <String>[
    frogMenuSfx1,
    frogMenuSfx2,
    frogMenuSfx3,
    frogMenuSfx4,
    frogMenuSfx5,
    frogMenuSfx6,
    frogMenuSfx7,
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
