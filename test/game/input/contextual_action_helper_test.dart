import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/core/entities/player_vertical_position.dart';
import 'package:game_jam/game/input/contextual_action_helper.dart';

void main() {
  test('jump is allowed at water level and underwater only', () {
    expect(
      ContextualActionHelper.canJump(PlayerVerticalPosition.land),
      isFalse,
    );
    expect(
      ContextualActionHelper.canJump(PlayerVerticalPosition.waterLevel),
      isTrue,
    );
    expect(
      ContextualActionHelper.canJump(PlayerVerticalPosition.underwater),
      isTrue,
    );
  });

  test('dive is allowed at water level only', () {
    expect(
      ContextualActionHelper.canDive(PlayerVerticalPosition.land),
      isFalse,
    );
    expect(
      ContextualActionHelper.canDive(PlayerVerticalPosition.waterLevel),
      isTrue,
    );
    expect(
      ContextualActionHelper.canDive(PlayerVerticalPosition.underwater),
      isFalse,
    );
  });

  test('lick is blocked underwater only', () {
    expect(ContextualActionHelper.canLick(PlayerVerticalPosition.land), isTrue);
    expect(
      ContextualActionHelper.canLick(PlayerVerticalPosition.waterLevel),
      isTrue,
    );
    expect(
      ContextualActionHelper.canLick(PlayerVerticalPosition.underwater),
      isFalse,
    );
  });

  test('pause stays available at every vertical position', () {
    expect(
      ContextualActionHelper.canPause(PlayerVerticalPosition.land),
      isTrue,
    );
    expect(
      ContextualActionHelper.canPause(PlayerVerticalPosition.waterLevel),
      isTrue,
    );
    expect(
      ContextualActionHelper.canPause(PlayerVerticalPosition.underwater),
      isTrue,
    );
  });
}
