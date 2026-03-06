import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:game_jam/game/input/input_state.dart';

class KeyboardInput {
  final Set<LogicalKeyboardKey> _held = <LogicalKeyboardKey>{};

  KeyEventResult handleEvent(KeyEvent event, InputState input) {
    if (event is KeyDownEvent) {
      _held.add(event.logicalKey);
      _queueActions(event.logicalKey, input);
    } else if (event is KeyUpEvent) {
      _held.remove(event.logicalKey);
    }

    input.moveAxis = _horizontalAxis();
    return KeyEventResult.handled;
  }

  void _queueActions(LogicalKeyboardKey key, InputState input) {
    if (key == LogicalKeyboardKey.space) {
      input.queueJump();
    } else if (key == LogicalKeyboardKey.escape) {
      input.queuePause();
    } else if (key == LogicalKeyboardKey.enter) {
      input.queueConfirm();
    } else if (key == LogicalKeyboardKey.keyJ) {
      input.queueAttack();
    }
  }

  double _horizontalAxis() {
    final bool left =
        _held.contains(LogicalKeyboardKey.arrowLeft) ||
        _held.contains(LogicalKeyboardKey.keyA);
    final bool right =
        _held.contains(LogicalKeyboardKey.arrowRight) ||
        _held.contains(LogicalKeyboardKey.keyD);

    if (left && !right) {
      return -1;
    }
    if (right && !left) {
      return 1;
    }
    return 0;
  }
}
