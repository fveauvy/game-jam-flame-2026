class InputState {
  double moveAxisX = 0;
  double moveAxisY = 0;
  bool jumpPressed = false;
  bool attackPressed = false;
  bool pausePressed = false;
  bool confirmPressed = false;

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
