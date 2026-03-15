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

  ui.FragmentShader? _waterShader;
  double _time = 0;
  double _tileSize = 1;
  int _cachedWaterRevision = -1;

  static const double _rectTolerance = 0.001;

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

    if (sourceBounds.isEmpty) {
      _tileSize = 1;
      return;
    }

    final double candidateTileSize = sourceBounds.first.width;
    if (!_canMergeBounds(sourceBounds, candidateTileSize)) {
      _tileSize = candidateTileSize <= 0 ? 1 : candidateTileSize;
      return;
    }

    _tileSize = candidateTileSize;
    _renderBounds
      ..clear()
      ..addAll(_mergeBounds(sourceBounds, candidateTileSize));
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

    _shaderPaint.shader = shader;
    for (final ui.Rect rect in bounds) {
      canvas.save();
      canvas.translate(rect.left, rect.top);
      shader
        ..setFloat(0, _tileSize)
        ..setFloat(1, _tileSize)
        ..setFloat(2, _time)
        ..setFloat(3, rect.left)
        ..setFloat(4, rect.top);
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, rect.width, rect.height),
        _shaderPaint,
      );
      canvas.restore();
    }
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
