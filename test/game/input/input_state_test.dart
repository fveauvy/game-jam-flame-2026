import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/core/entities/player_vertical_position.dart';
import 'package:game_jam/game/input/input_state.dart';

void main() {
  test('clearPausePressed only resets pause flag', () {
    final InputState inputState = InputState();
    inputState.queuePause();
    inputState.queueAttack();
    inputState.queueConfirm();
    inputState.queueJump();

    inputState.clearPausePressed();

    expect(inputState.pausePressed, isFalse);
    expect(inputState.attackPressed, isTrue);
    expect(inputState.confirmPressed, isTrue);
    expect(inputState.jumpPressed, isTrue);
  });

  test('defaults to land vertical position', () {
    final InputState inputState = InputState();

    expect(inputState.playerVerticalPosition, PlayerVerticalPosition.land);
  });

  test('clearTransient resets jump and dive flags', () {
    final InputState inputState = InputState();
    inputState.queueJump();
    inputState.queueDive();

    inputState.clearTransient();

    expect(inputState.jumpPressed, isFalse);
    expect(inputState.divePressed, isFalse);
  });
}
