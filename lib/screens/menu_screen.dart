import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_jam/game/character/model/character_generation_state.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({
    super.key,
    required this.inputController,
    required this.onInputChange,
    required this.viewPortSize,
    required this.generationState,
    required this.onReroll,
    required this.onStart,
  });

  final TextEditingController inputController;
  final void Function(String)? onInputChange;
  final CharacterGenerationState? generationState;
  final VoidCallback onReroll;
  final VoidCallback onStart;
  final Vector2 viewPortSize;

  Widget build(BuildContext context) {
    final menuWidth = viewPortSize.x * 0.4;
    final menuHeight = viewPortSize.y * 0.4;

    return Center(
      child: SizedBox(
        width: menuWidth,
        height: menuHeight,
        child: ColoredBox(
          color: const Color.fromARGB(150, 255, 255, 255),
          child: Flex(
            direction: Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'GRONOUŸ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),

              // Seed input
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: menuWidth,
                    height: menuHeight,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/plank.png'),
                        fit: BoxFit.scaleDown,
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
                      controller: inputController,
                      onChanged: onInputChange,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 6,
                      ),
                      decoration: const InputDecoration(
                        border:
                            InputBorder.none, // Remove default TextField border
                        isDense: true, // Reduce height of the TextField
                        contentPadding:
                            EdgeInsets.zero, // Remove default padding
                        hintStyle: TextStyle(letterSpacing: 1.5),
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),

                    splashColor: Colors.transparent, // Keeps it clean looking
                    highlightColor: Colors.transparent,
                    onPressed: () {
                      inputController.clear(); // Clears the text field visually
                      debugPrint('Seed reset');
                      onReroll();
                      // If you need to trigger a game event, do it here!
                    },
                  ),
                ],
              ),
              const Text(
                'Move: WASD/Arrows  Jump: Space  Pause: Esc',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterDetailsPanel extends StatelessWidget {
  const _CharacterDetailsPanel({required this.generationState});

  final CharacterGenerationState? generationState;

  @override
  Widget build(BuildContext context) {
    final CharacterGenerationState? state = generationState;
    final String name = state?.profile.name.display ?? '-';
    final String sprite = state?.profile.spriteId ?? '-';

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
            _DetailRow(label: 'Name', value: name),
            _DetailRow(label: 'Sprite', value: sprite),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

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
