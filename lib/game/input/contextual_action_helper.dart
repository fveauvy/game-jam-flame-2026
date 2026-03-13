import 'package:game_jam/core/entities/player_vertical_position.dart';

abstract final class ContextualActionHelper {
  static bool canJump(PlayerVerticalPosition level) {
    return level == PlayerVerticalPosition.waterLevel ||
        level == PlayerVerticalPosition.underwater;
  }

  static bool canDive(PlayerVerticalPosition level) {
    return level == PlayerVerticalPosition.waterLevel;
  }

  static bool canLick(PlayerVerticalPosition level) {
    return level != PlayerVerticalPosition.underwater;
  }

  static bool canPause(PlayerVerticalPosition level) {
    return level == PlayerVerticalPosition.land ||
        level == PlayerVerticalPosition.waterLevel ||
        level == PlayerVerticalPosition.underwater;
  }
}
