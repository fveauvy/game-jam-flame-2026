import 'package:flame/components.dart';

abstract final class GameConfig {
  static const String title = "Gronouy: Tadpole's Big Frother";
  static const String defaultCharacterSeedCode = '4SFE6';
  static const double baseWidth = 960;
  static const double baseHeight = 540;
  static const double maxDeltaTime = 1 / 30;
  static const String uiTooltipAssetPath = 'assets/images/ui/tooltip.png';
  static const String uiHeartLogoAssetPath = 'assets/images/ui/heart_logo.png';
  static const String uiIntelligenceLogoAssetPath =
      'assets/images/ui/intelligence_logo.png';
  static const String uiSpeedLogoAssetPath = 'assets/images/ui/speed_logo.png';
  static final Vector2 worldSize = Vector2(2200, 1200);
  static final Vector2 playerSpawn = Vector2(180, 920);
  static const double groundY = 980;
}
