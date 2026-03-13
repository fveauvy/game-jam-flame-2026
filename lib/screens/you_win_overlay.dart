import 'package:flutter/material.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/core/config/ui_config.dart';

class YouWinOverlay extends StatefulWidget {
  final Future<void> Function() onRetrySeed;
  final Future<void> Function() onRestartWithNewSeed;
  final String winningTime;
  final Future<bool> Function(String playerName) onPublishScore;

  const YouWinOverlay({
    super.key,
    required this.onRetrySeed,
    required this.onRestartWithNewSeed,
    required this.winningTime,
    required this.onPublishScore,
  });

  @override
  State<YouWinOverlay> createState() => _YouWinOverlayState();
}

class _YouWinOverlayState extends State<YouWinOverlay> {
  bool _isPublishing = false;
  bool _hasPublishedScore = false;
  bool _isRestarting = false;

  Future<void> _publishScore() async {
    if (_hasPublishedScore) {
      final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
        context,
      );
      messenger?.showSnackBar(
        const SnackBar(content: Text(WinOverlayUi.duplicatePublishMessage)),
      );
      return;
    }

    final String? playerName = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text(WinOverlayUi.publishDialogTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: WinOverlayUi.publishNameLabel,
              hintText: WinOverlayUi.publishNameHint,
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
              child: const Text(WinOverlayUi.cancelAction),
            ),
            FilledButton(
              onPressed: () {
                final String normalized = controller.text.trim();
                Navigator.of(
                  dialogContext,
                ).pop(normalized.isEmpty ? null : normalized);
              },
              child: const Text(WinOverlayUi.publishAction),
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
        content: Text(
          success
              ? WinOverlayUi.publishSuccessMessage
              : WinOverlayUi.publishFailMessage,
        ),
      ),
    );
  }

  Future<void> _runRestart(Future<void> Function() action) async {
    if (_isRestarting) {
      return;
    }
    setState(() {
      _isRestarting = true;
    });
    await action();
    if (!mounted) {
      return;
    }
    setState(() {
      _isRestarting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(
        alpha: WinOverlayUi.overlayBackgroundAlpha,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: WinOverlayUi.maxWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(WinOverlayUi.cardRadius),
            child: AspectRatio(
              aspectRatio: WinOverlayUi.cardAspectRatio,
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
                  spacing: WinOverlayUi.contentSpacing,
                  children: [
                    const Text(
                      WinOverlayUi.victoryTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: WinOverlayUi.titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: WinOverlayUi.titleColor,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: WinOverlayUi.summaryHorizontalPadding,
                      ),
                      child: Text(
                        WinOverlayUi.victorySummary,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: WinOverlayUi.summaryFontSize,
                          fontWeight: FontWeight.w500,
                          color: WinOverlayUi.summaryColor,
                          height: WinOverlayUi.summaryLineHeight,
                        ),
                      ),
                    ),
                    Text(
                      '${WinOverlayUi.rescueTimePrefix} ${widget.winningTime}',
                      style: const TextStyle(
                        fontSize: WinOverlayUi.rescueTimeFontSize,
                        fontWeight: FontWeight.w700,
                        color: WinOverlayUi.rescueTimeColor,
                      ),
                    ),
                    FilledButton(
                      onPressed: (_isPublishing || _hasPublishedScore)
                          ? null
                          : _publishScore,
                      child: Text(
                        _isPublishing
                            ? WinOverlayUi.publishingLabel
                            : (_hasPublishedScore
                                  ? WinOverlayUi.publishedLabel
                                  : WinOverlayUi.publishAction),
                      ),
                    ),
                    FilledButton(
                      onPressed: _isRestarting
                          ? null
                          : () => _runRestart(widget.onRetrySeed),
                      child: Text(
                        _isRestarting
                            ? WinOverlayUi.restartingLabel
                            : WinOverlayUi.retrySeedAction,
                      ),
                    ),
                    FilledButton(
                      onPressed: _isRestarting
                          ? null
                          : () => _runRestart(widget.onRestartWithNewSeed),
                      child: const Text(WinOverlayUi.restartNewSeedAction),
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
