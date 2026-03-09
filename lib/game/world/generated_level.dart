import 'package:flame/components.dart';
import 'package:game_jam/core/entities/biome_type.dart';
import 'package:game_jam/game/components/environment/thorn_component.dart';
import 'package:game_jam/game/my_game.dart';
import 'package:game_jam/game/world/world_mixin.dart';

class GeneratedLevel extends Component
    with HasGameReference<MyGame>, WorldMixin {
  late BiomeType biome;

  @override
  Future<void> onLoad() async {
    biome = computeBiome();
    await generateLevel(biome);
    await super.onLoad();
  }

  Future<void> onUpdateSeed() async {
    removeAll(children);
    biome = computeBiome();
    await generateLevel(biome);
  }

  bool isPositionOnThorn(Vector2 position) {
    for (final ThornComponent thorn in children.whereType<ThornComponent>()) {
      final bool insideX =
          position.x >= thorn.position.x &&
          position.x <= thorn.position.x + thorn.size.x;
      final bool insideY =
          position.y >= thorn.position.y &&
          position.y <= thorn.position.y + thorn.size.y;
      if (insideX && insideY) {
        return true;
      }
    }
    return false;
  }
}
