import 'dart:math';

import 'package:fast_noise/fast_noise.dart';
import 'package:flame/components.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/config/gameplay_tuning.dart';
import 'package:game_jam/core/entities/biome_type.dart';
import 'package:game_jam/game/character/infra/seed_code.dart';
import 'package:game_jam/game/components/enemies/fish_enemy_component.dart';
import 'package:game_jam/game/components/environment/cloud_shadow_component.dart';
import 'package:game_jam/game/components/environment/ground_component.dart';
import 'package:game_jam/game/components/environment/leaf_component.dart';
import 'package:game_jam/game/components/environment/thorn_component.dart';
import 'package:game_jam/game/components/environment/water_component.dart';
import 'package:game_jam/game/components/environment/water_lily_component.dart';
import 'package:game_jam/game/my_game.dart';

mixin WorldMixin on HasGameReference<MyGame>, Component {
  Random get random => game.random;

  static const double _cellSize = 100;

  static const double _spawnZoneHalfSize = 300;
  static const double _noiseFrequency = 0.05;
  static const double _minLilyRadius = 25;
  static const double _maxLilyRadius = 45;

  /// Player base radius 48 → diameter 96. Gap between lilies = centerDistance - 2*radius;
  /// centerDistance must be >= 2*maxLilyRadius + playerDiameter so the player can pass.
  static const double _playerBaseDiameter = 96;
  static const double _lilyGapBuffer = 20;
  static const double _minLilySpacing =
      2 * _maxLilyRadius + _playerBaseDiameter + _lilyGapBuffer;
  static const double _candidateSafeZoneHalfSize = 260;
  static const double _candidateSafeZoneLilyRadius = 36;
  static const double _candidateSafeZoneRingRadius = 210;

  static Vector2 candidateSafeZoneCenter({Vector2? preferredCenter}) {
    final Vector2 center = (preferredCenter ?? GameConfig.playerSpawn).clone();
    final double minX = _candidateSafeZoneHalfSize + _cellSize;
    final double minY = _candidateSafeZoneHalfSize + _cellSize;
    final double maxX =
        GameConfig.worldSize.x - _candidateSafeZoneHalfSize - _cellSize;
    final double maxY =
        GameConfig.worldSize.y - _candidateSafeZoneHalfSize - _cellSize;
    center.x = center.x.clamp(minX, maxX);
    center.y = center.y.clamp(minY, maxY);
    return center;
  }

  static bool shouldSpawnInteriorThorn({
    required bool isWaterCell,
    required bool inSpawnZone,
    required bool inCandidateSafeZone,
    required double thornNoiseValue,
    required double thornPatchRoll,
  }) {
    return !isWaterCell &&
        !inSpawnZone &&
        !inCandidateSafeZone &&
        thornNoiseValue >= GameplayTuning.thornPatchThresholdMin &&
        thornNoiseValue <= GameplayTuning.thornPatchThresholdMax &&
        thornPatchRoll <= GameplayTuning.thornPatchSpawnChance;
  }

  static bool isInCandidateSafeZone({
    required Vector2 position,
    Vector2? safeZoneCenter,
  }) {
    final Vector2 center = candidateSafeZoneCenter(
      preferredCenter: safeZoneCenter,
    );
    return position.x >= center.x - _candidateSafeZoneHalfSize &&
        position.x <= center.x + _candidateSafeZoneHalfSize &&
        position.y >= center.y - _candidateSafeZoneHalfSize &&
        position.y <= center.y + _candidateSafeZoneHalfSize;
  }

  static List<Vector2> candidateSafeZoneSpawnPositions({
    required int count,
    Vector2? safeZoneCenter,
  }) {
    if (count <= 0) {
      return <Vector2>[];
    }

    final Vector2 center = candidateSafeZoneCenter(
      preferredCenter: safeZoneCenter,
    );

    final List<Vector2> positions = <Vector2>[];
    if (count == 1) {
      positions.add(center.clone());
      return positions;
    }

    final int ringCount = count;
    for (int i = 0; i < ringCount; i++) {
      final double angle = (-pi / 2) + ((2 * pi * i) / ringCount);
      positions.add(
        Vector2(
          center.x + cos(angle) * _candidateSafeZoneRingRadius,
          center.y + sin(angle) * _candidateSafeZoneRingRadius,
        ),
      );
    }
    return positions;
  }

  static bool canSpawnFishInPatch({
    required List<List<bool>> fishSpawnableCells,
    required int column,
    required int row,
  }) {
    if (fishSpawnableCells.isEmpty ||
        column < 0 ||
        row < 0 ||
        column + 1 >= fishSpawnableCells.length ||
        row + 1 >= fishSpawnableCells.first.length) {
      return false;
    }

    for (int dx = 0; dx < 2; dx++) {
      for (int dy = 0; dy < 2; dy++) {
        if (!fishSpawnableCells[column + dx][row + dy]) {
          return false;
        }
      }
    }

    return true;
  }

  static Vector2 fishSpawnCenter({required int column, required int row}) {
    return Vector2((column + 1) * _cellSize, (row + 1) * _cellSize);
  }

  static bool isLeafSpawnableCell({
    required bool isWaterCell,
    required bool isThornCell,
  }) {
    return !isWaterCell && !isThornCell;
  }

  static bool isLeafPositionFarEnoughFromFish({
    required Vector2 leafCenter,
    required List<Vector2> spawnedFishPositions,
  }) {
    return !spawnedFishPositions.any(
      (Vector2 fishCenter) =>
          fishCenter.distanceTo(leafCenter) < GameplayTuning.fishLeafClearance,
    );
  }

  BiomeType computeBiome() {
    final biome = BiomeType.from(
      humidityPercent: random.nextDouble(),
      temperature: random.nextDouble(),
      vegetation: random.nextDouble(),
    );

    return biome;
  }

  Future<void> generateLevel(BiomeType biome) async {
    for (final WaterLilyComponent lily
        in game.world.children.whereType<WaterLilyComponent>().toList()) {
      lily.removeFromParent();
    }

    final List<FishEnemyComponent> fishEnemies = game.world.children
        .whereType<FishEnemyComponent>()
        .toList();
    for (final FishEnemyComponent fish in fishEnemies) {
      fish.removeFromParent();
    }

    for (final LeafComponent leaf
        in game.world.children.whereType<LeafComponent>().toList()) {
      leaf.removeFromParent();
    }

    final worldSize = GameConfig.worldSize;
    final gridW = (worldSize.x / _cellSize).ceil();
    final gridH = (worldSize.y / _cellSize).ceil();
    final seed = random.nextInt(1 << 20);

    final humidityNoise = noise2(
      gridW,
      gridH,
      seed: seed,
      noiseType: NoiseType.cellular,
      frequency: _noiseFrequency,
      cellularReturnType: CellularReturnType.distance,
    );
    final vegetationNoise = noise2(
      gridW,
      gridH,
      seed: seed + 1,
      noiseType: NoiseType.cellular,
      frequency: _noiseFrequency,
      cellularReturnType: CellularReturnType.distance,
    );
    final thornNoise = noise2(
      gridW,
      gridH,
      seed: seed + 2,
      noiseType: NoiseType.cellular,
      frequency: GameplayTuning.thornPatchNoiseFrequency,
      cellularReturnType: CellularReturnType.distance,
    );

    final humidityNorm = _normalizeGrid(humidityNoise, gridW, gridH);
    final vegetationNorm = _normalizeGrid(vegetationNoise, gridW, gridH);
    final thornNorm = _normalizeGrid(thornNoise, gridW, gridH);

    final spawn = GameConfig.playerSpawn;
    final List<Vector2> candidateSafeZoneCenters =
        candidateSafeZoneSpawnPositions(
          count: GameplayTuning.menuCharacterCandidateCount,
        );
    final lilyPositions = <Vector2>[];
    final fishCandidates = <Vector2>[];
    final leafCandidates = <Vector2>[];
    final cellSizeVec = Vector2(_cellSize, _cellSize);
    final fishSpawnableCells = List.generate(
      gridW,
      (_) => List<bool>.filled(gridH, false),
      growable: false,
    );

    for (var i = 0; i < gridW; i++) {
      for (var j = 0; j < gridH; j++) {
        final cellOrigin = Vector2(i * _cellSize, j * _cellSize);
        final cellCenter = Vector2(
          cellOrigin.x + _cellSize * 0.5,
          cellOrigin.y + _cellSize * 0.5,
        );
        final inSpawnZone =
            cellCenter.x >= spawn.x - _spawnZoneHalfSize &&
            cellCenter.x <= spawn.x + _spawnZoneHalfSize &&
            cellCenter.y >= spawn.y - _spawnZoneHalfSize &&
            cellCenter.y <= spawn.y + _spawnZoneHalfSize;
        final bool inCandidateSafeZone = isInCandidateSafeZone(
          position: cellCenter,
        );

        final h = humidityNorm[i][j];
        final v = vegetationNorm[i][j];
        final t = thornNorm[i][j];
        final isBorderCell =
            i == 0 || j == 0 || i == gridW - 1 || j == gridH - 1;

        // Spawn area is always water so the player fits; elsewhere use humidity.
        final isWaterCell =
            inSpawnZone ||
            inCandidateSafeZone ||
            (h >= biome.humidity.min && h <= biome.humidity.max);

        if (isWaterCell) {
          await add(
            WaterComponent(
              position: cellOrigin.clone(),
              size: cellSizeVec.clone(),
            ),
          );
        } else {
          await add(
            GroundComponent(
              position: cellOrigin.clone(),
              size: cellSizeVec.clone(),
            ),
          );
        }

        final bool isThornCell =
            isBorderCell ||
            shouldSpawnInteriorThorn(
              isWaterCell: isWaterCell,
              inSpawnZone: inSpawnZone,
              inCandidateSafeZone: inCandidateSafeZone,
              thornNoiseValue: t,
              thornPatchRoll: random.nextDouble(),
            );
        fishSpawnableCells[i][j] =
            isWaterCell && !isThornCell && !inSpawnZone && !inCandidateSafeZone;

        if (isLeafSpawnableCell(
          isWaterCell: isWaterCell,
          isThornCell: isThornCell,
        )) {
          leafCandidates.add(cellCenter.clone());
        }

        if (isThornCell) {
          await add(
            ThornComponent(
              position: cellOrigin.clone(),
              size: cellSizeVec.clone(),
              drawLandBackground: !isWaterCell,
            ),
          );
        }

        if (isWaterCell &&
            !isThornCell &&
            !inSpawnZone &&
            v >= biome.vegetation.min &&
            v <= biome.vegetation.max) {
          final radius =
              _minLilyRadius +
              random.nextDouble() * (_maxLilyRadius - _minLilyRadius);
          const buffer = 2.0;
          final maxOffset = _cellSize - 2 * radius - buffer;
          if (maxOffset > buffer) {
            final lilyPos = Vector2(
              cellOrigin.x +
                  buffer +
                  random.nextDouble() * (maxOffset - buffer),
              cellOrigin.y +
                  buffer +
                  random.nextDouble() * (maxOffset - buffer),
            );
            final lilyCenter = Vector2(lilyPos.x + radius, lilyPos.y + radius);
            final tooClose = lilyPositions.any(
              (p) => p.distanceTo(lilyCenter) < _minLilySpacing,
            );
            if (!tooClose) {
              lilyPositions.add(lilyCenter.clone());
              await game.world.add(
                WaterLilyComponent(position: lilyPos, radius: radius),
              );
            }
          }
        }
      }
    }

    for (int i = 0; i < gridW - 1; i++) {
      for (int j = 0; j < gridH - 1; j++) {
        if (!canSpawnFishInPatch(
          fishSpawnableCells: fishSpawnableCells,
          column: i,
          row: j,
        )) {
          continue;
        }

        final spawnCenter = fishSpawnCenter(column: i, row: j);
        if (spawnCenter.distanceTo(spawn) >=
            GameplayTuning.fishMinSpawnDistance) {
          fishCandidates.add(spawnCenter);
        }
      }
    }

    // Spawn fish enemies inside full 2x2 water patches so the sprite stays off land.
    fishCandidates.shuffle(random);
    final spawnedFishPositions = <Vector2>[];
    for (final pos in fishCandidates) {
      if (spawnedFishPositions.length >= GameplayTuning.fishEnemyCount) break;
      final tooClose = spawnedFishPositions.any(
        (p) => p.distanceTo(pos) < GameplayTuning.minFishSpacing,
      );
      if (!tooClose) {
        spawnedFishPositions.add(pos.clone());
        await game.world.add(
          FishEnemyComponent(
            initialPosition: pos.clone(),
            initialSize: Vector2.all(GameplayTuning.fishEnemySize),
          ),
        );
      }
    }

    leafCandidates.shuffle(random);
    final List<Vector2> spawnedLeafPositions = <Vector2>[];
    for (final Vector2 cellCenter in leafCandidates) {
      if (spawnedLeafPositions.length >= GameplayTuning.leafCount) {
        break;
      }

      final bool tooCloseToLeaf = spawnedLeafPositions.any(
        (Vector2 p) => p.distanceTo(cellCenter) < GameplayTuning.minLeafSpacing,
      );
      if (tooCloseToLeaf) {
        continue;
      }

      if (!isLeafPositionFarEnoughFromFish(
        leafCenter: cellCenter,
        spawnedFishPositions: spawnedFishPositions,
      )) {
        continue;
      }

      spawnedLeafPositions.add(cellCenter.clone());
      await game.world.add(
        LeafComponent(
          position: cellCenter - Vector2.all(GameplayTuning.leafSize / 2),
          size: Vector2.all(GameplayTuning.leafSize),
        ),
      );
    }

    for (final Vector2 center in candidateSafeZoneCenters) {
      await game.world.add(
        WaterLilyComponent(
          position: Vector2(
            center.x - _candidateSafeZoneLilyRadius,
            center.y - _candidateSafeZoneLilyRadius,
          ),
          radius: _candidateSafeZoneLilyRadius,
        ),
      );
    }

    await add(
      CloudShadowComponent(seed: SeedCode.decode(game.characterSeedCode)),
    );
  }

  List<List<double>> _normalizeGrid(List<List<double>> grid, int w, int h) {
    var minVal = double.infinity;
    var maxVal = double.negativeInfinity;
    for (var i = 0; i < w; i++) {
      for (var j = 0; j < h; j++) {
        final v = grid[i][j];
        if (v < minVal) minVal = v;
        if (v > maxVal) maxVal = v;
      }
    }
    final span = (maxVal - minVal) + 1e-9;
    return List.generate(
      w,
      (i) => List.generate(h, (j) => (grid[i][j] - minVal) / span),
    );
  }
}
