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
  static const double worldCellSize = 100;
  static final Vector2 worldSize = Vector2(3200, 3200);
  static final Vector2 playerSpawn = worldSize / 2;
}
