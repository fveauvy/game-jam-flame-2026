import 'package:flame/components.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/game/components/environment/ground_component.dart';

class Level1 extends Component {
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final GroundComponent ground = GroundComponent(
      position: Vector2(0, GameConfig.groundY + 48),
      size: Vector2(GameConfig.worldSize.x, GameConfig.worldSize.y),
    );
    add(ground);
  }
}
