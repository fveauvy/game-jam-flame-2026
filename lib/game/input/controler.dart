import 'package:game_jam/game/input/input_state.dart';

/// Abstract base class for all input controllers (keyboard, touch, gamepad, etc.)
/// Handles common movement logic (axes and layer changes).
/// Subclasses implement specific input methods (keyboard, touch, gamepad).
abstract class Controller {
  final InputState state;
  Controller(this.state);

  /// Protected helper to update movement axes in the input state.
  void setMoveAxis(double x, double y) {
    state.moveAxisX = x;
    state.moveAxisY = y;
  }

  /// Protected helper to request a jump.
  void moveUpLayer() {
    state.queueJump();
  }

  /// Protected helper to request a dive.
  void moveDownLayer() {
    state.queueDive();
  }

  void pause() {
    state.queuePause();
  }

  void confirm() {
    state.queueConfirm();
  }

  void attack() {
    state.queueAttack();
  }
}
