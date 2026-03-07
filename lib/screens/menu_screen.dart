import 'package:flutter/material.dart';
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
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF14213D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFCA311), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Flame Jam Template',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Web-first 2D starter with layered structure.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  _CharacterDebugPanel(debugState: debugState),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: onReroll,
                    child: const Text('Reroll Seed'),
                  ),
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
    final String seed = state?.seedCode ?? '-';
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
          children: [
            _DebugRow(label: 'Seed', value: seed),
            const SizedBox(height: 6),
            _DebugRow(label: 'Name', value: name),
            const SizedBox(height: 6),
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
