import 'package:flame/components.dart';

abstract class AnimationDefinition {
  Vector2 get textureSize;
  int get amount;
  double? get stepTime;
  bool get loop;

  SpriteAnimationData get animationData;
}
