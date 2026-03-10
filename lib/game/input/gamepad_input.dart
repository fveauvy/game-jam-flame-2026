import 'dart:async';

import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:game_jam/core/config/gamepad_bindings.dart';
import 'package:game_jam/core/config/gameplay_tuning.dart';
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
  Timer? _controllerPollingTimer;

  /// Initialize gamepad listening.
  Future<void> initialize() async {
    if (_disposed) return;

    // For web, gamepads require user interaction first (security restriction)
    // Listen for events which will trigger gamepad availability on first interaction
    _gamepadSubscription = Gamepads.events.listen(_handleGamepadEvent);

    // Also try immediately in case gamepads are already connected
    await _checkForGamepads();
    _controllerPollingTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(_checkForGamepads()),
    );
  }

  Future<void> _checkForGamepads() async {
    if (_disposed) return;

    final controllers = await Gamepads.list();
    if (controllers.isNotEmpty && !_disposed && _currentController == null) {
      debugPrint(
        'Gamepad connected: ${controllers.map((c) => c.name).join(", ")}',
      );
      _currentController = controllers[0];
      return;
    }

    if (controllers.isEmpty && _currentController != null) {
      await _currentController!.dispose();
      _currentController = null;
      setMoveAxis(0, 0);
    }
  }

  Future<void> notifyUserGesture() async {
    await _checkForGamepads();
  }

  Future<void> _handleGamepadEvent(GamepadEvent event) async {
    if (_disposed) return;

    try {
      // Ensure we have a controller reference
      if (_currentController == null) {
        await _checkForGamepads();
      }

      bool axisMoved = false;
      _debugLog('gamepad input: ${event.type} - ${event.key} : ${event.value}');
      final buttonPressed = GamepadButton.getFromString(event.key);
      switch (buttonPressed) {
        case GamepadButton.leftStickXAxis:
        case GamepadButton.rightStickXAxis:
        case GamepadButton.dpadXAxis:
          moveAxis.x = event.value;
          axisMoved = true;
          break;
        case GamepadButton.leftStickYAxis:
        case GamepadButton.rightStickYAxis:
        case GamepadButton.dpadYAxis:
          moveAxis.y = event.value;
          axisMoved = true;
          break;
        case GamepadButton.southButton:
          if (event.value == GameplayTuning.gamepadButtonPressedValue) {
            confirm();
            moveUpLayer();
          }
          break;
        case GamepadButton.eastButton:
          if (event.value == GameplayTuning.gamepadButtonPressedValue) {
            moveDownLayer();
          }
          break;
        case GamepadButton.dpadLeft:
          moveAxis.x = -event.value;
          axisMoved = true;
          break;
        case GamepadButton.dpadRight:
          moveAxis.x = event.value;
          axisMoved = true;
          break;
        case GamepadButton.dpadUp:
          moveAxis.y = -event.value;
          axisMoved = true;
          break;
        case GamepadButton.dpadDown:
          moveAxis.y = event.value;
          axisMoved = true;
          break;
        case GamepadButton.startButton:
          pause();
          break;
        case GamepadButton.northButton:
        case GamepadButton.westButton:
        case GamepadButton.selectButton:
        case GamepadButton.shareButton:
        case GamepadButton.homeButton:
        case GamepadButton.leftTrigger:
        case GamepadButton.rightTrigger:
        case GamepadButton.leftBumper:
        case GamepadButton.rightBumper:
        case GamepadButton.leftStickClick:
        case GamepadButton.rightStickClick:
        case GamepadButton.touchPadXAxis:
        case GamepadButton.touchPadYAxis:
          break;
        case null:
          _debugLog(
            'Unknown gamepad input: ${event.key}, value: ${event.value}',
          );
          break;
      }

      if (axisMoved) {
        // Invert Y axis for macos
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
          moveAxis.y = -moveAxis.y;
        }
        setMoveAxis(moveAxis.x, moveAxis.y);
      }
    } catch (error) {
      _debugLog('Ignored unsupported gamepad event ${event.key}: $error');
    }
  }

  void _debugLog(String message) {
    if (!GameplayTuning.gamepadDebugLogs) {
      return;
    }
    debugPrint(message);
  }

  /// Stop listening to gamepad events.
  Future<void> dispose() async {
    _disposed = true;
    if (_gamepadSubscription != null) {
      await _gamepadSubscription!.cancel();
      _gamepadSubscription = null;
    }
    _controllerPollingTimer?.cancel();
    _controllerPollingTimer = null;
    if (_currentController != null) {
      await _currentController!.dispose();
      _currentController = null;
    }
  }
}
