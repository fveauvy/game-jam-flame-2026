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
  static const String _idleUnderwaterFrog14Name = 'Chillsousleau.png';

  static const String _swim1Name = 'Nage1.png';
  static const String _swim2Name = 'Nage2.png';
  static const String _swim1UnderwaterFrog14Name = 'Nage1sousleau.png';
  static const String _swim2UnderwaterFrog14Name = 'Nage2sousleau.png';

  bool get _isFrog14 => profile.spriteId == 'frog-14';

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
      case PlayerVerticalPosition.underwater:
        final String swim1 = _isFrog14
            ? _swim1UnderwaterFrog14Name
            : _swim1Name;
        final String swim2 = _isFrog14
            ? _swim2UnderwaterFrog14Name
            : _swim2Name;
        return SpriteAnimation.spriteList(
          [
            Sprite(
              game.images.fromCache('gronouy/${profile.spriteId}/$swim1'),
              srcSize: Vector2(200, 200),
            ),
            Sprite(
              game.images.fromCache('gronouy/${profile.spriteId}/$swim2'),
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
      case PlayerVerticalPosition.underwater:
        final String idleUnderwater = _isFrog14
            ? _idleUnderwaterFrog14Name
            : _idleWaterName;
        return SpriteAnimation.spriteList(
          [
            Sprite(
              game.images.fromCache(
                'gronouy/${profile.spriteId}/$idleUnderwater',
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
