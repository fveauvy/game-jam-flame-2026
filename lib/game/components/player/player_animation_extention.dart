import 'package:flame/components.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/core/entities/player_vertical_position.dart';
import 'package:game_jam/game/components/player/player_component.dart';

extension PlayerAnimationExtension on PlayerComponent {
  List<String> get _supportedSpritesId =>
      AssetPaths.animatedFrogSpriteId.map((id) => 'frog-$id').toList();

  static const String _jump1Name = 'Saut1.png';
  static const String _jump2Name = 'Saut2.png';

  static const String _idleLandName = 'Saut1.png';
  static const String _idleWaterName = 'Chill.png';

  static const String _swim1Name = 'Nage1.png';
  static const String _swim2Name = 'Nage2.png';

  SpriteAnimation moveAnimation(PlayerVerticalPosition type) {
    if (!_supportedSpritesId.contains(profile.spriteId)) {
      return SpriteAnimation.spriteList(
        [
          Sprite(
            game.images.fromCache("gronouy/${profile.spriteId}.png"),
            srcSize: Vector2(200, 200),
          ),
        ],
        stepTime: double.infinity,
        loop: false,
      );
    }
    switch (type) {
      case PlayerVerticalPosition.land:
        return SpriteAnimation.spriteList(
          [
            Sprite(
              game.images.fromCache('gronouy/${profile.spriteId}/$_jump1Name'),
              srcSize: Vector2(200, 200),
            ),
            Sprite(
              game.images.fromCache('gronouy/${profile.spriteId}/$_jump2Name'),
              srcSize: Vector2(200, 200),
            ),
          ],
          stepTime: 0.3,
          loop: true,
        );
      case PlayerVerticalPosition.waterLevel:
      case PlayerVerticalPosition.underwater:
        return SpriteAnimation.spriteList(
          [
            Sprite(
              game.images.fromCache('gronouy/${profile.spriteId}/$_swim1Name'),
              srcSize: Vector2(200, 200),
            ),
            Sprite(
              game.images.fromCache('gronouy/${profile.spriteId}/$_swim2Name'),
              srcSize: Vector2(200, 200),
            ),
          ],
          stepTime: 0.3,
          loop: true,
        );
    }
  }

  SpriteAnimation idleAnimation(PlayerVerticalPosition type) {
    if (!_supportedSpritesId.contains(profile.spriteId)) {
      return SpriteAnimation.spriteList(
        [
          Sprite(
            game.images.fromCache("gronouy/${profile.spriteId}.png"),
            srcSize: Vector2(200, 200),
          ),
        ],
        stepTime: double.infinity,
        loop: false,
      );
    }
    switch (type) {
      case PlayerVerticalPosition.land:
        return SpriteAnimation.spriteList(
          [
            Sprite(
              game.images.fromCache(
                'gronouy/${profile.spriteId}/$_idleLandName',
              ),
              srcSize: Vector2(200, 200),
            ),
          ],
          stepTime: 1,
          loop: true,
        );
      case PlayerVerticalPosition.waterLevel:
      case PlayerVerticalPosition.underwater:
        return SpriteAnimation.spriteList(
          [
            Sprite(
              game.images.fromCache(
                'gronouy/${profile.spriteId}/$_idleWaterName',
              ),
              srcSize: Vector2(200, 200),
            ),
          ],
          stepTime: 1,
          loop: true,
        );
    }
  }
}
