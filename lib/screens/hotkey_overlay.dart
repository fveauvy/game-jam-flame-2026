import 'package:flutter/material.dart';
import 'package:game_jam/core/config/ui_config.dart';

class HotkeyOverlay extends StatelessWidget {
  const HotkeyOverlay({super.key, required this.isGamepadConnected});

  final bool isGamepadConnected;

  @override
  Widget build(BuildContext context) {
    final List<_HotkeyRow> rows = isGamepadConnected
        ? const <_HotkeyRow>[
            _HotkeyRow(Icons.gamepad, 'Movement', <String>[
              'Left Stick',
              'D-Pad',
            ]),
            _HotkeyRow(Icons.keyboard_arrow_up, 'Jump', <String>['A']),
            _HotkeyRow(Icons.keyboard_arrow_down, 'Dive', <String>['B']),
            _HotkeyRow(Icons.flash_on, 'Lick', <String>['X', 'Y']),
            _HotkeyRow(Icons.pause, 'Pause', <String>['Start']),
          ]
        : const <_HotkeyRow>[
            _HotkeyRow(Icons.open_with, 'Movement', <String>['WASD', 'Arrows']),
            _HotkeyRow(Icons.keyboard_arrow_up, 'Jump', <String>['Space']),
            _HotkeyRow(Icons.keyboard_arrow_down, 'Dive', <String>['Shift']),
            _HotkeyRow(Icons.flash_on, 'Lick', <String>['J']),
            _HotkeyRow(Icons.pause, 'Pause', <String>['Esc']),
          ];

    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(
              right: HotkeyOverlayUi.panelRight,
              bottom: HotkeyOverlayUi.panelBottom,
            ),
            child: Container(
              width: HotkeyOverlayUi.panelWidth,
              padding: const EdgeInsets.all(HotkeyOverlayUi.panelPadding),
              decoration: BoxDecoration(
                color: HotkeyOverlayUi.panelBackground,
                borderRadius: BorderRadius.circular(
                  HotkeyOverlayUi.panelRadius,
                ),
                border: Border.all(
                  color: HotkeyOverlayUi.panelBorder,
                  width: HotkeyOverlayUi.panelBorderWidth,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isGamepadConnected
                            ? Icons.sports_esports
                            : Icons.keyboard,
                        size: HotkeyOverlayUi.iconSize,
                        color: HotkeyOverlayUi.titleColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isGamepadConnected
                            ? HotkeyOverlayUi.gamepadTitle
                            : HotkeyOverlayUi.keyboardTitle,
                        style: const TextStyle(
                          color: HotkeyOverlayUi.titleColor,
                          fontSize: HotkeyOverlayUi.titleFontSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: HotkeyOverlayUi.panelSectionGap),
                  for (final _HotkeyRow row in rows) ...[
                    _HotkeyRowWidget(row: row),
                    const SizedBox(height: HotkeyOverlayUi.panelRowGap),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HotkeyRow {
  const _HotkeyRow(this.icon, this.label, this.keys);

  final IconData icon;
  final String label;
  final List<String> keys;
}

class _HotkeyRowWidget extends StatelessWidget {
  const _HotkeyRowWidget({required this.row});

  final _HotkeyRow row;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          row.icon,
          size: HotkeyOverlayUi.iconSize,
          color: HotkeyOverlayUi.labelColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            row.label,
            style: const TextStyle(
              color: HotkeyOverlayUi.labelColor,
              fontSize: HotkeyOverlayUi.labelFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Wrap(
          spacing: HotkeyOverlayUi.keyGap,
          children: row.keys.map(_buildKey).toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildKey(String key) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: HotkeyOverlayUi.keyHorizontalPadding,
        vertical: HotkeyOverlayUi.keyVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: HotkeyOverlayUi.keyBackground,
        borderRadius: BorderRadius.circular(HotkeyOverlayUi.keyRadius),
        border: Border.all(color: HotkeyOverlayUi.keyBorder),
      ),
      child: Text(
        key,
        style: const TextStyle(
          color: HotkeyOverlayUi.keyTextColor,
          fontSize: HotkeyOverlayUi.keyFontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
