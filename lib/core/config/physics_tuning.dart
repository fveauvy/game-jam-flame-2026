abstract final class PhysicsTuning {
  // Base player body and movement.
  static const double playerBaseSize = 56;
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
  static const double waterOpacity = 0.85;
  static const double underwaterOpacity = 0.6;
  static const double underwaterSurfaceGraceSeconds = 0.2;

  // Bird enemy component.
  static const double birdEnemySpeed = 100;
  static const double birdEnemyAttackSpeed = 300;
  static const double birdEnemyRotationSpeed = 6.0;
  static const double birdEnemyScaleSpeed = 2.0;
  static const double birdEnemyFadeOutSpeed = 1.5;
  static const double birdEnemyMegaSizeWidth = 1000;
  static const double birdEnemyMegaSizeHeight = 1100;
  static const int birdEnemyDamageAmount = 5;
  static const double birdEnemyDamageInvincibilitySeconds = 5;
  // Shadow distances and alpha curve.
  static const double birdShadowAttackTriggerDistance = 150;
  static const double birdShadowFadeInStartDistance = 600;
  static const double birdShadowAlphaPeakDistance = 300;
  static const double birdShadowFadeOutEndDistance = 100;
  static const double birdShadowMaxDistance = 2500 / 2;
  static const double birdShadowMinAlpha = 0.4;
  static const double birdShadowMaxAlpha = 1.0;
  static const double birdShadowMaxTypeDistance = 600;
  static const double birdShadowNormalTypeDistance = 450;
  // Shadow scale and position animation.
  static const double birdShadowMaxSizeMultiplier = 1.5;
  static const double birdShadowScaleSpeed = 2.0;
  static const double birdShadowRetractScaleSpeed = 1.0;
  static const double birdShadowPositionLerpSpeed = 0.5;
  static const double birdShadowPositionOffsetX = 50;
  static const double birdShadowPositionOffsetY = 25;

  // Thorn hazard.
  static const int thornDamageAmount = 20;
  static const double thornInvincibilitySeconds = 0.9;
  static const double thornKnockbackSpeed = 620;
  static const double thornKnockbackDrag = 8;
  static const double thornKnockbackMinSpeed = 8;
  static const double thornFlickerStepSeconds = 0.08;
  static const double thornFlickerLowOpacity = 0.35;
  static const double thornFlashStepSeconds = 0.06;
  static const int thornParticleCount = 14;
  static const double thornParticleLifespanSeconds = 0.28;
  static const double thornParticleRadius = 5;
  static const double thornParticleSpeedMin = 70;
  static const double thornParticleSpeedMax = 240;
  static const double thornParticleAlpha = 0.8;

  /// Frog House
  static const double frogHouseSize = 200;
  static const double frogHousePositionOffset = 100;
}
