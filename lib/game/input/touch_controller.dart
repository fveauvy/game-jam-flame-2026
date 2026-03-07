import 'package:game_jam/game/input/controler.dart';

/// Controller for touch-based input.
/// Handles virtual joystick and button input from the touch overlay.
class TouchController extends Controller {
  TouchController(super.state);

  /// Update movement axes from the virtual joystick.
  void updateJoystick(double x, double y) {
    setMoveAxis(x, y);
  }

  /// Handle up layer button press.
  void onUpLayerPressed() {
    moveUpLayer();
  }

  /// Handle down layer button press.
  void onDownLayerPressed() {
    moveDownLayer();
  }
}
