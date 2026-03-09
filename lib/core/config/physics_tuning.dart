abstract final class PhysicsTuning {
  // Base player body and movement.
  static const double playerBaseSize = 96;
  static const double playerMoveSpeed = 340;
  static const double playerRotationSpeed = 30;

  // Jump movement and timing.
  static const double jumpDurationSeconds = 0.24;
  static const double jumpForwardSpeed = 420;
  static const double jumpForwardScaleDecay = 0.6;
  static const double minJumpForwardScale = 0.35;

  // Trait multiplier clamps.
  static const double minSpeedMultiplier = 0.2;
  static const double maxSpeedMultiplier = 5.0;
  static const double minSizeMultiplier = 0.3;
  static const double maxSizeMultiplier = 3.0;

  // Sprite opacity by vertical layer.
  static const double landOpacity = 1.0;
  static const double waterOpacity = 0.7;
  static const double underwaterOpacity = 0.4;

  // Bird enemy component.
  static const double birdEnemySpeed = 200;
  static const double birdEnemyDirectionChangeInterval = 2;
  static const double birdEnemyMargin = 60;
  static const double birdEnemyFacingFlipDeadZone = 8;
  static const double birdEnemyScaleUpDistance = 400;
  static const double birdEnemyDamageInterval = 1;
  static const double birdEnemyDamageRange = 80;
  static const int birdEnemyDamageAmount = 10;
  static const double birdEnemyDescentDuration = 1;
  static const double birdEnemyDescentHeight = 140;
}
