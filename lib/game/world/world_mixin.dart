import 'dart:math';

import 'package:fast_noise/fast_noise.dart';
import 'package:flame/components.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/config/gameplay_tuning.dart';
import 'package:game_jam/core/entities/biome_type.dart';
import 'package:game_jam/game/components/environment/ground_component.dart';
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

  static bool shouldSpawnInteriorThorn({
    required bool isWaterCell,
    required bool inSpawnZone,
    required double thornNoiseValue,
    required double thornPatchRoll,
  }) {
    return !isWaterCell &&
        !inSpawnZone &&
        thornNoiseValue >= GameplayTuning.thornPatchThresholdMin &&
        thornNoiseValue <= GameplayTuning.thornPatchThresholdMax &&
        thornPatchRoll <= GameplayTuning.thornPatchSpawnChance;
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
    final lilyPositions = <Vector2>[];
    final cellSizeVec = Vector2(_cellSize, _cellSize);

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

        final h = humidityNorm[i][j];
        final v = vegetationNorm[i][j];
        final t = thornNorm[i][j];
        final isBorderCell =
            i == 0 || j == 0 || i == gridW - 1 || j == gridH - 1;

        // Spawn area is always water so the player fits; elsewhere use humidity.
        final isWaterCell =
            inSpawnZone || (h >= biome.humidity.min && h <= biome.humidity.max);

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
              thornNoiseValue: t,
              thornPatchRoll: random.nextDouble(),
            );
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
              add(WaterLilyComponent(position: lilyPos, radius: radius));
            }
          }
        }
      }
    }
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
