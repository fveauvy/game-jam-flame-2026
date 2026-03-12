import 'package:flame/components.dart';

abstract final class GameConfig {
  // App identity and deterministic defaults.
  static const String title = "Gronouy: Tadpole's Big Frogger";
  static const String defaultCharacterSeedCode = '6DCE9';

  // Camera and fixed-resolution world viewport.
  static const double baseWidth = 960;
  static const double baseHeight = 540;
  static const double maxDeltaTime = 1 / 30;

  // World geometry and spawn anchors.
  static final Vector2 worldSize = Vector2(2200, 1200);
  static final Vector2 playerSpawn = Vector2(180, 920);
  static const double groundY = 980;
}
