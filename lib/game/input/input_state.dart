import 'package:game_jam/core/entities/player_vertical_position.dart';

class InputState {
  double moveAxisX = 0;
  double moveAxisY = 0;
  PlayerVerticalPosition playerVerticalPosition = PlayerVerticalPosition.land;

  bool jumpPressed = false;
  bool divePressed = false;
  bool attackPressed = false;
  bool pausePressed = false;
  bool confirmPressed = false;

  void queueJump() {
    jumpPressed = true;
  }

  void queueDive() {
    divePressed = true;
  }

  void queueAttack() {
    attackPressed = true;
  }

  void queuePause() {
    pausePressed = true;
  }

  void clearPausePressed() {
    pausePressed = false;
  }

  void queueConfirm() {
    confirmPressed = true;
  }

  void clearTransient() {
    jumpPressed = false;
    divePressed = false;
    attackPressed = false;
    pausePressed = false;
    confirmPressed = false;
  }
}
