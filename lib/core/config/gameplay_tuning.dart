abstract final class GameplayTuning {
  // Character and sprite generation.
  static const int frogSpriteCount = 30;
  static const int characterRerollAttempts = 8;

  // Initial world population.
  static const int initialFlyCount = 10;
  static const int initialEggCount = 20;
  static const double worldPickupSize = 32;
  static const int eggSpawnMaxRetries = 96;

  // HUD and sampling behavior.
  static const double hudFpsSampleWindowSeconds = 0.25;

  // Menu candidate generation and navigation.
  static const int menuCharacterCandidateCount = 5;
  static const int menuCharacterCandidateSeedStep = 7919;
  static const int menuCharacterCandidateUniqueAttempts = 64;
  static const double menuNavigationRepeatIntervalSeconds = 0.18;
  static const double menuNavigationAxisThreshold = 0.5;

  // Shared input thresholds.
  static const double gamepadButtonPressedValue = 1;

  // Thorn world generation.
  static const double thornPatchNoiseFrequency = 0.12;
  static const double thornPatchThresholdMin = 0.56;
  static const double thornPatchThresholdMax = 0.69;
  static const double thornPatchSpawnChance = 0.35;

  // Thorn animation.
  static const double thornAnimationFrameSeconds = 0.2;
}
