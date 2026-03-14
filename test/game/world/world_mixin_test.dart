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

  test('fish spawn patch requires full 2x2 valid water area', () {
    final cells = <List<bool>>[
      <bool>[true, true, false],
      <bool>[true, true, true],
      <bool>[true, true, true],
    ];

    expect(
      WorldMixin.canSpawnFishInPatch(
        fishSpawnableCells: cells,
        column: 0,
        row: 0,
      ),
      isTrue,
    );
    expect(
      WorldMixin.canSpawnFishInPatch(
        fishSpawnableCells: cells,
        column: 0,
        row: 1,
      ),
      isFalse,
    );
  });

  test('fish spawn patch rejects out-of-bounds coordinates', () {
    final cells = <List<bool>>[
      <bool>[true, true],
      <bool>[true, true],
    ];

    expect(
      WorldMixin.canSpawnFishInPatch(
        fishSpawnableCells: cells,
        column: -1,
        row: 0,
      ),
      isFalse,
    );
    expect(
      WorldMixin.canSpawnFishInPatch(
        fishSpawnableCells: cells,
        column: 1,
        row: 0,
      ),
      isFalse,
    );
    expect(
      WorldMixin.canSpawnFishInPatch(
        fishSpawnableCells: cells,
        column: 0,
        row: 1,
      ),
      isFalse,
    );
  });

  test('fish spawn center is middle of 2x2 patch', () {
    final center = WorldMixin.fishSpawnCenter(column: 2, row: 3);

    expect(center.x, closeTo(300, 0.0001));
    expect(center.y, closeTo(400, 0.0001));
  });

  test('leaf spawnable cell must be land and non-thorn', () {
    expect(
      WorldMixin.isLeafSpawnableCell(isWaterCell: false, isThornCell: false),
      isTrue,
    );
    expect(
      WorldMixin.isLeafSpawnableCell(isWaterCell: true, isThornCell: false),
      isFalse,
    );
    expect(
      WorldMixin.isLeafSpawnableCell(isWaterCell: false, isThornCell: true),
      isFalse,
    );
  });

  test('leaf position must keep fish clearance', () {
    expect(
      WorldMixin.isLeafPositionFarEnoughFromFish(
        leafCenter: Vector2(100, 100),
        spawnedFishPositions: <Vector2>[Vector2(180, 100)],
      ),
      isFalse,
    );
    expect(
      WorldMixin.isLeafPositionFarEnoughFromFish(
        leafCenter: Vector2(100, 100),
        spawnedFishPositions: <Vector2>[Vector2(500, 500)],
      ),
      isTrue,
    );
  });
}
