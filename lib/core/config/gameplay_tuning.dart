abstract final class GameplayTuning {
  // Character and sprite generation.
  static const int frogSpriteCount = 30;
  static const int characterRerollAttempts = 8;

  ///minus 1 every 0,5 seconds
  static const int initialMoistureLevel = 10;

  // Initial world population.
  static const int initialFlyCount = 10;
  static const int initialEggCount = 20;
  static const double maxEggs = 5;
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
  static const bool gamepadDebugLogs = false;

  // Frog tongue and fly healing.
  static const int flyHealAmount = 12;
  static const double tongueCooldownSeconds = 0.45;
  static const double tongueActiveSeconds = 0.22;
  static const double tongueAnimationStepSeconds = 0.07;
  static const double tongueWidth = 50;
  static const double tongueHeight = 180;
  static const double tongueHitboxWidthFactor = 0.8;
  static const double tongueHitboxHeightFactor = 1.0;
  static const double tongueMouthOffsetFactor = 0.28;
  static const double tongueMouthOffsetPixels = 0;
  static const double tongueSfxVolume = 0.8;

  // Healing feedback.
  static const double healingTextOffsetX = -8;
  static const double healingTextOffsetY = -12;
  static const double healingTextRiseDistance = 18;
  static const double healingTextRiseDurationSeconds = 0.45;
  static const int healingTextLifetimeMs = 500;

  // Fly collision.
  static const double flyHitboxRadiusFactor = 0.35;

  // Thorn world generation.
  static const double thornPatchNoiseFrequency = 0.12;
  static const double thornPatchThresholdMin = 0.56;
  static const double thornPatchThresholdMax = 0.69;
  static const double thornPatchSpawnChance = 0.35;

  // Thorn animation.
  static const double thornAnimationFrameSeconds = 0.2;

  // Fish enemy spawning.
  static const int fishEnemyCount = 3;
  static const double fishEnemySize = 150;
  static const double fishMinSpawnDistance = 600;
  static const double minFishSpacing = 400;
}
