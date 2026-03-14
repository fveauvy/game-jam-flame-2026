import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/config/gameplay_tuning.dart';
import 'package:game_jam/game/world/world_mixin.dart';

void main() {
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

  // ---------------------------------------------------------------------------
  // classifyCell tests
  // World is 3200×3200 → worldCenter = (1600, 1600).
  // Zone 1 (center water): cellCenter within ±350 → [1250, 1950].
  // Zone 2 (ring):         cellCenter within ±700 but outside zone 1.
  // Zone 3 (outer):        cellCenter outside ±700 → outside [900, 2300].
  // ---------------------------------------------------------------------------

  group('classifyCell', () {
    final worldCenter = GameConfig.worldSize / 2; // (1600, 1600)

    test(
      'zone 1 cell is always water, never fish zone, never zone-3 ground',
      () {
        // Squarely inside the 700×700 center water zone.
        final cell = Vector2(worldCenter.x, worldCenter.y);

        final result = WorldMixin.classifyCell(
          cellCenter: cell,
          worldCenter: worldCenter,
          ringNoiseValue: 0.0,
          outerNoiseValue: 0.0,
        );

        expect(result.isWater, isTrue);
        expect(
          result.isFishZone,
          isFalse,
          reason: 'zone-1 water is not a fish zone',
        );
        expect(result.isZone3Ground, isFalse);
      },
    );

    test(
      'zone 2 ring cell above noise threshold is water and fish-eligible',
      () {
        // 600 units from center → inside ring (±700) but outside zone 1 (±350).
        final cell = Vector2(worldCenter.x + 600, worldCenter.y);

        final result = WorldMixin.classifyCell(
          cellCenter: cell,
          worldCenter: worldCenter,
          ringNoiseValue: 1.0, // well above 0.30 threshold → water
          outerNoiseValue: 0.0,
        );

        expect(result.isWater, isTrue);
        expect(
          result.isFishZone,
          isTrue,
          reason: 'ring water far from spawn is a fish zone',
        );
        expect(result.isZone3Ground, isFalse);
      },
    );

    test('zone 2 ring cell below noise threshold is ground, not fish zone', () {
      final cell = Vector2(worldCenter.x + 600, worldCenter.y);

      final result = WorldMixin.classifyCell(
        cellCenter: cell,
        worldCenter: worldCenter,
        ringNoiseValue: 0.0, // below 0.30 threshold → ground
        outerNoiseValue: 0.0,
      );

      expect(result.isWater, isFalse);
      expect(result.isFishZone, isFalse);
      expect(
        result.isZone3Ground,
        isFalse,
        reason: 'zone-2 ground is not zone-3 ground',
      );
    });

    test('zone 3 cell above outer noise threshold is water', () {
      // 1000 units from center → outside ±700 ring boundary.
      final cell = Vector2(worldCenter.x + 1000, worldCenter.y);

      final result = WorldMixin.classifyCell(
        cellCenter: cell,
        worldCenter: worldCenter,
        ringNoiseValue: 0.0,
        outerNoiseValue: 1.0, // above 0.65 threshold → water
      );

      expect(result.isWater, isTrue);
      expect(result.isZone3Ground, isFalse);
    });

    test(
      'zone 3 cell below outer noise threshold is ground and zone-3-ground eligible',
      () {
        final cell = Vector2(worldCenter.x + 1000, worldCenter.y);

        final result = WorldMixin.classifyCell(
          cellCenter: cell,
          worldCenter: worldCenter,
          ringNoiseValue: 0.0,
          outerNoiseValue: 0.0, // below 0.65 threshold → ground
        );

        expect(result.isWater, isFalse);
        expect(result.isFishZone, isFalse);
        expect(result.isZone3Ground, isTrue);
      },
    );

    test('zone 3 water is fish-eligible when far enough from spawn', () {
      // Place cell far from player spawn (world center) in zone 3.
      final cell = Vector2(200, 200); // corner of the world, deep zone 3

      final result = WorldMixin.classifyCell(
        cellCenter: cell,
        worldCenter: worldCenter,
        ringNoiseValue: 0.0,
        outerNoiseValue: 1.0, // water
      );

      expect(result.isWater, isTrue);
      expect(
        cell.distanceTo(GameConfig.playerSpawn),
        greaterThanOrEqualTo(GameplayTuning.fishMinSpawnDistance),
      );
      expect(result.isFishZone, isTrue);
    });

    test('ring water too close to spawn is not fish-eligible', () {
      // Place cell in the ring zone but within fishMinSpawnDistance of spawn.
      // playerSpawn == worldCenter, so we need < 600 units away and in the ring.
      final cell = Vector2(worldCenter.x + 400, worldCenter.y);
      final distToSpawn = cell.distanceTo(GameConfig.playerSpawn);

      expect(distToSpawn, lessThan(GameplayTuning.fishMinSpawnDistance));

      final result = WorldMixin.classifyCell(
        cellCenter: cell,
        worldCenter: worldCenter,
        ringNoiseValue: 1.0, // water
        outerNoiseValue: 0.0,
      );

      expect(result.isWater, isTrue);
      expect(result.isFishZone, isFalse, reason: 'too close to spawn for fish');
    });

    test('zone 1 boundary: cell just inside edge is water', () {
      // Exactly on the inner boundary of zone 1.
      final cell = Vector2(
        worldCenter.x - 350, // _centerWaterZoneHalfSize
        worldCenter.y,
      );

      final result = WorldMixin.classifyCell(
        cellCenter: cell,
        worldCenter: worldCenter,
        ringNoiseValue: 0.0,
        outerNoiseValue: 0.0,
      );

      expect(result.isWater, isTrue);
    });

    test('zone 1 boundary: cell just outside zone 1 is classified as ring', () {
      // 1 unit outside zone 1, deep inside the ring — low noise → ground.
      final cell = Vector2(worldCenter.x - 351, worldCenter.y);

      final result = WorldMixin.classifyCell(
        cellCenter: cell,
        worldCenter: worldCenter,
        ringNoiseValue: 0.0, // below ring threshold → ground
        outerNoiseValue: 0.0,
      );

      expect(result.isWater, isFalse);
      expect(
        result.isZone3Ground,
        isFalse,
        reason: 'still inside ring, not zone 3',
      );
    });

    test('isWater and isZone3Ground are mutually exclusive', () {
      for (final noiseValue in [0.0, 0.5, 1.0]) {
        // Zone 3 cell
        final cell = Vector2(worldCenter.x + 1000, worldCenter.y);

        final result = WorldMixin.classifyCell(
          cellCenter: cell,
          worldCenter: worldCenter,
          ringNoiseValue: 0.0,
          outerNoiseValue: noiseValue,
        );

        expect(
          result.isWater && result.isZone3Ground,
          isFalse,
          reason: 'a cell cannot be both water and zone-3 ground',
        );
      }
    });
  });

  // ---------------------------------------------------------------------------
  // generateLevel grid-setup helpers
  //
  // generateLevel computes:
  //   gridW = ceil(worldSize.x / cellSize)   = ceil(3200 / 100) = 32
  //   gridH = ceil(worldSize.y / cellSize)   = ceil(3200 / 100) = 32
  //
  // Border cells: i==0, j==0, i==gridW-1, j==gridH-1.
  // Cell origin: Vector2(i * cellSize, j * cellSize)
  // Cell center: cellOrigin + Vector2.all(cellSize) / 2
  // ---------------------------------------------------------------------------

  group('generateLevel grid geometry', () {
    const double cellSize = 100;
    const int expectedGridW = 32; // ceil(3200 / 100)
    const int expectedGridH = 32;

    test('grid dimensions match world size divided by cell size', () {
      final worldSize = GameConfig.worldSize;
      final gridW = (worldSize.x / cellSize).ceil();
      final gridH = (worldSize.y / cellSize).ceil();

      expect(gridW, equals(expectedGridW));
      expect(gridH, equals(expectedGridH));
    });

    test('corner cells are border cells', () {
      bool isBorder(int i, int j) =>
          i == 0 || j == 0 || i == expectedGridW - 1 || j == expectedGridH - 1;

      expect(isBorder(0, 0), isTrue, reason: 'top-left corner');
      expect(
        isBorder(expectedGridW - 1, 0),
        isTrue,
        reason: 'top-right corner',
      );
      expect(
        isBorder(0, expectedGridH - 1),
        isTrue,
        reason: 'bottom-left corner',
      );
      expect(
        isBorder(expectedGridW - 1, expectedGridH - 1),
        isTrue,
        reason: 'bottom-right corner',
      );
    });

    test('first-row and first-column cells are border cells', () {
      bool isBorder(int i, int j) =>
          i == 0 || j == 0 || i == expectedGridW - 1 || j == expectedGridH - 1;

      for (int i = 0; i < expectedGridW; i++) {
        expect(isBorder(i, 0), isTrue, reason: 'top edge at i=$i');
        expect(
          isBorder(i, expectedGridH - 1),
          isTrue,
          reason: 'bottom edge at i=$i',
        );
      }
      for (int j = 0; j < expectedGridH; j++) {
        expect(isBorder(0, j), isTrue, reason: 'left edge at j=$j');
        expect(
          isBorder(expectedGridW - 1, j),
          isTrue,
          reason: 'right edge at j=$j',
        );
      }
    });

    test('interior cells are not border cells', () {
      bool isBorder(int i, int j) =>
          i == 0 || j == 0 || i == expectedGridW - 1 || j == expectedGridH - 1;

      for (int i = 1; i < expectedGridW - 1; i++) {
        for (int j = 1; j < expectedGridH - 1; j++) {
          expect(isBorder(i, j), isFalse, reason: 'interior cell ($i, $j)');
        }
      }
    });

    test(
      'cell origin and center are computed correctly for a given grid index',
      () {
        const int i = 5;
        const int j = 7;
        final cellOrigin = Vector2(i * cellSize, j * cellSize);
        final cellCenter = cellOrigin + Vector2.all(cellSize) / 2;

        expect(cellOrigin.x, equals(500.0));
        expect(cellOrigin.y, equals(700.0));
        expect(cellCenter.x, equals(550.0));
        expect(cellCenter.y, equals(750.0));
      },
    );

    test('total cell count equals gridW * gridH', () {
      expect(expectedGridW * expectedGridH, equals(1024));
    });

    test('border cell count matches perimeter formula', () {
      // Perimeter = 2*(gridW + gridH) - 4 (corners counted once).
      const int expected = 2 * (expectedGridW + expectedGridH) - 4;

      int count = 0;
      for (int i = 0; i < expectedGridW; i++) {
        for (int j = 0; j < expectedGridH; j++) {
          if (i == 0 ||
              j == 0 ||
              i == expectedGridW - 1 ||
              j == expectedGridH - 1) {
            count++;
          }
        }
      }
      expect(count, equals(expected));
    });
  });

  // ---------------------------------------------------------------------------
  // classifyCell ↔ generateLevel grid-tracking arrays
  //
  // generateLevel populates isWaterGrid, isFishZoneGrid, isZone3GroundGrid from
  // processCellAt, which now delegates to classifyCell.  These tests verify the
  // semantics of those arrays without spinning up a component tree.
  // ---------------------------------------------------------------------------

  group('generateLevel grid tracking via classifyCell', () {
    final worldCenter = GameConfig.worldSize / 2; // (1600, 1600)

    test('all zone-1 cells are marked water, never fish or zone-3 ground', () {
      // A 7×7 patch inside the 700×700 center square (±350 from centre).
      for (int di = -3; di <= 3; di++) {
        for (int dj = -3; dj <= 3; dj++) {
          final cell = Vector2(
            worldCenter.x + di * 50,
            worldCenter.y + dj * 50,
          );
          final r = WorldMixin.classifyCell(
            cellCenter: cell,
            worldCenter: worldCenter,
            ringNoiseValue: 0.0,
            outerNoiseValue: 0.0,
          );

          expect(
            r.isWater,
            isTrue,
            reason: 'zone-1 cell $cell should be water',
          );
          expect(
            r.isFishZone,
            isFalse,
            reason: 'zone-1 cell $cell is not a fish zone',
          );
          expect(
            r.isZone3Ground,
            isFalse,
            reason: 'zone-1 cell $cell is not zone-3 ground',
          );
        }
      }
    });

    test(
      'high ring noise marks zone-2 cell as water and fish-eligible when far from spawn',
      () {
        // 650 units from centre = inside ring (±700) and outside zone 1 (±350).
        final cell = Vector2(worldCenter.x + 650, worldCenter.y);

        final r = WorldMixin.classifyCell(
          cellCenter: cell,
          worldCenter: worldCenter,
          ringNoiseValue: 1.0,
          outerNoiseValue: 0.0,
        );

        expect(r.isWater, isTrue);
        expect(r.isFishZone, isTrue);
        expect(r.isZone3Ground, isFalse);
      },
    );

    test(
      'low ring noise marks zone-2 cell as ground, not fish, not zone-3',
      () {
        final cell = Vector2(worldCenter.x + 650, worldCenter.y);

        final r = WorldMixin.classifyCell(
          cellCenter: cell,
          worldCenter: worldCenter,
          ringNoiseValue: 0.0,
          outerNoiseValue: 0.0,
        );

        expect(r.isWater, isFalse);
        expect(r.isFishZone, isFalse);
        expect(
          r.isZone3Ground,
          isFalse,
          reason: 'zone-2 ground is not zone-3 ground',
        );
      },
    );

    test(
      'noise exactly at ring threshold (0.30) is ground (not strictly above)',
      () {
        // _ringGroundThreshold = 0.30; condition is ringNoiseValue > threshold.
        final cell = Vector2(worldCenter.x + 650, worldCenter.y);

        final r = WorldMixin.classifyCell(
          cellCenter: cell,
          worldCenter: worldCenter,
          ringNoiseValue: 0.30,
          outerNoiseValue: 0.0,
        );

        expect(r.isWater, isFalse);
      },
    );

    test('noise just above ring threshold is water', () {
      final cell = Vector2(worldCenter.x + 650, worldCenter.y);

      final r = WorldMixin.classifyCell(
        cellCenter: cell,
        worldCenter: worldCenter,
        ringNoiseValue: 0.31,
        outerNoiseValue: 0.0,
      );

      expect(r.isWater, isTrue);
    });

    test('zone-3 cell with high outer noise is water', () {
      // 1100 units from centre = outside ring boundary ±700.
      final cell = Vector2(worldCenter.x + 1100, worldCenter.y);

      final r = WorldMixin.classifyCell(
        cellCenter: cell,
        worldCenter: worldCenter,
        ringNoiseValue: 0.0,
        outerNoiseValue: 1.0,
      );

      expect(r.isWater, isTrue);
      expect(r.isZone3Ground, isFalse);
    });

    test(
      'zone-3 cell below outer noise threshold is ground and zone-3-ground eligible',
      () {
        final cell = Vector2(worldCenter.x + 1100, worldCenter.y);

        final r = WorldMixin.classifyCell(
          cellCenter: cell,
          worldCenter: worldCenter,
          ringNoiseValue: 0.0,
          outerNoiseValue: 0.0,
        );

        expect(r.isWater, isFalse);
        expect(r.isFishZone, isFalse);
        expect(r.isZone3Ground, isTrue);
      },
    );

    test(
      'noise exactly at outer threshold (0.65) is ground (not strictly above)',
      () {
        // _outerWaterThreshold = 0.65; condition is outerNoiseValue > threshold.
        final cell = Vector2(worldCenter.x + 1100, worldCenter.y);

        final r = WorldMixin.classifyCell(
          cellCenter: cell,
          worldCenter: worldCenter,
          ringNoiseValue: 0.0,
          outerNoiseValue: 0.65,
        );

        expect(r.isWater, isFalse);
        expect(r.isZone3Ground, isTrue);
      },
    );

    test(
      'isWater and isZone3Ground are always mutually exclusive across all zones',
      () {
        final testCases = [
          // Zone 1
          (worldCenter.clone(), 0.0, 0.0),
          // Zone 2 water
          (Vector2(worldCenter.x + 650, worldCenter.y), 1.0, 0.0),
          // Zone 2 ground
          (Vector2(worldCenter.x + 650, worldCenter.y), 0.0, 0.0),
          // Zone 3 water
          (Vector2(worldCenter.x + 1100, worldCenter.y), 0.0, 1.0),
          // Zone 3 ground
          (Vector2(worldCenter.x + 1100, worldCenter.y), 0.0, 0.0),
        ];

        for (final (cell, ringNoise, outerNoise) in testCases) {
          final r = WorldMixin.classifyCell(
            cellCenter: cell,
            worldCenter: worldCenter,
            ringNoiseValue: ringNoise,
            outerNoiseValue: outerNoise,
          );
          expect(
            r.isWater && r.isZone3Ground,
            isFalse,
            reason:
                'cell=$cell ring=$ringNoise outer=$outerNoise: cannot be both',
          );
        }
      },
    );

    test('zone-1 boundary at ±350 is inclusive (water)', () {
      // Exactly on the inner boundary of zone 1 — should still be water.
      final cell = Vector2(worldCenter.x - 350, worldCenter.y);

      final r = WorldMixin.classifyCell(
        cellCenter: cell,
        worldCenter: worldCenter,
        ringNoiseValue: 0.0,
        outerNoiseValue: 0.0,
      );

      expect(
        r.isWater,
        isTrue,
        reason: 'boundary cell at -350 is inside zone 1',
      );
    });

    test(
      'one unit outside zone-1 boundary falls into ring and obeys ring noise',
      () {
        final cell = Vector2(worldCenter.x - 351, worldCenter.y);

        final groundResult = WorldMixin.classifyCell(
          cellCenter: cell,
          worldCenter: worldCenter,
          ringNoiseValue: 0.0,
          outerNoiseValue: 0.0,
        );
        final waterResult = WorldMixin.classifyCell(
          cellCenter: cell,
          worldCenter: worldCenter,
          ringNoiseValue: 1.0,
          outerNoiseValue: 0.0,
        );

        expect(groundResult.isWater, isFalse);
        expect(
          groundResult.isZone3Ground,
          isFalse,
          reason: 'still in ring zone, not zone 3',
        );
        expect(waterResult.isWater, isTrue);
      },
    );

    test('ring boundary at ±700 is inclusive (ring zone obeys noise)', () {
      // Exactly on the outer ring boundary should be classified as ring (inOuterSquare=true,
      // inCenterWaterZone=false) so noise determines water/ground.
      final cell = Vector2(worldCenter.x + 700, worldCenter.y);

      final r = WorldMixin.classifyCell(
        cellCenter: cell,
        worldCenter: worldCenter,
        ringNoiseValue: 1.0,
        outerNoiseValue: 0.0,
      );

      expect(r.isWater, isTrue);
      expect(r.isZone3Ground, isFalse);
    });

    test(
      'one unit outside ring boundary is in zone 3 and obeys outer noise',
      () {
        final cell = Vector2(worldCenter.x + 701, worldCenter.y);

        final groundResult = WorldMixin.classifyCell(
          cellCenter: cell,
          worldCenter: worldCenter,
          ringNoiseValue: 0.0,
          outerNoiseValue: 0.0,
        );
        final waterResult = WorldMixin.classifyCell(
          cellCenter: cell,
          worldCenter: worldCenter,
          ringNoiseValue: 0.0,
          outerNoiseValue: 1.0,
        );

        expect(groundResult.isZone3Ground, isTrue);
        expect(waterResult.isWater, isTrue);
        expect(waterResult.isZone3Ground, isFalse);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // shouldSpawnInteriorThorn
  //
  // Interior thorns now spawn on water cells (not ground) whose thorn-noise
  // value falls within [thornPatchThresholdMin, thornPatchThresholdMax] and
  // whose random roll is <= thornPatchSpawnChance.
  // ---------------------------------------------------------------------------

  group('shouldSpawnInteriorThorn', () {
    test('returns false when cell is not water', () {
      expect(
        WorldMixin.shouldSpawnInteriorThorn(
          isWaterCell: false,
          thornNoiseValue: GameplayTuning.thornPatchThresholdMin,
          thornPatchRoll: 0,
        ),
        isFalse,
      );
    });

    test(
      'returns true for a water cell with noise and roll inside thresholds',
      () {
        expect(
          WorldMixin.shouldSpawnInteriorThorn(
            isWaterCell: true,
            thornNoiseValue: GameplayTuning.thornPatchThresholdMin,
            thornPatchRoll: GameplayTuning.thornPatchSpawnChance,
          ),
          isTrue,
        );
      },
    );

    test('returns false when noise is above thornPatchThresholdMax', () {
      expect(
        WorldMixin.shouldSpawnInteriorThorn(
          isWaterCell: true,
          thornNoiseValue: GameplayTuning.thornPatchThresholdMax + 0.01,
          thornPatchRoll: GameplayTuning.thornPatchSpawnChance,
        ),
        isFalse,
      );
    });

    test('returns false when noise is below thornPatchThresholdMin', () {
      expect(
        WorldMixin.shouldSpawnInteriorThorn(
          isWaterCell: true,
          thornNoiseValue: GameplayTuning.thornPatchThresholdMin - 0.01,
          thornPatchRoll: GameplayTuning.thornPatchSpawnChance,
        ),
        isFalse,
      );
    });

    test('returns false when roll exceeds thornPatchSpawnChance', () {
      expect(
        WorldMixin.shouldSpawnInteriorThorn(
          isWaterCell: true,
          thornNoiseValue: GameplayTuning.thornPatchThresholdMin,
          thornPatchRoll: GameplayTuning.thornPatchSpawnChance + 0.01,
        ),
        isFalse,
      );
    });

    test('noise exactly at thornPatchThresholdMax is still eligible', () {
      expect(
        WorldMixin.shouldSpawnInteriorThorn(
          isWaterCell: true,
          thornNoiseValue: GameplayTuning.thornPatchThresholdMax,
          thornPatchRoll: 0,
        ),
        isTrue,
      );
    });

    test(
      'roll of zero always passes the chance gate when noise is in window',
      () {
        expect(
          WorldMixin.shouldSpawnInteriorThorn(
            isWaterCell: true,
            thornNoiseValue:
                (GameplayTuning.thornPatchThresholdMin +
                    GameplayTuning.thornPatchThresholdMax) /
                2,
            thornPatchRoll: 0,
          ),
          isTrue,
        );
      },
    );
  });

  // test('fish spawn patch requires full 2x2 valid water area', () {
  //   final cells = <List<bool>>[
  //     <bool>[true, true, false],
  //     <bool>[true, true, true],
  //     <bool>[true, true, true],
  //   ];

  //   expect(
  //     WorldMixin.canSpawnFishInPatch(
  //       fishSpawnableCells: cells,
  //       column: 0,
  //       row: 0,
  //     ),
  //     isTrue,
  //   );
  //   expect(
  //     WorldMixin.canSpawnFishInPatch(
  //       fishSpawnableCells: cells,
  //       column: 0,
  //       row: 1,
  //     ),
  //     isFalse,
  //   );
  // });

  // test('fish spawn patch rejects out-of-bounds coordinates', () {
  //   final cells = <List<bool>>[
  //     <bool>[true, true],
  //     <bool>[true, true],
  //   ];

  //   expect(
  //     WorldMixin.canSpawnFishInPatch(
  //       fishSpawnableCells: cells,
  //       column: -1,
  //       row: 0,
  //     ),
  //     isFalse,
  //   );
  //   expect(
  //     WorldMixin.canSpawnFishInPatch(
  //       fishSpawnableCells: cells,
  //       column: 1,
  //       row: 0,
  //     ),
  //     isFalse,
  //   );
  //   expect(
  //     WorldMixin.canSpawnFishInPatch(
  //       fishSpawnableCells: cells,
  //       column: 0,
  //       row: 1,
  //     ),
  //     isFalse,
  //   );
  // });

  // test('fish spawn center is middle of 2x2 patch', () {
  //   final center = WorldMixin.fishSpawnCenter(column: 2, row: 3);

  //   expect(center.x, closeTo(300, 0.0001));
  //   expect(center.y, closeTo(400, 0.0001));
  // });

  // test('leaf spawnable cell must be land and non-thorn', () {
  //   expect(
  //     WorldMixin.isLeafSpawnableCell(isWaterCell: false, isThornCell: false),
  //     isTrue,
  //   );
  //   expect(
  //     WorldMixin.isLeafSpawnableCell(isWaterCell: true, isThornCell: false),
  //     isFalse,
  //   );
  //   expect(
  //     WorldMixin.isLeafSpawnableCell(isWaterCell: false, isThornCell: true),
  //     isFalse,
  //   );
  // });

  // test('leaf position must keep fish clearance', () {
  //   expect(
  //     WorldMixin.isLeafPositionFarEnoughFromFish(
  //       leafCenter: Vector2(100, 100),
  //       spawnedFishPositions: <Vector2>[Vector2(180, 100)],
  //     ),
  //     isFalse,
  //   );
  //   expect(
  //     WorldMixin.isLeafPositionFarEnoughFromFish(
  //       leafCenter: Vector2(100, 100),
  //       spawnedFishPositions: <Vector2>[Vector2(500, 500)],
  //     ),
  //     isTrue,
  //   );
  // });
}
