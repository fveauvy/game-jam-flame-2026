import 'dart:math';

import 'package:flame/components.dart';
import 'package:game_jam/game/components/environment/fly_animation_definition.dart';
import 'package:game_jam/game/my_game.dart';

class FlyComponent extends SpriteAnimationComponent
    with HasGameReference<MyGame>, FlyAnimationDefinition {
  FlyComponent({super.position, super.size}) : super(priority: 100);

  static const double _minRadius = 20;
  static const double _maxRadius = 60;
  static const double _minAngleSpeed = 1.5;
  static const double _maxAngleSpeed = 3.5;

  late final Vector2 _orbitCenter;
  late final double _radius;
  late final double _angleSpeed;
  double _angle = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _orbitCenter = position.clone();
    _radius = _minRadius + game.random.nextDouble() * (_maxRadius - _minRadius);
    _angleSpeed =
        (_minAngleSpeed +
            game.random.nextDouble() * (_maxAngleSpeed - _minAngleSpeed)) *
        (game.random.nextBool() ? 1 : -1);
    _angle = game.random.nextDouble() * 2 * pi;

    if (_angleSpeed < 0) {
      flipHorizontally();
    }

    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('fly.png'),
      animationData,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    _angle += _angleSpeed * dt;

    position
      ..x =
          _orbitCenter.x +
          _radius * cos(_angle) +
          game.random.nextDouble() * 100 * dt
      ..y = _orbitCenter.y + _radius * sin(_angle);
  }
}
