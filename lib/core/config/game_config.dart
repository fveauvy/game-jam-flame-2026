import 'package:flame/components.dart';

abstract final class GameConfig {
  static const String title = 'Flame Jam Template';
  static const int defaultCharacterSeed = 1337;
  static const double baseWidth = 960;
  static const double baseHeight = 540;
  static const double maxDeltaTime = 1 / 30;
  static final Vector2 worldSize = Vector2(2200, 1200);
  static final Vector2 playerSpawn = Vector2(180, 920);
  static const double groundY = 980;
}
