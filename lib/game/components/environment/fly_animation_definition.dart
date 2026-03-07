import 'package:flame/components.dart';
import 'package:game_jam/core/entities/animation_definition.dart';

mixin FlyAnimationDefinition on PositionComponent
    implements AnimationDefinition {
  @override
  int get amount => 3;

  @override
  bool get loop => true;

  @override
  double? get stepTime => 0.1;

  @override
  Vector2 get textureSize => Vector2(192, 168);

  @override
  SpriteAnimationData get animationData => SpriteAnimationData.sequenced(
    amount: amount,
    stepTime: stepTime ?? 0.1,
    loop: loop,
    textureSize: textureSize,
  );
}
