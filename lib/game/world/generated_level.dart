import 'package:flame/components.dart';
import 'package:game_jam/core/entities/biome_type.dart';
import 'package:game_jam/game/components/environment/leaf_component.dart';
import 'package:game_jam/game/components/environment/thorn_component.dart';
import 'package:game_jam/game/components/environment/water_component.dart';
import 'package:game_jam/game/my_game.dart';
import 'package:game_jam/game/world/world_mixin.dart';

class GeneratedLevel extends Component
    with HasGameReference<MyGame>, WorldMixin {
  late BiomeType biome;
  List<_AxisAlignedBounds> _waterBounds = <_AxisAlignedBounds>[];
  List<_AxisAlignedBounds> _leafBounds = <_AxisAlignedBounds>[];

  @override
  Future<void> onLoad() async {
    biome = computeBiome();
    await generateLevel(biome);
    _rebuildWaterBounds();
    _rebuildLeafBounds();
    await super.onLoad();
  }

  Future<void> onUpdateSeed() async {
    removeAll(children);
    _waterBounds = <_AxisAlignedBounds>[];
    _leafBounds = <_AxisAlignedBounds>[];
    biome = computeBiome();
    await generateLevel(biome);
    _rebuildWaterBounds();
    _rebuildLeafBounds();
  }

  void _rebuildWaterBounds() {
    _waterBounds = children
        .whereType<WaterComponent>()
        .map(
          (WaterComponent water) => _AxisAlignedBounds(
            left: water.position.x,
            top: water.position.y,
            right: water.position.x + water.size.x,
            bottom: water.position.y + water.size.y,
          ),
        )
        .toList(growable: false);
  }

  void _rebuildLeafBounds() {
    _leafBounds = children
        .whereType<LeafComponent>()
        .map(
          (LeafComponent leaf) => _AxisAlignedBounds(
            left: leaf.position.x,
            top: leaf.position.y,
            right: leaf.position.x + leaf.size.x,
            bottom: leaf.position.y + leaf.size.y,
          ),
        )
        .toList(growable: false);
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

  bool isPositionInWater(Vector2 position) {
    for (final _AxisAlignedBounds bounds in _waterBounds) {
      if (bounds.contains(position)) {
        return true;
      }
    }
    return false;
  }

  bool isPositionOnLeaf(Vector2 position) {
    for (final _AxisAlignedBounds bounds in _leafBounds) {
      if (bounds.contains(position)) {
        return true;
      }
    }
    return false;
  }
}

class _AxisAlignedBounds {
  const _AxisAlignedBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  bool contains(Vector2 point) {
    return point.x >= left &&
        point.x <= right &&
        point.y >= top &&
        point.y <= bottom;
  }
}
