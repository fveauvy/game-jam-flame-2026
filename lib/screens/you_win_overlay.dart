import 'package:flutter/material.dart';
import 'package:game_jam/core/config/asset_paths.dart';

class YouWinOverlay extends StatefulWidget {
  final VoidCallback onRestart;
  final String winningTime;
  final Future<bool> Function(String playerName) onPublishScore;

  const YouWinOverlay({
    super.key,
    required this.onRestart,
    required this.winningTime,
    required this.onPublishScore,
  });

  @override
  State<YouWinOverlay> createState() => _YouWinOverlayState();
}

class _YouWinOverlayState extends State<YouWinOverlay> {
  bool _isPublishing = false;
  bool _hasPublishedScore = false;

  Future<void> _publishScore() async {
    if (_hasPublishedScore) {
      final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
        context,
      );
      messenger?.showSnackBar(
        const SnackBar(content: Text('Score already published for this run.')),
      );
      return;
    }

    final String? playerName = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text('Publish Score'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Player name',
              hintText: 'Enter your name',
            ),
            onSubmitted: (String value) {
              final String normalized = value.trim();
              Navigator.of(
                dialogContext,
              ).pop(normalized.isEmpty ? null : normalized);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final String normalized = controller.text.trim();
                Navigator.of(
                  dialogContext,
                ).pop(normalized.isEmpty ? null : normalized);
              },
              child: const Text('Publish'),
            ),
          ],
        );
      },
    );

    if (playerName == null || _isPublishing) {
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    final bool success = await widget.onPublishScore(playerName);
    if (!mounted) {
      return;
    }

    setState(() {
      _isPublishing = false;
      if (success) {
        _hasPublishedScore = true;
      }
    });

    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    messenger?.showSnackBar(
      SnackBar(
        content: Text(success ? 'Score published.' : 'Score publish failed.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 773 / 801,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(AssetPaths.uiTooltip),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 18,
                  children: [
                    const Text(
                      'The little brothers are safe.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2A170E),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 36),
                      child: Text(
                        'You brought every egg home before the marsh could take them.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF3B2418),
                          height: 1.35,
                        ),
                      ),
                    ),
                    Text(
                      'Rescue time: ${widget.winningTime}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A0C05),
                      ),
                    ),
                    FilledButton(
                      onPressed: (_isPublishing || _hasPublishedScore)
                          ? null
                          : _publishScore,
                      child: Text(
                        _isPublishing
                            ? 'Publishing...'
                            : (_hasPublishedScore
                                  ? 'Published'
                                  : 'Publish Score'),
                      ),
                    ),
                    FilledButton(
                      onPressed: widget.onRestart,
                      child: const Text('Play Again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
