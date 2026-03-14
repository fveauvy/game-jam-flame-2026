import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_jam/core/config/ui_config.dart';
import 'package:game_jam/game/character/infra/seed_code.dart';
import 'package:game_jam/screens/credits_overlay.dart';

class MenuSeedOverlay extends StatefulWidget {
  const MenuSeedOverlay({super.key, required this.onStartWithSeed});

  final Future<void> Function(String seedCode) onStartWithSeed;

  @override
  State<MenuSeedOverlay> createState() => _MenuSeedOverlayState();
}

class _MenuSeedOverlayState extends State<MenuSeedOverlay> {
  bool _isApplyingSeed = false;
  bool _showCredits = false;

  Future<void> _openSeedDialog() async {
    if (_isApplyingSeed) {
      return;
    }
    final String? seedCode = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text(WinOverlayUi.seedDialogTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            maxLength: MenuUi.seedCodeLength,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(
                RegExp(WinOverlayUi.seedAllowedCharactersPattern),
              ),
              _UpperCaseTextFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: WinOverlayUi.seedLabel,
              hintText: WinOverlayUi.seedHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(WinOverlayUi.cancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text(WinOverlayUi.startAction),
            ),
          ],
        );
      },
    );
    if (!mounted || seedCode == null) {
      return;
    }

    final String normalized = seedCode.trim();
    if (normalized.length != MenuUi.seedCodeLength) {
      final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
        context,
      );
      messenger?.showSnackBar(
        const SnackBar(content: Text(WinOverlayUi.seedLengthError)),
      );
      return;
    }
    if (!SeedCode.isValid(normalized)) {
      final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
        context,
      );
      messenger?.showSnackBar(
        const SnackBar(content: Text(WinOverlayUi.seedInvalidError)),
      );
      return;
    }

    setState(() {
      _isApplyingSeed = true;
    });
    try {
      await widget.onStartWithSeed(normalized);
    } catch (_) {
      if (mounted) {
        final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
          context,
        );
        messenger?.showSnackBar(
          const SnackBar(content: Text(WinOverlayUi.seedInvalidError)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingSeed = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  FilledButton(
                    onPressed: _isApplyingSeed ? null : _openSeedDialog,
                    child: Text(
                      _isApplyingSeed
                          ? WinOverlayUi.restartingLabel
                          : WinOverlayUi.startWithSeedAction,
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => setState(() => _showCredits = true),
                    child: const Text('Credits'),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_showCredits)
          CreditsOverlay(onClose: () => setState(() => _showCredits = false)),
      ],
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
