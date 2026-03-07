import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

abstract interface class VisionHitBoxDelegate {
  void onVisionHitBoxCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other);
  void onVisionHitBoxCollisionEnd(PositionComponent other);
}

class VisionHitBox extends CircleComponent with CollisionCallbacks {
  VisionHitBox({ super.radius, super.position });

  VisionHitBoxDelegate? get delegate => (parent is VisionHitBoxDelegate) ? parent as VisionHitBoxDelegate : null;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    priority = 50;
    add(CircleHitbox(radius: radius));
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    delegate?.onVisionHitBoxCollisionStart(intersectionPoints, other);
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    delegate?.onVisionHitBoxCollisionEnd(other);
  }
}
