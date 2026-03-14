import 'dart:collection';
import 'dart:ui';

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
  List<Rect> _waterBounds = <Rect>[];
  List<Rect> _leafBounds = <Rect>[];

  UnmodifiableListView<Rect> get waterBounds =>
      UnmodifiableListView<Rect>(_waterBounds);

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
    _waterBounds = <Rect>[];
    _leafBounds = <Rect>[];
    biome = computeBiome();
    await generateLevel(biome);
    _rebuildWaterBounds();
    _rebuildLeafBounds();
  }

  void _rebuildWaterBounds() {
    _waterBounds = children
        .whereType<WaterComponent>()
        .map(
          (WaterComponent water) => Rect.fromLTWH(
            water.position.x,
            water.position.y,
            water.size.x,
            water.size.y,
          ),
        )
        .toList(growable: false);
  }

  void _rebuildLeafBounds() {
    _leafBounds = children
        .whereType<LeafComponent>()
        .map(
          (LeafComponent leaf) => Rect.fromLTWH(
            leaf.position.x,
            leaf.position.y,
            leaf.size.x,
            leaf.size.y,
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
    final Offset point = Offset(position.x, position.y);
    for (final Rect bounds in _waterBounds) {
      if (bounds.contains(point)) {
        return true;
      }
    }
    return false;
  }

  bool isPositionOnLeaf(Vector2 position) {
    final Offset point = Offset(position.x, position.y);
    for (final Rect bounds in _leafBounds) {
      if (bounds.contains(point)) {
        return true;
      }
    }
    return false;
  }
}
