import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/post_process.dart';
import 'package:flutter/material.dart';

/// A post-processing effect that renders a warm pulsing golden glow (halo)
/// around the egg sprite. This is applied only to free-standing eggs
/// (i.e. [EggComponent] with `isOnBack == false`).
class EggAnimationProcess extends PostProcess {
  static ui.FragmentProgram? _program;
  static Future<ui.FragmentProgram>? _programLoader;

  ui.FragmentShader? _shader;

  double _time = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _ensureShader();
  }

  Future<void> _ensureShader() async {
    try {
      final ui.FragmentProgram program =
          _program ??
          await (_programLoader ??= ui.FragmentProgram.fromAsset(
            'shaders/egg_animation.frag',
          ));
      _program = program;
      _shader = program.fragmentShader();
    } catch (error) {
      _shader = null;
      debugPrint('[shader] egg glow shader unavailable: $error');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void postProcess(Vector2 size, Canvas canvas) {
    final ui.FragmentShader? shader = _shader;
    if (shader == null) {
      renderSubtree(canvas);
      return;
    }

    final ui.Image preRendered = rasterizeSubtree();

    shader
      ..setFloat(0, size.x)
      ..setFloat(1, size.y)
      ..setFloat(2, _time)
      ..setImageSampler(0, preRendered);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..shader = shader,
    );
  }
}
