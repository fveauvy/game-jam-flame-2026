import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';

class VisualJoystick extends StatefulWidget {
  final void Function(Vector2) onVectorChanged;
  const VisualJoystick({super.key, required this.onVectorChanged});

  @override
  State<VisualJoystick> createState() => _VisualJoystickState();
}

class _VisualJoystickState extends State<VisualJoystick> {
  OverlayEntry? _joystickOverlayEntry;
  Offset _joystickBasePosition =
      Offset.zero; // Global position of the joystick's center
  Offset _currentHandleRelativePosition =
      Offset.zero; // Handle position relative to base center

  // Customizable joystick appearance properties
  final double _joystickRadius = 35; // Radius of the larger base circle
  final double _handleRadius = 20; // Radius of the smaller handle circle

  /// Called when the user first presses down on the screen.
  /// This creates and inserts the joystick overlay.
  void _onPanDown(DragDownDetails details) {
    // Store the initial global position as the joystick's base center
    _joystickBasePosition = details.globalPosition;
    _currentHandleRelativePosition = Offset.zero; // Handle starts at the center

    // Create a new OverlayEntry for the joystick
    _joystickOverlayEntry = OverlayEntry(
      builder: (context) {
        // Positioned widget places the CustomPaint widget correctly on the screen.
        // The top-left corner of the CustomPaint needs to be adjusted
        // so that the joystick's center is at _joystickBasePosition.
        return Positioned(
          left: _joystickBasePosition.dx - _joystickRadius,
          top: _joystickBasePosition.dy - _joystickRadius,
          child: CustomPaint(
            painter: JoystickPainter(
              joystickRadius: _joystickRadius,
              handleRadius: _handleRadius,
              handleOffset: _currentHandleRelativePosition,
            ),
            size: Size.square(
              _joystickRadius * 2,
            ), // The size of the square canvas for drawing
          ),
        );
      },
    );

    // Insert the overlay into the OverlayLayer
    Overlay.of(context).insert(_joystickOverlayEntry!);

    // Initialize the joystick value to zero
    widget.onVectorChanged(Vector2.zero());
  }

  /// Called as the user drags their finger across the screen.
  /// This updates the handle's position and calculates the new joystick value.
  void _onPanUpdate(DragUpdateDetails details) {
    if (_joystickOverlayEntry == null) return; // Joystick not active

    // Calculate the new handle position relative to the joystick's base center
    final Offset newHandleGlobalPosition = details.globalPosition;
    Offset newHandleRelativePosition =
        newHandleGlobalPosition - _joystickBasePosition;

    // Clamp the handle's position within the joystick's radius
    final double distance = newHandleRelativePosition.distance;
    if (distance > _joystickRadius) {
      // If the finger is outside the radius, keep the handle at the edge
      newHandleRelativePosition = Offset.fromDirection(
        newHandleRelativePosition.direction,
        _joystickRadius,
      );
    }

    // Update the state and trigger a rebuild of the overlay to draw the handle
    setState(() {
      _currentHandleRelativePosition = newHandleRelativePosition;
      _joystickOverlayEntry
          ?.markNeedsBuild(); // Tell the overlay to rebuild its child
    });

    // Calculate the normalized joystick value (-1 to 1 for both axes)
    // X and Y are normalized by the joystick's radius.
    widget.onVectorChanged(
      Vector2(
        _currentHandleRelativePosition.dx / _joystickRadius,
        _currentHandleRelativePosition.dy / _joystickRadius,
      ),
    );
  }

  /// Called when the user lifts their finger.
  /// This hides the joystick overlay.
  void _onPanEnd(DragEndDetails details) {
    _hideJoystick();
  }

  /// Called if the gesture is cancelled (e.g., by another gesture recognizer).
  /// This also hides the joystick overlay.
  void _onPanCancel() {
    _hideJoystick();
  }

  /// Removes the joystick overlay and resets its value.
  void _hideJoystick() {
    _joystickOverlayEntry?.remove();
    _joystickOverlayEntry = null;
    widget.onVectorChanged(
      Vector2.zero(),
    ); // Reset value when joystick is hidden
  }

  @override
  void dispose() {
    // Ensure the overlay is removed when the widget is disposed
    _joystickOverlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // GestureDetector covers the entire screen to capture gestures anywhere
      onPanDown: _onPanDown,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: _onPanCancel,
    );
  }
}

/// A CustomPainter that draws the joystick base and handle.
class JoystickPainter extends CustomPainter {
  final double joystickRadius;
  final double handleRadius;
  final Offset
  handleOffset; // Position of the handle relative to the joystick's center

  JoystickPainter({
    required this.joystickRadius,
    required this.handleRadius,
    required this.handleOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Paint for the joystick base
    final Paint basePaint = Paint()
      ..color = Colors.white30
      ..style = PaintingStyle.fill;

    // Paint for the joystick handle
    final Paint handlePaint = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.fill;

    // The center of the CustomPaint's canvas is the center of our joystick base.
    // The size of the canvas is (2 * joystickRadius) x (2 * joystickRadius).
    final Offset center = Offset(size.width / 2, size.height / 2);

    // Draw the joystick base circle
    canvas.drawCircle(center, joystickRadius, basePaint);

    // Draw the joystick handle circle
    // The handleOffset is added to the center because it's already relative
    // to the desired center point.
    canvas.drawCircle(center + handleOffset, handleRadius, handlePaint);
  }

  @override
  bool shouldRepaint(covariant JoystickPainter oldDelegate) {
    // Only repaint if the handle's position has changed
    return oldDelegate.handleOffset != handleOffset;
  }
}
