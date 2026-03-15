import 'dart:collection';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/entities/biome_type.dart';
import 'package:game_jam/game/components/environment/frog_house_component.dart';
import 'package:game_jam/game/components/environment/thorn_component.dart';
import 'package:game_jam/game/components/environment/water_lily_component.dart';
import 'package:game_jam/game/my_game.dart';
import 'package:game_jam/game/world/world_mixin.dart';

class GeneratedLevel extends Component
    with HasGameReference<MyGame>, WorldMixin {
  late BiomeType biome;
  final List<Rect> _waterBounds = <Rect>[];
  final List<Rect> _leafBounds = <Rect>[];
  final List<Rect> _waterLilies = <Rect>[];
  final List<Rect> _frogHouses = <Rect>[];
  late final UnmodifiableListView<Rect> _waterBoundsView =
      UnmodifiableListView<Rect>(_waterBounds);
  int _waterRevision = 0;

  List<List<bool>> _isWaterGrid = <List<bool>>[];
  double _waterGridCellSize = GameConfig.worldCellSize;
  int _waterGridWidth = 0;
  int _waterGridHeight = 0;

  UnmodifiableListView<Rect> get waterBounds => _waterBoundsView;
  int get waterRevision => _waterRevision;

  @override
  Future<void> onLoad() async {
    final (List<Rect> waterBounds, List<Rect> leafBounds) =
        await generateLevel();
    _setGeneratedBounds(waterBounds: waterBounds, leafBounds: leafBounds);
    _waterLilies.addAll(
      children.whereType<WaterLilyComponent>().map((lily) => lily.toRect()),
    );
    _frogHouses.addAll(
      children.whereType<FrogHouseComponent>().map((house) => house.toRect()),
    );
    await super.onLoad();
  }

  Future<void> onUpdateSeed() async {
    _waterLilies.clear();
    _frogHouses.clear();
    removeAll(children);
    final (List<Rect> waterBounds, List<Rect> leafBounds) =
        await generateLevel();
    _setGeneratedBounds(waterBounds: waterBounds, leafBounds: leafBounds);
    _waterLilies.addAll(
      children.whereType<WaterLilyComponent>().map((lily) => lily.toRect()),
    );
    _frogHouses.addAll(
      children.whereType<FrogHouseComponent>().map((house) => house.toRect()),
    );
  }

  void _setGeneratedBounds({
    required List<Rect> waterBounds,
    required List<Rect> leafBounds,
  }) {
    _waterBounds
      ..clear()
      ..addAll(waterBounds);
    _leafBounds
      ..clear()
      ..addAll(leafBounds);
    _waterRevision++;
    _rebuildWaterGridIndex();
  }

  void _rebuildWaterGridIndex() {
    if (_waterBounds.isEmpty) {
      _isWaterGrid = <List<bool>>[];
      _waterGridCellSize = GameConfig.worldCellSize;
      _waterGridWidth = 0;
      _waterGridHeight = 0;
      return;
    }

    double cellSize = _waterBounds.first.width;
    if (!cellSize.isFinite || cellSize <= 0) {
      cellSize = GameConfig.worldCellSize;
    }

    for (final Rect rect in _waterBounds) {
      if ((rect.width - cellSize).abs() > 0.001 ||
          (rect.height - cellSize).abs() > 0.001) {
        cellSize = GameConfig.worldCellSize;
        break;
      }
    }

    final int gridW = (GameConfig.worldSize.x / cellSize).ceil();
    final int gridH = (GameConfig.worldSize.y / cellSize).ceil();
    final List<List<bool>> grid = List<List<bool>>.generate(
      gridW,
      (_) => List<bool>.filled(gridH, false),
      growable: false,
    );

    for (final Rect rect in _waterBounds) {
      final int minI = (rect.left / cellSize).floor().clamp(0, gridW - 1);
      final int maxI = ((rect.right - 0.000001) / cellSize).floor().clamp(
        0,
        gridW - 1,
      );
      final int minJ = (rect.top / cellSize).floor().clamp(0, gridH - 1);
      final int maxJ = ((rect.bottom - 0.000001) / cellSize).floor().clamp(
        0,
        gridH - 1,
      );

      for (int i = minI; i <= maxI; i++) {
        final List<bool> column = grid[i];
        for (int j = minJ; j <= maxJ; j++) {
          column[j] = true;
        }
      }
    }

    _isWaterGrid = grid;
    _waterGridCellSize = cellSize;
    _waterGridWidth = gridW;
    _waterGridHeight = gridH;
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

  bool isPositionInWaterLily(Vector2 position) {
    for (final Rect lily in _waterLilies) {
      if (lily.contains(Offset(position.x, position.y))) {
        return true;
      }
    }
    return false;
  }

  bool isPositionInWater(Vector2 position) {
    if (_isWaterGrid.isNotEmpty) {
      final int i = (position.x / _waterGridCellSize).floor();
      final int j = (position.y / _waterGridCellSize).floor();
      if (i < 0 || i >= _waterGridWidth || j < 0 || j >= _waterGridHeight) {
        return false;
      }
      return _isWaterGrid[i][j];
    }

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

  bool isPositionOnFrogHouse(Vector2 position) {
    for (final Rect house in _frogHouses) {
      if (house.contains(Offset(position.x, position.y))) {
        return true;
      }
    }
    return false;
  }
}
