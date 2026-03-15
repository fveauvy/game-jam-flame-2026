import 'package:flame/components.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/game/components/enemies/simple_oponenet.dart';
import 'package:game_jam/game/components/environment/ground_component.dart';
import 'package:game_jam/game/components/environment/water_component.dart';
import 'package:game_jam/game/components/environment/water_lily_component.dart';

class Level1 extends Component {
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final GroundComponent ground = GroundComponent(
      position: Vector2(0, GameConfig.groundY + 48),
      size: Vector2(GameConfig.worldSize.x, GameConfig.worldSize.y),
    );
    final WaterComponent water = WaterComponent(
      assetPosition: WaterAssetPosition.bottom,
      position: Vector2(100, GameConfig.groundY + 48),
      size: Vector2(100, 200),
    );

    final waterLily = WaterLilyComponent(
      position: Vector2(800, 800),
      radius: 40,
    );

    final simpleOpponent = SimpleOpponent(
      position: Vector2(100, 100),
      radius: 40,
    );

    await addAll([ground, water, waterLily, simpleOpponent]);
  }
}
