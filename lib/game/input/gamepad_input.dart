import 'dart:async';

import 'package:flame/extensions.dart';
import 'package:flutter/widgets.dart';
import 'package:game_jam/game/input/controler.dart';
import 'package:gamepads/gamepads.dart';

/// Controller for gamepad/game controller input.
/// Supports standard gamepads with analog sticks and buttons.
class GamepadInput extends Controller {
  GamepadInput(super.state);

  GamepadController? _currentController;
  bool _disposed = false;

  Vector2 moveAxis = Vector2.zero();

  StreamSubscription<GamepadEvent>? _gamepadSubscription;

  /// Initialize gamepad listening.

  /// Initialize gamepad listening.
  Future<void> initialize() async {
    if (_disposed) return;

    // Get list of connected gamepads and use the first one if available
    final controllers = await Gamepads.list();
    if (controllers.isNotEmpty && !_disposed) {
      debugPrint(
        'Gamepad connected: ${controllers.map((c) => c.name).join(", ")}',
      );
      _currentController = controllers[0];

      _gamepadSubscription = Gamepads.events.listen((event) {
        bool axisMoved = false;
        switch (event.key) {
          case "l.joystick - xAxis":
          case "r.joystick - xAxis":
            moveAxis.x = event.value;
            axisMoved = true;
            break;
          case "l.joystick - yAxis":
          case "r.joystick - yAxis":
            moveAxis.y =
                -event.value; // Invert Y axis for typical game controls
            axisMoved = true;
            break;
          case "a.circle":
            if (event.value == 1) {
              moveUpLayer();
            }
            break;
          case "b.circle":
            if (event.value == 1) {
              moveDownLayer();
            }
            break;
          default:
            debugPrint(
              'Unhandled gamepad input: ${event.type} - ${event.key} : ${event.value}',
            );
        }
        if (axisMoved) {
          setMoveAxis(moveAxis.x, moveAxis.y);
        }
      });
    }
  }

  /// Stop listening to gamepad events.
  Future<void> dispose() async {
    _disposed = true;
    if (_gamepadSubscription != null) {
      await _gamepadSubscription!.cancel();
      _gamepadSubscription = null;
    }
    if (_currentController != null) {
      await _currentController!.dispose();
      _currentController = null;
    }
  }
}
