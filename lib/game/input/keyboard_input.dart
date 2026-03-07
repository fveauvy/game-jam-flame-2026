import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:game_jam/game/input/controler.dart';

class KeyboardInput extends Controller {
  KeyboardInput(super.state);

  final Set<LogicalKeyboardKey> _held = <LogicalKeyboardKey>{};

  KeyEventResult handleEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      _held.add(event.logicalKey);
      _queueActions(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _held.remove(event.logicalKey);
    }

    setMoveAxis(_horizontalAxis(), _verticalAxis());
    return KeyEventResult.handled;
  }

  void _queueActions(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.space) {
      moveUpLayer();
    } else if (key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      moveDownLayer();
    } else if (key == LogicalKeyboardKey.escape) {
      pause();
    } else if (key == LogicalKeyboardKey.enter) {
      confirm();
    } else if (key == LogicalKeyboardKey.keyJ) {
      attack();
    }
  }

  double _verticalAxis() {
    final bool up =
        _held.contains(LogicalKeyboardKey.arrowUp) ||
        _held.contains(LogicalKeyboardKey.keyW);
    final bool down =
        _held.contains(LogicalKeyboardKey.arrowDown) ||
        _held.contains(LogicalKeyboardKey.keyS);

    if (up && !down) {
      return -1;
    }
    if (down && !up) {
      return 1;
    }
    return 0;
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
