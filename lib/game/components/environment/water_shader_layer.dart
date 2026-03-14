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

  ui.FragmentShader? _waterShader;
  double _time = 0;

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
            'shaders/water.frag',
          ));
      _waterProgram = program;
      _waterShader = program.fragmentShader();
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

  @override
  void render(ui.Canvas canvas) {
    final List<ui.Rect> bounds = _level.waterBounds;
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

    final ui.Paint paint = ui.Paint()..shader = shader;
    for (final ui.Rect rect in bounds) {
      canvas.save();
      canvas.translate(rect.left, rect.top);
      shader
        ..setFloat(0, rect.width)
        ..setFloat(1, rect.height)
        ..setFloat(2, _time)
        ..setFloat(3, rect.left)
        ..setFloat(4, rect.top);
      canvas.drawRect(ui.Rect.fromLTWH(0, 0, rect.width, rect.height), paint);
      canvas.restore();
    }
  }
}
