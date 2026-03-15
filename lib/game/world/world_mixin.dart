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
import 'package:game_jam/game/components/environment/leaf_component.dart';
import 'package:game_jam/game/components/environment/thorn_component.dart';
import 'package:game_jam/game/components/environment/water_component.dart';
import 'package:game_jam/game/components/environment/water_lily_component.dart';
import 'package:game_jam/game/my_game.dart';

mixin WorldMixin on HasGameReference<MyGame>, Component {
  Random get random => game.random;

  static const double _cellSize = GameConfig.worldCellSize;

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

  /// Maximum rectangle side length (in cells) for zone-2 and zone-3 water bodies.
  /// Minimum is always 4 (enforced in _buildWaterRectangles).
  static const int _ringMaxRectCells = 6;
  static const int _outerMaxRectCells = 5;

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

  Future<(List<Rect>, List<Rect>)> generateLevel() async {
    for (final WaterLilyComponent lily
        in game.world.children.whereType<WaterLilyComponent>().toList()) {
      lily.removeFromParent();
    }
    for (final FishEnemyComponent fish
        in game.world.children.whereType<FishEnemyComponent>().toList()) {
      fish.removeFromParent();
    }

    for (final LeafComponent leaf
        in game.world.children.whereType<LeafComponent>().toList()) {
      leaf.removeFromParent();
    }

    for (final ThornComponent thorn
        in game.world.children.whereType<ThornComponent>().toList()) {
      thorn.removeFromParent();
    }

    final Vector2 worldSize = GameConfig.worldSize;
    final int gridW = (worldSize.x / _cellSize).ceil();
    final int gridH = (worldSize.y / _cellSize).ceil();
    final Vector2 cellSizeVec = Vector2.all(_cellSize);
    final Vector2 worldCenter = worldSize / 2;
    final int seed = random.nextInt(1 << 20);

    final (
      List<List<bool>> isWaterGrid,
      List<List<bool>> isFishZoneGrid,
      List<List<bool>> isZone3GroundGrid,
      List<List<double>> thornNoiseGrid,
    ) = _classifyGrid(
      gridW: gridW,
      gridH: gridH,
      cellSizeVec: cellSizeVec,
      worldCenter: worldCenter,
      seed: seed,
    );

    final List<Rect> waterBounds = await _placeTiles(
      gridW: gridW,
      gridH: gridH,
      cellSizeVec: cellSizeVec,
      isWaterGrid: isWaterGrid,
    );

    final (
      List<Vector2> fishCandidates,
      List<Vector2> lilyCandidateOrigins,
      List<Vector2> eggCandidateOrigins,
      List<Vector2> leafCandidateOrigins,
    ) = _collectSpawnCandidates(
      gridW: gridW,
      gridH: gridH,
      cellSizeVec: cellSizeVec,
      isWaterGrid: isWaterGrid,
      isFishZoneGrid: isFishZoneGrid,
      isZone3GroundGrid: isZone3GroundGrid,
    );

    final List<Vector2> spawnedFishPositions = await _spawnFish(fishCandidates);

    final List<Vector2> lilyPositions = await _spawnLilies(
      lilyCandidateOrigins,
      spawnedFishPositions,
    );

    await _spawnThorns(
      gridW: gridW,
      gridH: gridH,
      cellSizeVec: cellSizeVec,
      isWaterGrid: isWaterGrid,
      thornNoiseGrid: thornNoiseGrid,
      spawnedFishPositions: spawnedFishPositions,
      lilyPositions: lilyPositions,
    );

    await _spawnEggs(eggCandidateOrigins);

    final List<Rect> leafBounds = await _spawnLeaves(
      leafCandidateOrigins,
      spawnedFishPositions,
    );

    await add(
      CloudShadowComponent(seed: SeedCode.decode(game.characterSeedCode)),
    );

    return (waterBounds, leafBounds);
  }

  (List<List<bool>>, List<List<bool>>, List<List<bool>>, List<List<double>>)
  _classifyGrid({
    required int gridW,
    required int gridH,
    required Vector2 cellSizeVec,
    required Vector2 worldCenter,
    required int seed,
  }) {
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

    final List<List<bool>> isWaterGrid = List.generate(
      gridW,
      (_) => List.filled(gridH, false),
    );
    final List<List<bool>> isFishZoneGrid = List.generate(
      gridW,
      (_) => List.filled(gridH, false),
    );
    final List<List<bool>> isZone3GroundGrid = List.generate(
      gridW,
      (_) => List.filled(gridH, false),
    );

    final waterRects = _buildWaterRectangles(
      gridW: gridW,
      gridH: gridH,
      worldCenter: worldCenter,
      ringNoise: ringNoise,
      outerNoise: outerNoise,
    );

    for (final rect in waterRects) {
      for (int i = rect.minI; i <= rect.maxI; i++) {
        for (int j = rect.minJ; j <= rect.maxJ; j++) {
          if (i < 0 || i >= gridW || j < 0 || j >= gridH) continue;
          isWaterGrid[i][j] = true;

          final Vector2 cellCenter =
              Vector2(i * _cellSize, j * _cellSize) + cellSizeVec / 2;
          final bool farFromSpawn =
              cellCenter.distanceTo(GameConfig.playerSpawn) >=
              GameplayTuning.fishMinSpawnDistance;
          if (!rect.isCenterZone && farFromSpawn) {
            isFishZoneGrid[i][j] = true;
          }
        }
      }
    }

    // Force all map border cells to water so the outer edge is always water.
    for (int i = 0; i < gridW; i++) {
      isWaterGrid[i][0] = true;
      isWaterGrid[i][gridH - 1] = true;
    }
    for (int j = 0; j < gridH; j++) {
      isWaterGrid[0][j] = true;
      isWaterGrid[gridW - 1][j] = true;
    }

    for (int i = 0; i < gridW; i++) {
      for (int j = 0; j < gridH; j++) {
        final Vector2 cellCenter =
            Vector2(i * _cellSize, j * _cellSize) + cellSizeVec / 2;
        final bool inOuterSquare =
            cellCenter.x >= worldCenter.x - _ringZoneHalfSize &&
            cellCenter.x <= worldCenter.x + _ringZoneHalfSize &&
            cellCenter.y >= worldCenter.y - _ringZoneHalfSize &&
            cellCenter.y <= worldCenter.y + _ringZoneHalfSize;
        if (!isWaterGrid[i][j] && !inOuterSquare) {
          isZone3GroundGrid[i][j] = true;
        }
      }
    }

    return (isWaterGrid, isFishZoneGrid, isZone3GroundGrid, thornNoise);
  }

  Future<List<Rect>> _placeTiles({
    required int gridW,
    required int gridH,
    required Vector2 cellSizeVec,
    required List<List<bool>> isWaterGrid,
  }) async {
    final List<Rect> waterBounds = <Rect>[];
    for (int i = 0; i < gridW; i++) {
      for (int j = 0; j < gridH; j++) {
        final Vector2 cellOrigin = Vector2(i * _cellSize, j * _cellSize);
        final bool isBorderCell =
            i == 0 || j == 0 || i == gridW - 1 || j == gridH - 1;
        final bool isWater = isWaterGrid[i][j];

        if (isWater) {
          // For border cells the only meaningful ground edge is the exterior
          // side of the map. Interior neighbours are always treated as water so
          // the asset shows ground facing outward regardless of what is inside.
          final bool onTop = j == 0;
          final bool onBottom = j == gridH - 1;
          final bool onLeft = i == 0;
          final bool onRight = i == gridW - 1;
          final WaterAssetPosition assetPos;
          if (isBorderCell) {
            // Each border side's interior neighbour: if it's water the border
            // tile is surrounded by water on both sides → plain.
            // Inverted so the ground edge sprite faces inward, making the
            // exterior look like open water beyond the map boundary.
            final bool interiorWaterTop = onTop && isWaterGrid[i][j + 1];
            final bool interiorWaterBottom = onBottom && isWaterGrid[i][j - 1];
            final bool interiorWaterLeft = onLeft && isWaterGrid[i + 1][j];
            final bool interiorWaterRight = onRight && isWaterGrid[i - 1][j];
            final bool hasInteriorWater =
                interiorWaterTop ||
                interiorWaterBottom ||
                interiorWaterLeft ||
                interiorWaterRight;
            if (hasInteriorWater) {
              assetPos = WaterAssetPosition.plain;
            } else {
              final WaterAssetPosition raw = waterAssetPositionFromNeighbours(
                groundUp: onBottom,
                groundDown: onTop,
                groundLeft: onRight,
                groundRight: onLeft,
              );
              // Corner border cells produce an invertedCorner* from the
              // neighbour logic, but visually they need a plain corner* asset
              // so the exterior looks like open water with the ground intrusion
              // coming from the interior side.
              assetPos = switch (raw) {
                WaterAssetPosition.invertedCornerTopLeft =>
                  WaterAssetPosition.cornerUpLeft,
                WaterAssetPosition.invertedCornerTopRight =>
                  WaterAssetPosition.cornerUpRight,
                WaterAssetPosition.invertedCornerBottomLeft =>
                  WaterAssetPosition.cornerBottomLeft,
                WaterAssetPosition.invertedCornerBottomRight =>
                  WaterAssetPosition.cornerBottomRight,
                _ => raw,
              };
            }
          } else {
            assetPos = waterAssetPositionFromNeighbours(
              groundUp: !isWaterGrid[i][j - 1],
              groundDown: !isWaterGrid[i][j + 1],
              groundLeft: !isWaterGrid[i - 1][j],
              groundRight: !isWaterGrid[i + 1][j],
              groundUpLeft: !isWaterGrid[i - 1][j - 1],
              groundUpRight: !isWaterGrid[i + 1][j - 1],
              groundDownLeft: !isWaterGrid[i - 1][j + 1],
              groundDownRight: !isWaterGrid[i + 1][j + 1],
            );
          }
          await add(
            WaterComponent(
              position: cellOrigin.clone(),
              size: cellSizeVec.clone(),
              assetPosition: assetPos,
            ),
          );
          waterBounds.add(
            Rect.fromLTWH(
              cellOrigin.x,
              cellOrigin.y,
              cellSizeVec.x,
              cellSizeVec.y,
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

        if (isBorderCell) {
          await add(
            ThornComponent(
              position: cellOrigin.clone(),
              size: cellSizeVec.clone(),
              drawLandBackground: false,
            ),
          );
        }
      }
    }
    return waterBounds;
  }

  (List<Vector2>, List<Vector2>, List<Vector2>, List<Vector2>)
  _collectSpawnCandidates({
    required int gridW,
    required int gridH,
    required Vector2 cellSizeVec,
    required List<List<bool>> isWaterGrid,
    required List<List<bool>> isFishZoneGrid,
    required List<List<bool>> isZone3GroundGrid,
  }) {
    final List<Vector2> fishCandidates = <Vector2>[];
    final List<Vector2> lilyCandidateOrigins = <Vector2>[];
    final List<Vector2> eggCandidateOrigins = <Vector2>[];
    final List<Vector2> leafCandidateOrigins = <Vector2>[];

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
          final bool cardinalNeighboursAreWater =
              isWaterGrid[i][j - 1] &&
              isWaterGrid[i][j + 1] &&
              isWaterGrid[i - 1][j] &&
              isWaterGrid[i + 1][j];
          if (!inLilyFreeZone && cardinalNeighboursAreWater) {
            lilyCandidateOrigins.add(Vector2(i * _cellSize, j * _cellSize));
          }
        }

        if (isZone3GroundGrid[i][j]) {
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

        if (!isWaterGrid[i][j]) {
          leafCandidateOrigins.add(Vector2(i * _cellSize, j * _cellSize));
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
          fishCandidates.add(
            Vector2(i * _cellSize, j * _cellSize) + cellSizeVec / 2,
          );
        }
      }
    }

    return (
      fishCandidates,
      lilyCandidateOrigins,
      eggCandidateOrigins,
      leafCandidateOrigins,
    );
  }

  Future<List<Vector2>> _spawnFish(List<Vector2> candidates) async {
    candidates.shuffle(random);
    final List<Vector2> spawnedPositions = <Vector2>[];
    for (final Vector2 pos in candidates) {
      if (spawnedPositions.length >= GameplayTuning.fishEnemyCount) break;
      final bool tooClose = spawnedPositions.any(
        (Vector2 p) => p.distanceTo(pos) < GameplayTuning.minFishSpacing,
      );
      if (!tooClose) {
        spawnedPositions.add(pos.clone());
        await add(
          FishEnemyComponent(
            initialPosition:
                pos - Vector2.all(GameplayTuning.fishEnemySize / 2),
            initialSize: Vector2.all(GameplayTuning.fishEnemySize),
          ),
        );
      }
    }
    return spawnedPositions;
  }

  Future<List<Vector2>> _spawnLilies(
    List<Vector2> candidateOrigins,
    List<Vector2> spawnedFishPositions,
  ) async {
    candidateOrigins.shuffle(random);
    final List<Vector2> lilyPositions = <Vector2>[];
    for (final Vector2 cellOrigin in candidateOrigins) {
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
      final Vector2 lilyCenter = lilyPos + Vector2.all(radius);

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
        await add(WaterLilyComponent(position: lilyPos, radius: radius));
      }
    }
    return lilyPositions;
  }

  Future<void> _spawnThorns({
    required int gridW,
    required int gridH,
    required Vector2 cellSizeVec,
    required List<List<bool>> isWaterGrid,
    required List<List<double>> thornNoiseGrid,
    required List<Vector2> spawnedFishPositions,
    required List<Vector2> lilyPositions,
  }) async {
    for (int i = 1; i < gridW - 1; i++) {
      for (int j = 1; j < gridH - 1; j++) {
        if (!isWaterGrid[i][j]) continue;

        final double t = thornNoiseGrid[i][j];
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
  }

  Future<void> _spawnEggs(List<Vector2> candidateOrigins) async {
    candidateOrigins.shuffle(random);
    int spawnedCount = 0;
    for (final Vector2 cellOrigin in candidateOrigins) {
      if (spawnedCount >= GameplayTuning.initialEggCount) break;
      final double halfEgg = GameplayTuning.worldPickupSize / 2;
      await add(
        EggComponent(
          position: Vector2(
            cellOrigin.x +
                halfEgg +
                random.nextDouble() *
                    (_cellSize - GameplayTuning.worldPickupSize),
            cellOrigin.y +
                halfEgg +
                random.nextDouble() *
                    (_cellSize - GameplayTuning.worldPickupSize),
          ),
          size: Vector2.all(GameplayTuning.worldPickupSize),
          isInSafeHouse: false,
        ),
      );
      spawnedCount++;
    }
  }

  Future<List<Rect>> _spawnLeaves(
    List<Vector2> candidateOrigins,
    List<Vector2> spawnedFishPositions,
  ) async {
    candidateOrigins.shuffle(random);
    final List<Vector2> spawnedLeafCenters = <Vector2>[];
    final List<Rect> leafBounds = <Rect>[];
    for (final Vector2 cellOrigin in candidateOrigins) {
      if (spawnedLeafCenters.length >= GameplayTuning.leafCount) break;

      final double maxOffset = _cellSize - GameplayTuning.leafSize;
      if (maxOffset < 0) continue;
      final Vector2 leafPos = Vector2(
        cellOrigin.x + random.nextDouble() * maxOffset,
        cellOrigin.y + random.nextDouble() * maxOffset,
      );
      final Vector2 leafCenter =
          leafPos + Vector2.all(GameplayTuning.leafSize / 2);

      final bool tooCloseToLeaf = spawnedLeafCenters.any(
        (Vector2 p) => p.distanceTo(leafCenter) < GameplayTuning.minLeafSpacing,
      );
      if (tooCloseToLeaf) continue;

      final bool tooCloseToFish = spawnedFishPositions.any(
        (Vector2 p) =>
            p.distanceTo(leafCenter) < GameplayTuning.fishLeafClearance,
      );
      if (tooCloseToFish) continue;

      spawnedLeafCenters.add(leafCenter);
      await add(
        LeafComponent(
          position: leafPos,
          size: Vector2.all(GameplayTuning.leafSize),
        ),
      );
      leafBounds.add(
        Rect.fromLTWH(
          leafPos.x,
          leafPos.y,
          GameplayTuning.leafSize,
          GameplayTuning.leafSize,
        ),
      );
    }
    return leafBounds;
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

    return (
      isWater: isWaterCell,
      isFishZone: isFishZone,
      isZone3Ground: isZone3Ground,
    );
  }

  /// Derives the [WaterAssetPosition] for a water cell from its four cardinal
  /// neighbours and optional diagonal neighbours.
  ///
  /// [groundUp], [groundDown], [groundLeft], [groundRight] are true when the
  /// neighbour in that direction is ground (or out-of-bounds).
  ///
  /// When two adjacent cardinal neighbours are ground (e.g. up + left), the
  /// tile sits at the outer corner of the water body and uses an
  /// `invertedCorner*` asset (concave ground edge, ~¾ water).
  ///
  /// The diagonal parameters are only consulted when all four cardinal
  /// neighbours are water. A single diagonal ground neighbour means this is
  /// an interior tile with a convex corner intrusion, using a `corner*` asset.
  @visibleForTesting
  static WaterAssetPosition waterAssetPositionFromNeighbours({
    required bool groundUp,
    required bool groundDown,
    required bool groundLeft,
    required bool groundRight,
    bool groundUpLeft = false,
    bool groundUpRight = false,
    bool groundDownLeft = false,
    bool groundDownRight = false,
  }) {
    final int exposedCount =
        (groundUp ? 1 : 0) +
        (groundDown ? 1 : 0) +
        (groundLeft ? 1 : 0) +
        (groundRight ? 1 : 0);

    if (exposedCount == 2) {
      if (groundUp && groundLeft) {
        return WaterAssetPosition.invertedCornerTopLeft;
      }
      if (groundUp && groundRight) {
        return WaterAssetPosition.invertedCornerTopRight;
      }
      if (groundDown && groundLeft) {
        return WaterAssetPosition.invertedCornerBottomLeft;
      }
      if (groundDown && groundRight) {
        return WaterAssetPosition.invertedCornerBottomRight;
      }
    }
    if (exposedCount == 1) {
      if (groundUp) return WaterAssetPosition.up;
      if (groundDown) return WaterAssetPosition.bottom;
      if (groundLeft) return WaterAssetPosition.left;
      if (groundRight) return WaterAssetPosition.right;
    }

    // All four cardinal neighbours are water: check diagonals for convex corners.
    // Only one diagonal is applied per tile; priority matches the enum order.
    if (exposedCount == 0) {
      if (groundUpLeft) return WaterAssetPosition.cornerUpLeft;
      if (groundUpRight) return WaterAssetPosition.cornerUpRight;
      if (groundDownLeft) return WaterAssetPosition.cornerBottomLeft;
      if (groundDownRight) return WaterAssetPosition.cornerBottomRight;
    }

    return WaterAssetPosition.plain;
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
    required bool groundUp,
    required bool groundDown,
    required bool groundLeft,
    required bool groundRight,
    bool groundUpLeft = false,
    bool groundUpRight = false,
    bool groundDownLeft = false,
    bool groundDownRight = false,
  }) async {
    final (:bool isWater, :bool isFishZone, :bool isZone3Ground) = classifyCell(
      cellCenter: cellCenter,
      worldCenter: worldCenter,
      ringNoiseValue: ringNoiseValue,
      outerNoiseValue: outerNoiseValue,
    );

    if (isWater) {
      final WaterAssetPosition assetPosition = waterAssetPositionFromNeighbours(
        groundUp: groundUp,
        groundDown: groundDown,
        groundLeft: groundLeft,
        groundRight: groundRight,
        groundUpLeft: groundUpLeft,
        groundUpRight: groundUpRight,
        groundDownLeft: groundDownLeft,
        groundDownRight: groundDownRight,
      );
      await add(
        WaterComponent(
          position: cellOrigin.clone(),
          size: cellSizeVec.clone(),
          assetPosition: assetPosition,
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

    return (isWater, isFishZone, isZone3Ground);
  }

  /// Builds a list of axis-aligned water rectangles (in grid-cell coordinates).
  ///
  /// Every water body is always a rectangle of at least 4×4 cells.
  /// Zone 1 (center) produces a single large rectangle.
  /// Zone 2 (ring) and Zone 3 (outer) sample noise to seed rectangles of
  /// random sizes, snapping each candidate cell to the top-left of its
  /// rectangle so that overlapping seeds don't create duplicate rects.
  /// Each placed rect's 1-cell perimeter is also claimed so that no two rects
  /// can be diagonal-only adjacent (they either share a cardinal edge or are
  /// separated by at least 2 ground cells).
  List<({int minI, int minJ, int maxI, int maxJ, bool isCenterZone})>
  _buildWaterRectangles({
    required int gridW,
    required int gridH,
    required Vector2 worldCenter,
    required List<List<double>> ringNoise,
    required List<List<double>> outerNoise,
  }) {
    final results =
        <({int minI, int minJ, int maxI, int maxJ, bool isCenterZone})>[];

    // Zone 1: entire center water square as one rectangle.
    final int centerMinI =
        ((worldCenter.x - _centerWaterZoneHalfSize) / _cellSize).floor().clamp(
          0,
          gridW - 1,
        );
    final int centerMaxI =
        ((worldCenter.x + _centerWaterZoneHalfSize) / _cellSize).ceil() - 1;
    final int centerMinJ =
        ((worldCenter.y - _centerWaterZoneHalfSize) / _cellSize).floor().clamp(
          0,
          gridH - 1,
        );
    final int centerMaxJ =
        ((worldCenter.y + _centerWaterZoneHalfSize) / _cellSize).ceil() - 1;
    final int clampedCenterMinI = centerMinI.clamp(0, gridW - 1);
    final int clampedCenterMinJ = centerMinJ.clamp(0, gridH - 1);
    final int clampedCenterMaxI = centerMaxI.clamp(0, gridW - 1);
    final int clampedCenterMaxJ = centerMaxJ.clamp(0, gridH - 1);
    results.add((
      minI: clampedCenterMinI,
      minJ: clampedCenterMinJ,
      maxI: clampedCenterMaxI,
      maxJ: clampedCenterMaxJ,
      isCenterZone: true,
    ));

    // To avoid placing many overlapping rectangles from nearby seeds, track
    // which seed cells have already been claimed by a rectangle's perimeter.
    // `waterCells` tracks only actual rect interiors — used to reject any new
    // rect whose own 1-cell perimeter would touch existing water.
    final List<List<bool>> claimed = List.generate(
      gridW,
      (_) => List.filled(gridH, false),
    );
    final List<List<bool>> waterCells = List.generate(
      gridW,
      (_) => List.filled(gridH, false),
    );

    // Claim the center zone rect and its 1-cell perimeter so that ring rects
    // cannot be diagonal-only adjacent to the center zone's corners.
    for (
      int ci = (clampedCenterMinI - 1).clamp(0, gridW - 1);
      ci <= (clampedCenterMaxI + 1).clamp(0, gridW - 1);
      ci++
    ) {
      for (
        int cj = (clampedCenterMinJ - 1).clamp(0, gridH - 1);
        cj <= (clampedCenterMaxJ + 1).clamp(0, gridH - 1);
        cj++
      ) {
        claimed[ci][cj] = true;
      }
    }
    for (int ci = clampedCenterMinI; ci <= clampedCenterMaxI; ci++) {
      for (int cj = clampedCenterMinJ; cj <= clampedCenterMaxJ; cj++) {
        waterCells[ci][cj] = true;
      }
    }

    for (int i = 0; i < gridW; i++) {
      for (int j = 0; j < gridH; j++) {
        final Vector2 cellCenter = Vector2(
          i * _cellSize + _cellSize / 2,
          j * _cellSize + _cellSize / 2,
        );

        final bool inCenterZone =
            cellCenter.x >= worldCenter.x - _centerWaterZoneHalfSize &&
            cellCenter.x <= worldCenter.x + _centerWaterZoneHalfSize &&
            cellCenter.y >= worldCenter.y - _centerWaterZoneHalfSize &&
            cellCenter.y <= worldCenter.y + _centerWaterZoneHalfSize;

        if (inCenterZone) continue;
        if (claimed[i][j]) continue;

        final bool inOuterSquare =
            cellCenter.x >= worldCenter.x - _ringZoneHalfSize &&
            cellCenter.x <= worldCenter.x + _ringZoneHalfSize &&
            cellCenter.y >= worldCenter.y - _ringZoneHalfSize &&
            cellCenter.y <= worldCenter.y + _ringZoneHalfSize;

        final bool inRingZone = inOuterSquare;
        final bool isWaterSeed =
            (inRingZone && ringNoise[i][j] > _ringGroundThreshold) ||
            (!inRingZone && outerNoise[i][j] > _outerWaterThreshold);

        if (!isWaterSeed) continue;

        // Random width and height: minimum 4 cells, maximum depends on zone.
        final int maxDim = inRingZone ? _ringMaxRectCells : _outerMaxRectCells;
        final int w = 4 + random.nextInt(maxDim - 3);
        final int h = 4 + random.nextInt(maxDim - 3);

        final int minI = i.clamp(0, gridW - 1);
        final int minJ = j.clamp(0, gridH - 1);
        final int maxI = (i + w - 1).clamp(0, gridW - 1);
        final int maxJ = (j + h - 1).clamp(0, gridH - 1);

        // Must be at least 4×4 after clamping.
        if (maxI - minI < 3 || maxJ - minJ < 3) continue;

        // Reject if any cell in this rect's 1-cell perimeter is already a
        // water cell. This guarantees every pair of water rects is separated
        // by at least 2 ground cells in every direction — no diagonal adjacency
        // is possible regardless of where the seed falls within the rect.
        bool tooClose = false;
        perimeterCheck:
        for (
          int ci = (minI - 1).clamp(0, gridW - 1);
          ci <= (maxI + 1).clamp(0, gridW - 1);
          ci++
        ) {
          for (
            int cj = (minJ - 1).clamp(0, gridH - 1);
            cj <= (maxJ + 1).clamp(0, gridH - 1);
            cj++
          ) {
            if (waterCells[ci][cj]) {
              tooClose = true;
              break perimeterCheck;
            }
          }
        }
        if (tooClose) continue;

        results.add((
          minI: minI,
          minJ: minJ,
          maxI: maxI,
          maxJ: maxJ,
          isCenterZone: false,
        ));

        // Claim the rect interior as water and its 1-cell perimeter so that
        // future seeds are blocked from starting inside the buffer zone.
        for (
          int ci = (minI - 1).clamp(0, gridW - 1);
          ci <= (maxI + 1).clamp(0, gridW - 1);
          ci++
        ) {
          for (
            int cj = (minJ - 1).clamp(0, gridH - 1);
            cj <= (maxJ + 1).clamp(0, gridH - 1);
            cj++
          ) {
            claimed[ci][cj] = true;
          }
        }
        for (int ci = minI; ci <= maxI; ci++) {
          for (int cj = minJ; cj <= maxJ; cj++) {
            waterCells[ci][cj] = true;
          }
        }
      }
    }

    return results;
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
