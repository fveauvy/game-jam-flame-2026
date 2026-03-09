import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/core/config/gameplay_tuning.dart';
import 'package:game_jam/game/world/world_mixin.dart';

void main() {
  test('never spawns interior thorn in water or spawn zone', () {
    expect(
      WorldMixin.shouldSpawnInteriorThorn(
        isWaterCell: true,
        inSpawnZone: false,
        thornNoiseValue: GameplayTuning.thornPatchThresholdMin,
        thornPatchRoll: 0,
      ),
      isFalse,
    );
    expect(
      WorldMixin.shouldSpawnInteriorThorn(
        isWaterCell: false,
        inSpawnZone: true,
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
        thornNoiseValue: GameplayTuning.thornPatchThresholdMin,
        thornPatchRoll: GameplayTuning.thornPatchSpawnChance,
      ),
      isTrue,
    );
    expect(
      WorldMixin.shouldSpawnInteriorThorn(
        isWaterCell: false,
        inSpawnZone: false,
        thornNoiseValue: GameplayTuning.thornPatchThresholdMax + 1,
        thornPatchRoll: GameplayTuning.thornPatchSpawnChance,
      ),
      isFalse,
    );
    expect(
      WorldMixin.shouldSpawnInteriorThorn(
        isWaterCell: false,
        inSpawnZone: false,
        thornNoiseValue: GameplayTuning.thornPatchThresholdMin,
        thornPatchRoll: GameplayTuning.thornPatchSpawnChance + 1,
      ),
      isFalse,
    );
  });
}
