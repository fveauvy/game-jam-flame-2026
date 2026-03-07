import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Make sure this is imported at the top
import 'package:game_jam/game/character/model/character_debug_state.dart';
class MenuScreen extends StatelessWidget {
  const MenuScreen({
    super.key,
    required this.onStart,
    required this.onReroll,
    required this.debugState,
  });

  final VoidCallback onStart;
  final VoidCallback onReroll;
  final CharacterDebugState? debugState;

  @override
  Widget build(BuildContext context) {
    String seed = debugState?.seedCode ?? '-';
    final controller = TextEditingController(text: seed);

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFF14213D)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'GRONOUŸ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  // Seed input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 170,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/plank.png'),
                            fit: BoxFit
                                .fill, // Ensures the plank stretches to fill the container
                          ),
                        ),
                        child: TextField(
                          maxLength: 5,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]'),
                            ),
                            UpperCaseTextFormatter(),
                          ],
                          buildCounter:
                              (
                                ctx, {
                                required int currentLength,
                                required bool isFocused,
                                maxLength,
                              }) => null,
                          controller: controller,
                          onChanged: (value) => {
                            if (value.length == 5)
                              {
                                debugPrint(
                                  'Seed submitted: ${controller.text}',
                                ),
                                seed = controller.text,
                              },
                          },
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 6,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder
                                .none, // Remove default TextField border
                            isDense: true, // Reduce height of the TextField
                            contentPadding:
                                EdgeInsets.zero, // Remove default padding
                            hintStyle: TextStyle(letterSpacing: 1.5),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white70),
                        iconSize: 20,
                        splashColor:
                            Colors.transparent, // Keeps it clean looking
                        highlightColor: Colors.transparent,
                        onPressed: () {
                          controller.clear(); // Clears the text field visually
                          debugPrint('Seed reset');
                          onReroll();
                          // If you need to trigger a game event, do it here!
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  _CharacterDebugPanel(debugState: debugState),
                  const SizedBox(height: 12),

                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onStart,
                    child: const Text('Start Game'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Move: WASD/Arrows  Jump: Space  Pause: Esc',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterDebugPanel extends StatelessWidget {
  const _CharacterDebugPanel({required this.debugState});

  final CharacterDebugState? debugState;

  @override
  Widget build(BuildContext context) {
    final CharacterDebugState? state = debugState;
    final String name = state?.profile.name.display ?? '-';
    final String color = state == null
        ? '-'
        : '${state.profile.colorId} ${state.profile.colorHex}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          spacing: 6,
          children: [
            _DebugRow(label: 'Name', value: name),
            _DebugRow(label: 'Color', value: color),
          ],
        ),
      ),
    );
  }
}

class _DebugRow extends StatelessWidget {
  const _DebugRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(label, style: const TextStyle(color: Colors.white60)),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}


class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection, // Keeps the cursor in the correct position
    );
  }
}
