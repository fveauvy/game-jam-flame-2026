import 'package:flutter/material.dart';
import 'package:game_jam/game/input/input_state.dart';

class TouchInputOverlay extends StatelessWidget {
  const TouchInputOverlay({super.key, required this.input});

  final InputState input;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  _HoldButton(
                    icon: Icons.arrow_drop_up,
                    onPressStart: () => input.moveAxisY = -1,
                    onPressEnd: () {
                      if (input.moveAxisY < 0) {
                        input.moveAxisY = 0;
                      }
                    },
                  ),
                  Row(
                    spacing: 12,
                    children: [
                      _HoldButton(
                        icon: Icons.arrow_left,
                        onPressStart: () => input.moveAxisX = -1,
                        onPressEnd: () {
                          if (input.moveAxisX < 0) {
                            input.moveAxisX = 0;
                          }
                        },
                      ),
                      _HoldButton(
                        icon: Icons.arrow_drop_down,
                        onPressStart: () => input.moveAxisY = 1,
                        onPressEnd: () {
                          if (input.moveAxisY > 0) {
                            input.moveAxisY = 0;
                          }
                        },
                      ),
                      _HoldButton(
                        icon: Icons.arrow_right,
                        onPressStart: () => input.moveAxisX = 1,
                        onPressEnd: () {
                          if (input.moveAxisX > 0) {
                            input.moveAxisX = 0;
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              _TapButton(icon: Icons.arrow_upward, onTap: input.queueJump),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapButton extends StatelessWidget {
  const _TapButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _HoldButton extends StatefulWidget {
  const _HoldButton({
    required this.icon,
    required this.onPressStart,
    required this.onPressEnd,
  });

  final IconData icon;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        if (_active) {
          return;
        }
        setState(() => _active = true);
        widget.onPressStart();
      },
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: _active
              ? Colors.black.withValues(alpha: 0.55)
              : Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(widget.icon, color: Colors.white),
      ),
    );
  }

  void _release() {
    if (!_active) {
      return;
    }
    setState(() => _active = false);
    widget.onPressEnd();
  }
}
