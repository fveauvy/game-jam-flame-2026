import 'package:flame/components.dart';
import 'package:game_jam/core/entities/player_vertical_position.dart';
import 'package:game_jam/game/components/player/player_component.dart';

extension PlayerAnimationExtension on PlayerComponent {
  static const List<String> supportedSpritesId = ['14'];

  static const String _jump1Name = 'Saut_1.png';
  static const String _jump2Name = 'Saut_2.png';

  static const String _idleLandName = 'ChillTerre.png';
  static const String _idleWaterName = 'ChillEau.png';

  static const String _swim1Name = 'Nage1eau.png';
  static const String _swim2Name = 'Nage2eau.png';

  SpriteAnimation moveAnimation(PlayerVerticalPosition type) {
    if (!supportedSpritesId.contains(profile.spriteId)) {
      return SpriteAnimation.spriteList(
        [Sprite(game.images.fromCache("gronouy/${profile.spriteId}.png"))],
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
            ),
            Sprite(
              game.images.fromCache('gronouy/${profile.spriteId}/$_jump2Name'),
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
            ),
            Sprite(
              game.images.fromCache('gronouy/${profile.spriteId}/$_swim2Name'),
            ),
          ],
          stepTime: 0.3,
          loop: true,
        );
    }
  }

  SpriteAnimation idleAnimation(PlayerVerticalPosition type) {
    if (!supportedSpritesId.contains(profile.spriteId)) {
      return SpriteAnimation.spriteList(
        [Sprite(game.images.fromCache("gronouy/${profile.spriteId}.png"))],
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
            ),
          ],
          stepTime: 1,
          loop: true,
        );
    }
  }
}
