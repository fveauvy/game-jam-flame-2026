import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
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
}
