import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/config/gameplay_tuning.dart';
import 'package:game_jam/game/world/world_mixin.dart';

void main() {
  test('never spawns interior thorn in water or spawn zone', () {
    expect(
      WorldMixin.shouldSpawnInteriorThorn(
        isWaterCell: true,
        inSpawnZone: false,
        inCandidateSafeZone: false,
        thornNoiseValue: GameplayTuning.thornPatchThresholdMin,
        thornPatchRoll: 0,
      ),
      isFalse,
    );
    expect(
      WorldMixin.shouldSpawnInteriorThorn(
        isWaterCell: false,
        inSpawnZone: true,
        inCandidateSafeZone: false,
        thornNoiseValue: GameplayTuning.thornPatchThresholdMin,
        thornPatchRoll: 0,
      ),
      isFalse,
    );
    expect(
      WorldMixin.shouldSpawnInteriorThorn(
        isWaterCell: false,
        inSpawnZone: false,
        inCandidateSafeZone: true,
        thornNoiseValue: GameplayTuning.thornPatchThresholdMin,
        thornPatchRoll: 0,
      ),
      isFalse,
    );
  });

  test('spawns interior thorn only inside tuned noise and chance windows', () {
    expect(
      WorldMixin.shouldSpawnInteriorThorn(
        isWaterCell: false,
        inSpawnZone: false,
        inCandidateSafeZone: false,
        thornNoiseValue: GameplayTuning.thornPatchThresholdMin,
        thornPatchRoll: GameplayTuning.thornPatchSpawnChance,
      ),
      isTrue,
    );
    expect(
      WorldMixin.shouldSpawnInteriorThorn(
        isWaterCell: false,
        inSpawnZone: false,
        inCandidateSafeZone: false,
        thornNoiseValue: GameplayTuning.thornPatchThresholdMax + 1,
        thornPatchRoll: GameplayTuning.thornPatchSpawnChance,
      ),
      isFalse,
    );
    expect(
      WorldMixin.shouldSpawnInteriorThorn(
        isWaterCell: false,
        inSpawnZone: false,
        inCandidateSafeZone: false,
        thornNoiseValue: GameplayTuning.thornPatchThresholdMin,
        thornPatchRoll: GameplayTuning.thornPatchSpawnChance + 1,
      ),
      isFalse,
    );
  });

  test('candidate safe-zone spawn positions stay in safe zone', () {
    final positions = WorldMixin.candidateSafeZoneSpawnPositions(count: 5);

    expect(positions, hasLength(5));
    for (final position in positions) {
      expect(WorldMixin.isInCandidateSafeZone(position: position), isTrue);
    }
  });

  test('candidate safe-zone center is clamped away from world borders', () {
    final center = WorldMixin.candidateSafeZoneCenter(
      preferredCenter: Vector2(0, 0),
    );
    final positions = WorldMixin.candidateSafeZoneSpawnPositions(
      count: 5,
      safeZoneCenter: center,
    );

    for (final position in positions) {
      expect(position.x, greaterThan(0));
      expect(position.y, greaterThan(0));
    }
  });

  test('candidate safe-zone center clamps to max world bounds', () {
    final center = WorldMixin.candidateSafeZoneCenter(
      preferredCenter: Vector2(999999, 999999),
    );

    expect(center.x, lessThan(GameConfig.worldSize.x));
    expect(center.y, lessThan(GameConfig.worldSize.y));
  });

  test('candidate safe-zone spawn positions handle edge counts', () {
    expect(WorldMixin.candidateSafeZoneSpawnPositions(count: 0), isEmpty);

    final center = WorldMixin.candidateSafeZoneCenter();
    final single = WorldMixin.candidateSafeZoneSpawnPositions(count: 1);

    expect(single, hasLength(1));
    expect(single.first.x, closeTo(center.x, 0.0001));
    expect(single.first.y, closeTo(center.y, 0.0001));
  });

  test('candidate safe-zone spawn positions are deterministic', () {
    final customCenter = Vector2(640, 640);
    final first = WorldMixin.candidateSafeZoneSpawnPositions(
      count: GameplayTuning.menuCharacterCandidateCount,
      safeZoneCenter: customCenter,
    );
    final second = WorldMixin.candidateSafeZoneSpawnPositions(
      count: GameplayTuning.menuCharacterCandidateCount,
      safeZoneCenter: customCenter,
    );

    expect(first, hasLength(second.length));
    for (int i = 0; i < first.length; i++) {
      expect(first[i].x, closeTo(second[i].x, 0.0001));
      expect(first[i].y, closeTo(second[i].y, 0.0001));
    }
  });

  test('isInCandidateSafeZone returns false for clearly outside point', () {
    final center = WorldMixin.candidateSafeZoneCenter();
    final outside = Vector2(center.x + 1000, center.y + 1000);

    expect(WorldMixin.isInCandidateSafeZone(position: outside), isFalse);
  });

  test('thorn cannot spawn for cells inside candidate safe zone', () {
    final safeCenter = WorldMixin.candidateSafeZoneCenter();
    final inSafeZone = WorldMixin.isInCandidateSafeZone(position: safeCenter);

    expect(inSafeZone, isTrue);
    expect(
      WorldMixin.shouldSpawnInteriorThorn(
        isWaterCell: false,
        inSpawnZone: false,
        inCandidateSafeZone: inSafeZone,
        thornNoiseValue: GameplayTuning.thornPatchThresholdMin,
        thornPatchRoll: 0,
      ),
      isFalse,
    );
  });
}
