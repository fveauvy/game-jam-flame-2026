import 'dart:math';

import 'package:fast_noise/fast_noise.dart';
import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/config/gameplay_tuning.dart';
import 'package:game_jam/game/character/infra/seed_code.dart';
import 'package:game_jam/game/components/allies/egg_component.dart';
import 'package:game_jam/game/components/enemies/fish_enemy_component.dart';
import 'package:game_jam/game/components/environment/cloud_shadow_component.dart';
import 'package:game_jam/game/components/environment/ground_component.dart';
import 'package:game_jam/game/components/environment/thorn_component.dart';
import 'package:game_jam/game/components/environment/water_component.dart';
import 'package:game_jam/game/components/environment/water_lily_component.dart';
import 'package:game_jam/game/my_game.dart';

mixin WorldMixin on HasGameReference<MyGame>, Component {
  Random get random => game.random;

  static const double _cellSize = 100;

  /// Zone 1: 700×700 pure-water square at the world centre.
  static const double _centerWaterZoneHalfSize = 350;

  /// Zone 2: noise ring surrounding zone 1 — outer boundary is 1400×1400.
  static const double _ringZoneHalfSize = 700;
  static const double _ringNoiseFrequency = 0.05;

  /// Zone 2: noise value > threshold → water. Top 70% → water, bottom 30% → ground.
  static const double _ringGroundThreshold = 0.30;

  /// Zone 3: everything outside zone 2 — mostly ground, 30% water as isolated puddles.
  /// Higher frequency + simplex noise creates small, separated water blobs.
  static const double _outerNoiseFrequency = 0.25;

  /// Zone 3: noise value > threshold → water. Top 45% → water, bottom 55% → ground.
  static const double _outerWaterThreshold = 0.65;

  static const double _candidateSafeZoneHalfSize = 260;
  static const double _candidateSafeZoneRingRadius = 210;

  static const double _minLilyRadius = 25;
  static const double _maxLilyRadius = 45;
  static const double _playerBaseDiameter = 96;
  static const double _lilyGapBuffer = 20;
  static const double _minLilySpacing =
      2 * _maxLilyRadius + _playerBaseDiameter + _lilyGapBuffer;

  /// No water lilies spawn within this half-size square around the player spawn.
  static const double _lilyFreeZoneHalfSize = 130;

  final List<Vector2> candidateSafeZoneCenters =
      candidateSafeZoneSpawnPositions(
        count: GameplayTuning.menuCharacterCandidateCount,
      );

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

  Future<void> generateLevel() async {
    /// Remove all components at the start of the level
    for (final WaterLilyComponent lily
        in game.world.children.whereType<WaterLilyComponent>().toList()) {
      lily.removeFromParent();
    }

    for (final FishEnemyComponent fish
        in game.world.children.whereType<FishEnemyComponent>().toList()) {
      fish.removeFromParent();
    }

    final Vector2 worldSize = GameConfig.worldSize;
    final int gridW = (worldSize.x / _cellSize).ceil();
    final int gridH = (worldSize.y / _cellSize).ceil();
    final Vector2 cellSizeVec = Vector2.all(_cellSize);
    final Vector2 worldCenter = worldSize / 2;

    final int seed = random.nextInt(1 << 20);

    final List<List<double>> ringNoise = _normalizeGrid(
      noise2(
        gridW,
        gridH,
        seed: seed,
        noiseType: NoiseType.cellular,
        frequency: _ringNoiseFrequency,
        cellularReturnType: CellularReturnType.distance,
      ),
      gridW,
      gridH,
    );

    final List<List<double>> outerNoise = _normalizeGrid(
      noise2(
        gridW,
        gridH,
        seed: seed + 1,
        noiseType: NoiseType.simplexFractal,
        frequency: _outerNoiseFrequency,
      ),
      gridW,
      gridH,
    );

    final List<List<double>> thornNoise = _normalizeGrid(
      noise2(
        gridW,
        gridH,
        seed: seed + 2,
        noiseType: NoiseType.cellular,
        frequency: GameplayTuning.thornPatchNoiseFrequency,
        cellularReturnType: CellularReturnType.distance,
      ),
      gridW,
      gridH,
    );

    // Track which cells are water so we can require a full 3×3 water neighbourhood.
    final List<List<bool>> isWaterGrid = List.generate(
      gridW,
      (_) => List.filled(gridH, false),
    );
    // Track which cells are eligible fish spawn zones (not zone 1, far from spawn).
    final List<List<bool>> isFishZoneGrid = List.generate(
      gridW,
      (_) => List.filled(gridH, false),
    );
    // Track zone-3 ground cells for egg spawning.
    final List<List<bool>> isZone3GroundGrid = List.generate(
      gridW,
      (_) => List.filled(gridH, false),
    );
    // Track thorn noise values for water cells.
    final List<List<double>> thornCandidateNoise = List.generate(
      gridW,
      (_) => List.filled(gridH, 0.0),
    );

    for (int i = 0; i < gridW; i++) {
      for (int j = 0; j < gridH; j++) {
        final Vector2 cellOrigin = Vector2(i * _cellSize, j * _cellSize);
        final Vector2 cellCenter = cellOrigin + cellSizeVec / 2;
        final bool isBorderCell =
            i == 0 || j == 0 || i == gridW - 1 || j == gridH - 1;

        final (
          bool isWater,
          bool isFishZone,
          bool isZone3Ground,
        ) = await processCellAt(
          cellOrigin: cellOrigin,
          cellCenter: cellCenter,
          cellSizeVec: cellSizeVec,
          isBorderCell: isBorderCell,
          worldCenter: worldCenter,
          ringNoiseValue: ringNoise[i][j],
          outerNoiseValue: outerNoise[i][j],
        );

        isWaterGrid[i][j] = isWater;
        isFishZoneGrid[i][j] = isFishZone;
        isZone3GroundGrid[i][j] = isZone3Ground;
        thornCandidateNoise[i][j] = thornNoise[i][j];

        if (isBorderCell) {
          await add(
            ThornComponent(
              position: cellOrigin.clone(),
              size: cellSizeVec.clone(),
              drawLandBackground: !isWater,
            ),
          );
        }
      }
    }

    // Collect candidates where the full 3×3 neighbourhood is water so the
    // 150×150 fish sprite never overlaps a ground cell.
    final List<Vector2> fishCandidates = <Vector2>[];
    final List<Vector2> lilyCandidateOrigins = <Vector2>[];
    final List<Vector2> eggCandidateOrigins = <Vector2>[];
    for (int i = 1; i < gridW - 1; i++) {
      for (int j = 1; j < gridH - 1; j++) {
        if (isWaterGrid[i][j]) {
          final Vector2 cellCenter =
              Vector2(i * _cellSize, j * _cellSize) + cellSizeVec / 2;
          final Vector2 spawn = GameConfig.playerSpawn;
          final bool inLilyFreeZone =
              cellCenter.x >= spawn.x - _lilyFreeZoneHalfSize &&
              cellCenter.x <= spawn.x + _lilyFreeZoneHalfSize &&
              cellCenter.y >= spawn.y - _lilyFreeZoneHalfSize &&
              cellCenter.y <= spawn.y + _lilyFreeZoneHalfSize;
          if (!inLilyFreeZone) {
            lilyCandidateOrigins.add(Vector2(i * _cellSize, j * _cellSize));
          }
        }
        if (isZone3GroundGrid[i][j]) {
          // Require all 8 neighbours to also be ground so the egg never
          // sits on a cell bordering water.
          bool allNeighboursGround = true;
          groundCheck:
          for (int di = -1; di <= 1; di++) {
            for (int dj = -1; dj <= 1; dj++) {
              if (isWaterGrid[i + di][j + dj]) {
                allNeighboursGround = false;
                break groundCheck;
              }
            }
          }
          if (allNeighboursGround) {
            eggCandidateOrigins.add(Vector2(i * _cellSize, j * _cellSize));
          }
        }

        if (!isFishZoneGrid[i][j]) continue;
        bool allNeighboursWater = true;
        outer:
        for (int di = -1; di <= 1; di++) {
          for (int dj = -1; dj <= 1; dj++) {
            if (!isWaterGrid[i + di][j + dj]) {
              allNeighboursWater = false;
              break outer;
            }
          }
        }
        if (allNeighboursWater) {
          final Vector2 cellCenter =
              Vector2(i * _cellSize, j * _cellSize) + cellSizeVec / 2;
          fishCandidates.add(cellCenter);
        }
      }
    }

    fishCandidates.shuffle(random);
    final List<Vector2> spawnedFishPositions = <Vector2>[];
    for (final Vector2 pos in fishCandidates) {
      if (spawnedFishPositions.length >= GameplayTuning.fishEnemyCount) break;
      final bool tooClose = spawnedFishPositions.any(
        (Vector2 p) => p.distanceTo(pos) < GameplayTuning.minFishSpacing,
      );
      if (!tooClose) {
        spawnedFishPositions.add(pos.clone());
        await game.world.add(
          FishEnemyComponent(
            initialPosition:
                pos - Vector2.all(GameplayTuning.fishEnemySize / 2),
            initialSize: Vector2.all(GameplayTuning.fishEnemySize),
          ),
        );
      }
    }

    // Place lilies on water cells, avoiding fish positions.
    lilyCandidateOrigins.shuffle(random);
    final List<Vector2> lilyPositions = <Vector2>[];
    for (final Vector2 cellOrigin in lilyCandidateOrigins) {
      final double radius =
          _minLilyRadius +
          random.nextDouble() * (_maxLilyRadius - _minLilyRadius);
      const double buffer = 2.0;
      final double maxOffset = _cellSize - 2 * radius - buffer;
      if (maxOffset <= buffer) continue;

      final Vector2 lilyPos = Vector2(
        cellOrigin.x + buffer + random.nextDouble() * (maxOffset - buffer),
        cellOrigin.y + buffer + random.nextDouble() * (maxOffset - buffer),
      );
      final Vector2 lilyCenter = Vector2(
        lilyPos.x + radius,
        lilyPos.y + radius,
      );

      final bool tooCloseToLily = lilyPositions.any(
        (Vector2 p) => p.distanceTo(lilyCenter) < _minLilySpacing,
      );
      final bool tooCloseToFish = spawnedFishPositions.any(
        (Vector2 p) =>
            p.distanceTo(lilyCenter) <
            GameplayTuning.fishEnemySize / 2 + _maxLilyRadius,
      );
      if (!tooCloseToLily && !tooCloseToFish) {
        lilyPositions.add(lilyCenter);
        await game.world.add(
          WaterLilyComponent(position: lilyPos, radius: radius),
        );
      }
    }

    // Spawn thorns on water cells that pass noise threshold, avoiding fish and lilies.
    for (int i = 0; i < gridW; i++) {
      for (int j = 0; j < gridH; j++) {
        if (i == 0 || j == 0 || i == gridW - 1 || j == gridH - 1) continue;
        if (!isWaterGrid[i][j]) continue;

        final double t = thornCandidateNoise[i][j];
        if (t < GameplayTuning.thornPatchThresholdMin ||
            t > GameplayTuning.thornPatchThresholdMax) {
          continue;
        }
        if (random.nextDouble() > GameplayTuning.thornPatchSpawnChance) {
          continue;
        }

        final Vector2 cellOrigin = Vector2(i * _cellSize, j * _cellSize);
        final Vector2 cellCenter = cellOrigin + cellSizeVec / 2;

        final bool overlapsFish = spawnedFishPositions.any(
          (Vector2 p) =>
              p.distanceTo(cellCenter) <
              GameplayTuning.fishEnemySize / 2 + _cellSize / 2,
        );
        if (overlapsFish) continue;

        final bool overlapsLily = lilyPositions.any(
          (Vector2 p) =>
              p.x >= cellOrigin.x &&
              p.x <= cellOrigin.x + _cellSize &&
              p.y >= cellOrigin.y &&
              p.y <= cellOrigin.y + _cellSize,
        );
        if (overlapsLily) continue;

        await add(
          ThornComponent(
            position: cellOrigin.clone(),
            size: cellSizeVec.clone(),
            drawLandBackground: false,
          ),
        );
      }
    }

    // Spawn eggs randomly on zone-3 ground cells, one per candidate cell.
    eggCandidateOrigins.shuffle(random);
    int spawnedEggCount = 0;
    for (final Vector2 cellOrigin in eggCandidateOrigins) {
      if (spawnedEggCount >= GameplayTuning.initialEggCount) break;
      final double halfEgg = GameplayTuning.worldPickupSize / 2;
      final double eggX =
          cellOrigin.x +
          halfEgg +
          random.nextDouble() * (_cellSize - GameplayTuning.worldPickupSize);
      final double eggY =
          cellOrigin.y +
          halfEgg +
          random.nextDouble() * (_cellSize - GameplayTuning.worldPickupSize);
      await game.world.add(
        EggComponent(
          position: Vector2(eggX, eggY),
          size: Vector2.all(GameplayTuning.worldPickupSize),
          isInSafeHouse: false,
        ),
      );
      spawnedEggCount++;
    }

    await add(
      CloudShadowComponent(seed: SeedCode.decode(game.characterSeedCode)),
    );
  }

  /// Returns whether an interior thorn should spawn on a given water cell.
  ///
  /// Thorns spawn on interior water cells whose thorn-noise value falls within
  /// the tuned window and whose random roll passes the spawn-chance threshold.
  @visibleForTesting
  static bool shouldSpawnInteriorThorn({
    required bool isWaterCell,
    required double thornNoiseValue,
    required double thornPatchRoll,
  }) {
    return isWaterCell &&
        thornNoiseValue >= GameplayTuning.thornPatchThresholdMin &&
        thornNoiseValue <= GameplayTuning.thornPatchThresholdMax &&
        thornPatchRoll <= GameplayTuning.thornPatchSpawnChance;
  }

  /// Pure classification logic for a single cell: determines water/fish/ground
  /// status from zone geometry and pre-computed noise values, with no side
  /// effects on the component tree.
  @visibleForTesting
  static ({bool isWater, bool isFishZone, bool isZone3Ground}) classifyCell({
    required Vector2 cellCenter,
    required Vector2 worldCenter,
    required double ringNoiseValue,
    required double outerNoiseValue,
  }) {
    final bool inCenterWaterZone =
        cellCenter.x >= worldCenter.x - _centerWaterZoneHalfSize &&
        cellCenter.x <= worldCenter.x + _centerWaterZoneHalfSize &&
        cellCenter.y >= worldCenter.y - _centerWaterZoneHalfSize &&
        cellCenter.y <= worldCenter.y + _centerWaterZoneHalfSize;

    final bool inOuterSquare =
        cellCenter.x >= worldCenter.x - _ringZoneHalfSize &&
        cellCenter.x <= worldCenter.x + _ringZoneHalfSize &&
        cellCenter.y >= worldCenter.y - _ringZoneHalfSize &&
        cellCenter.y <= worldCenter.y + _ringZoneHalfSize;

    final bool inRingZone = inOuterSquare && !inCenterWaterZone;
    final bool inOuterZone = !inOuterSquare;

    final bool isWaterCell =
        inCenterWaterZone ||
        (inRingZone && ringNoiseValue > _ringGroundThreshold) ||
        (inOuterZone && outerNoiseValue > _outerWaterThreshold);

    final bool isFishZone =
        isWaterCell &&
        !inCenterWaterZone &&
        cellCenter.distanceTo(GameConfig.playerSpawn) >=
            GameplayTuning.fishMinSpawnDistance;

    final bool isZone3Ground = !isWaterCell && inOuterZone;

    return (isWater: isWaterCell, isFishZone: isFishZone, isZone3Ground: isZone3Ground);
  }

  @visibleForTesting
  Future<(bool isWater, bool isFishZone, bool isZone3Ground)> processCellAt({
    required Vector2 cellOrigin,
    required Vector2 cellCenter,
    required Vector2 cellSizeVec,
    required bool isBorderCell,
    required Vector2 worldCenter,
    required double ringNoiseValue,
    required double outerNoiseValue,
  }) async {
    final (
      :bool isWater,
      :bool isFishZone,
      :bool isZone3Ground,
    ) = classifyCell(
      cellCenter: cellCenter,
      worldCenter: worldCenter,
      ringNoiseValue: ringNoiseValue,
      outerNoiseValue: outerNoiseValue,
    );

    if (isWater) {
      await add(
        WaterComponent(position: cellOrigin.clone(), size: cellSizeVec.clone()),
      );
    } else {
      await add(
        GroundComponent(
          position: cellOrigin.clone(),
          size: cellSizeVec.clone(),
        ),
      );
    }

    return (isWater, isFishZone, isZone3Ground);
  }

  List<List<double>> _normalizeGrid(List<List<double>> grid, int w, int h) {
    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;
    for (int i = 0; i < w; i++) {
      for (int j = 0; j < h; j++) {
        final double v = grid[i][j];
        if (v < minVal) minVal = v;
        if (v > maxVal) maxVal = v;
      }
    }
    final double span = (maxVal - minVal) + 1e-9;
    return List.generate(
      w,
      (int i) => List.generate(h, (int j) => (grid[i][j] - minVal) / span),
    );
  }
}
