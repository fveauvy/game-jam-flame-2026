import 'package:game_jam/core/entities/player_type.dart';

class InputState {
  double moveAxisX = 0;
  double moveAxisY = 0;
  PlayerType playerType = PlayerType.middle; // position of player in the world, determines what they can interact with

  bool jumpPressed = false;
  bool attackPressed = false;
  bool pausePressed = false;
  bool confirmPressed = false;

  void goAbove() {
    playerType = playerType.above;
  }

  void goBellow() {
    playerType = playerType.bellow;
  }
  
  void queueJump() {
    jumpPressed = true;
  }

  void queueAttack() {
    attackPressed = true;
  }

  void queuePause() {
    pausePressed = true;
  }

  void queueConfirm() {
    confirmPressed = true;
  }

  void clearTransient() {
    jumpPressed = false;
    attackPressed = false;
    pausePressed = false;
    confirmPressed = false;
  }
}
