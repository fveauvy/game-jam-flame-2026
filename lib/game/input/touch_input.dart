import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:game_jam/core/config/ui_config.dart';
import 'package:game_jam/game/input/input_state.dart';
import 'package:game_jam/game/input/touch_controller.dart';
import 'package:game_jam/game/input/visual_joystick.dart';

class TouchInputOverlay extends StatelessWidget {
  const TouchInputOverlay({
    super.key,
    required this.input,
    required this.touchController,
    required this.aspectRatio,
  });

  final InputState input;
  final TouchController touchController;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Center(
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,

                  children: [
                    Align(
                      alignment: Alignment.topCenter,

                      child: Padding(
                        padding: EdgeInsets.only(
                          top: constraints.maxHeight * 0.25,
                        ),
                        child: _TapButton(
                          icon: Icons.pause,
                          onTap: () => touchController.onPause(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: VisualJoystick(
                        onVectorChanged: (vector) {
                          touchController.updateJoystick(vector.x, vector.y);
                        },
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Expanded(child: SizedBox.shrink()),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CardinalButtons(
                            north: const SizedBox(
                              width: 72,
                              height: 72,
                            ), // Placeholder for spacing
                            west: _TapButton(
                              icon: Icons.flash_on,
                              onTap: touchController.attack,
                            ),
                            east: _TapButton(
                              icon: Icons.arrow_upward,
                              onTap: touchController.moveUpLayer,
                            ),
                            south: _HoldButton(
                              icon: Icons.arrow_downward,
                              onPressStart: touchController.moveDownLayer,
                              onPressEnd: touchController.moveUpLayer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class CardinalButtons extends StatelessWidget {
  const CardinalButtons({
    super.key,
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  final Widget north;
  final Widget south;
  final Widget east;
  final Widget west;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Row(
        spacing: 12,
        children: [
          Column(
            spacing: 12,
            children: [
              const SizedBox(width: 72, height: 72),
              Transform.rotate(angle: -math.pi / 4, child: west),
            ],
          ),
          Column(
            spacing: 12,
            children: [
              Transform.rotate(angle: -math.pi / 4, child: east),
              Transform.rotate(angle: -math.pi / 4, child: south),
            ],
          ),
        ],
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: HotkeyOverlayUi.panelBackground,
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(
            color: HotkeyOverlayUi.keyBorder,
            width: HotkeyOverlayUi.panelBorderWidth,
          ),
        ),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Icon(icon, color: HotkeyOverlayUi.keyTextColor),
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
              ? HotkeyOverlayUi.panelBackground.withValues(alpha: 0.55)
              : HotkeyOverlayUi.panelBackground,
          shape: BoxShape.circle,
          border: const Border.fromBorderSide(
            BorderSide(
              color: HotkeyOverlayUi.keyBorder,
              width: HotkeyOverlayUi.panelBorderWidth,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(widget.icon, color: HotkeyOverlayUi.keyTextColor),
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
