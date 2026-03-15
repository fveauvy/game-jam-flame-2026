import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:game_jam/game/my_game.dart';
import 'package:game_jam/game/world/generated_level.dart';

class WaterShaderLayer extends Component with HasGameReference<MyGame> {
  WaterShaderLayer({required GeneratedLevel level})
    : _level = level,
      super(priority: -1);

  static ui.FragmentProgram? _waterProgram;
  static Future<ui.FragmentProgram>? _waterProgramLoader;

  final GeneratedLevel _level;
  final ui.Paint _fallbackPaint = ui.Paint()
    ..color = const ui.Color.fromARGB(180, 35, 112, 191);
  final ui.Paint _shaderPaint = ui.Paint();
  final List<ui.Rect> _renderBounds = <ui.Rect>[];
  final List<double> _shaderRectsUniforms = <double>[];
  final List<_PuddleData> _puddles = <_PuddleData>[];
  final List<double> _shaderPuddlesUniforms = <double>[];

  ui.FragmentShader? _waterShader;
  double _time = 0;
  double _tileSize = 1;
  int _cachedWaterRevision = -1;

  static const double _rectTolerance = 0.001;
  static const int _maxShaderRects = 32;
  static const int _maxShaderPuddles = 32;

  ui.Rect _coverageRect = ui.Rect.zero;
  int _packedPuddleCount = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _ensureShader();
  }

  Future<void> _ensureShader() async {
    try {
      final ui.FragmentProgram program =
          _waterProgram ??
          await (_waterProgramLoader ??= ui.FragmentProgram.fromAsset(
            'shaders/watah.frag',
          ));
      _waterProgram = program;
      _waterShader = program.fragmentShader();
      debugPrint('[shader] water shader loaded successfully');
    } catch (error) {
      _waterShader = null;
      debugPrint('[shader] water shader unavailable: $error');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  void _syncRenderBoundsIfNeeded() {
    final int revision = _level.waterRevision;
    if (revision == _cachedWaterRevision) {
      return;
    }
    _cachedWaterRevision = revision;
    _rebuildRenderBounds();
  }

  void _rebuildRenderBounds() {
    final List<ui.Rect> sourceBounds = _level.waterBounds;
    _renderBounds
      ..clear()
      ..addAll(sourceBounds);
    _puddles.clear();

    if (sourceBounds.isEmpty) {
      _tileSize = 1;
      _coverageRect = ui.Rect.zero;
      return;
    }

    final double candidateTileSize = sourceBounds.first.width;
    final bool canMerge = _canMergeBounds(sourceBounds, candidateTileSize);
    if (!canMerge) {
      _tileSize = candidateTileSize <= 0 ? 1 : candidateTileSize;
      _coverageRect = _computeCoverageRect(_renderBounds);
      _rebuildPuddlesFromBounds(_renderBounds);
      return;
    }

    _tileSize = candidateTileSize;
    _renderBounds
      ..clear()
      ..addAll(_mergeBounds(sourceBounds, candidateTileSize));
    _coverageRect = _computeCoverageRect(_renderBounds);
    _rebuildPuddlesFromTiles(sourceBounds, candidateTileSize);
  }

  ui.Rect _computeCoverageRect(List<ui.Rect> bounds) {
    if (bounds.isEmpty) {
      return ui.Rect.zero;
    }

    double minLeft = bounds.first.left;
    double minTop = bounds.first.top;
    double maxRight = bounds.first.right;
    double maxBottom = bounds.first.bottom;

    for (int i = 1; i < bounds.length; i++) {
      final ui.Rect rect = bounds[i];
      if (rect.left < minLeft) {
        minLeft = rect.left;
      }
      if (rect.top < minTop) {
        minTop = rect.top;
      }
      if (rect.right > maxRight) {
        maxRight = rect.right;
      }
      if (rect.bottom > maxBottom) {
        maxBottom = rect.bottom;
      }
    }

    return ui.Rect.fromLTRB(minLeft, minTop, maxRight, maxBottom);
  }

  void _packShaderRects(List<ui.Rect> bounds) {
    _shaderRectsUniforms.clear();
    for (final ui.Rect rect in bounds) {
      _shaderRectsUniforms
        ..add(rect.left)
        ..add(rect.top)
        ..add(rect.right)
        ..add(rect.bottom);
    }
  }

  void _packShaderPuddles() {
    _shaderPuddlesUniforms.clear();
    final int count = _puddles.length > _maxShaderPuddles
        ? _maxShaderPuddles
        : _puddles.length;
    _packedPuddleCount = count;

    for (int i = 0; i < count; i++) {
      final _PuddleData puddle = _puddles[i];
      _shaderPuddlesUniforms
        ..add(puddle.left)
        ..add(puddle.top)
        ..add(puddle.right)
        ..add(puddle.bottom);
    }
  }

  void _rebuildPuddlesFromBounds(List<ui.Rect> bounds) {
    _puddles.clear();
    for (final ui.Rect rect in bounds) {
      _puddles.add(
        _PuddleData(
          left: rect.left,
          top: rect.top,
          right: rect.right,
          bottom: rect.bottom,
        ),
      );
    }
  }

  void _rebuildPuddlesFromTiles(List<ui.Rect> tiles, double tileSize) {
    _puddles.clear();

    final Set<_GridCoord> tileCoords = <_GridCoord>{};
    for (final ui.Rect tile in tiles) {
      final int row = (tile.top / tileSize).round();
      final int col = (tile.left / tileSize).round();
      tileCoords.add(_GridCoord(row: row, col: col));
    }

    final Set<_GridCoord> visited = <_GridCoord>{};
    for (final _GridCoord start in tileCoords) {
      if (visited.contains(start)) {
        continue;
      }

      final List<_GridCoord> stack = <_GridCoord>[start];
      int minRow = start.row;
      int maxRow = start.row;
      int minCol = start.col;
      int maxCol = start.col;

      while (stack.isNotEmpty) {
        final _GridCoord current = stack.removeLast();
        if (!tileCoords.contains(current) || visited.contains(current)) {
          continue;
        }

        visited.add(current);

        if (current.row < minRow) {
          minRow = current.row;
        }
        if (current.row > maxRow) {
          maxRow = current.row;
        }
        if (current.col < minCol) {
          minCol = current.col;
        }
        if (current.col > maxCol) {
          maxCol = current.col;
        }

        stack
          ..add(_GridCoord(row: current.row - 1, col: current.col))
          ..add(_GridCoord(row: current.row + 1, col: current.col))
          ..add(_GridCoord(row: current.row, col: current.col - 1))
          ..add(_GridCoord(row: current.row, col: current.col + 1));
      }

      final double left = minCol * tileSize;
      final double top = minRow * tileSize;
      final double right = (maxCol + 1) * tileSize;
      final double bottom = (maxRow + 1) * tileSize;

      _puddles.add(
        _PuddleData(left: left, top: top, right: right, bottom: bottom),
      );
    }
  }

  bool _canMergeBounds(List<ui.Rect> bounds, double tileSize) {
    if (!tileSize.isFinite || tileSize <= 0) {
      return false;
    }

    for (final ui.Rect rect in bounds) {
      final bool sameTileSize =
          (rect.width - tileSize).abs() <= _rectTolerance &&
          (rect.height - tileSize).abs() <= _rectTolerance;
      if (!sameTileSize) {
        return false;
      }

      final double col = rect.left / tileSize;
      final double row = rect.top / tileSize;
      if ((col - col.roundToDouble()).abs() > _rectTolerance ||
          (row - row.roundToDouble()).abs() > _rectTolerance) {
        return false;
      }
    }

    return true;
  }

  List<ui.Rect> _mergeBounds(List<ui.Rect> bounds, double tileSize) {
    final Map<int, List<int>> rowToColumns = <int, List<int>>{};
    for (final ui.Rect rect in bounds) {
      final int row = (rect.top / tileSize).round();
      final int col = (rect.left / tileSize).round();
      rowToColumns.putIfAbsent(row, () => <int>[]).add(col);
    }

    final List<int> rows = rowToColumns.keys.toList()..sort();
    final List<_RowSpan> rowSpans = <_RowSpan>[];
    for (final int row in rows) {
      final List<int> columns = rowToColumns[row]!..sort();
      if (columns.isEmpty) {
        continue;
      }

      int start = columns.first;
      int end = columns.first;
      for (int i = 1; i < columns.length; i++) {
        final int col = columns[i];
        if (col <= end + 1) {
          end = col;
          continue;
        }
        rowSpans.add(_RowSpan(row: row, leftCol: start, rightCol: end));
        start = col;
        end = col;
      }
      rowSpans.add(_RowSpan(row: row, leftCol: start, rightCol: end));
    }

    final Map<_SpanKey, List<_RowSpan>> spansByRange =
        <_SpanKey, List<_RowSpan>>{};
    for (final _RowSpan span in rowSpans) {
      final _SpanKey key = _SpanKey(span.leftCol, span.rightCol);
      spansByRange.putIfAbsent(key, () => <_RowSpan>[]).add(span);
    }

    final List<ui.Rect> merged = <ui.Rect>[];
    for (final MapEntry<_SpanKey, List<_RowSpan>> entry
        in spansByRange.entries) {
      final List<_RowSpan> spans = entry.value
        ..sort((a, b) => a.row.compareTo(b.row));
      int startRow = spans.first.row;
      int endRow = spans.first.row;
      for (int i = 1; i < spans.length; i++) {
        final _RowSpan span = spans[i];
        if (span.row == endRow + 1) {
          endRow = span.row;
          continue;
        }
        merged.add(
          ui.Rect.fromLTWH(
            entry.key.leftCol * tileSize,
            startRow * tileSize,
            (entry.key.rightCol - entry.key.leftCol + 1) * tileSize,
            (endRow - startRow + 1) * tileSize,
          ),
        );
        startRow = span.row;
        endRow = span.row;
      }
      merged.add(
        ui.Rect.fromLTWH(
          entry.key.leftCol * tileSize,
          startRow * tileSize,
          (entry.key.rightCol - entry.key.leftCol + 1) * tileSize,
          (endRow - startRow + 1) * tileSize,
        ),
      );
    }

    merged.sort((ui.Rect a, ui.Rect b) {
      final int topCompare = a.top.compareTo(b.top);
      if (topCompare != 0) {
        return topCompare;
      }
      return a.left.compareTo(b.left);
    });
    return merged;
  }

  @override
  void render(ui.Canvas canvas) {
    _syncRenderBoundsIfNeeded();

    final List<ui.Rect> bounds = _renderBounds;
    if (bounds.isEmpty) {
      return;
    }

    final ui.FragmentShader? shader = _waterShader;
    if (shader == null) {
      for (final ui.Rect rect in bounds) {
        canvas.drawRect(rect, _fallbackPaint);
      }
      return;
    }

    if (bounds.length > _maxShaderRects) {
      // Fallback for very fragmented water regions that exceed uniform budget.
      for (final ui.Rect rect in bounds) {
        canvas.drawRect(rect, _fallbackPaint);
      }
      return;
    }

    final ui.Rect coverageRect = _coverageRect;
    if (coverageRect.isEmpty) {
      return;
    }

    _packShaderRects(bounds);
    _packShaderPuddles();

    shader
      ..setFloat(0, _tileSize)
      ..setFloat(1, _tileSize)
      ..setFloat(2, _time)
      ..setFloat(3, coverageRect.left)
      ..setFloat(4, coverageRect.top)
      ..setFloat(5, bounds.length.toDouble());

    int uniformIndex = 6;
    for (final double value in _shaderRectsUniforms) {
      shader.setFloat(uniformIndex, value);
      uniformIndex++;
    }

    // uRects[32] always occupies exactly 32 * 4 = 128 float slots (indices
    // 6..133). Jump to the fixed position of uPuddleCount regardless of how
    // many rects were actually written.
    uniformIndex = 6 + 32 * 4;

    shader.setFloat(uniformIndex, _packedPuddleCount.toDouble());
    uniformIndex++;
    for (final double value in _shaderPuddlesUniforms) {
      shader.setFloat(uniformIndex, value);
      uniformIndex++;
    }

    _shaderPaint.shader = shader;
    canvas.save();
    canvas.translate(coverageRect.left, coverageRect.top);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, coverageRect.width, coverageRect.height),
      _shaderPaint,
    );
    canvas.restore();
  }
}

class _RowSpan {
  const _RowSpan({
    required this.row,
    required this.leftCol,
    required this.rightCol,
  });

  final int row;
  final int leftCol;
  final int rightCol;
}

class _SpanKey {
  const _SpanKey(this.leftCol, this.rightCol);

  final int leftCol;
  final int rightCol;

  @override
  bool operator ==(Object other) {
    return other is _SpanKey &&
        other.leftCol == leftCol &&
        other.rightCol == rightCol;
  }

  @override
  int get hashCode => Object.hash(leftCol, rightCol);
}

class _GridCoord {
  const _GridCoord({required this.row, required this.col});

  final int row;
  final int col;

  @override
  bool operator ==(Object other) {
    return other is _GridCoord && other.row == row && other.col == col;
  }

  @override
  int get hashCode => Object.hash(row, col);
}

class _PuddleData {
  const _PuddleData({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;
}
