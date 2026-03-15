import 'package:flutter/material.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/core/config/ui_config.dart';

class YouWinOverlay extends StatefulWidget {
  final Future<void> Function() onReplay;
  final String winningTime;
  final Future<bool> Function(String playerName) onPublishScore;

  const YouWinOverlay({
    super.key,
    required this.onReplay,
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
      child: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxHeight < 600;
              final double spacing = compact ? 10 : WinOverlayUi.contentSpacing;
              final double titleSize = compact
                  ? 24
                  : WinOverlayUi.titleFontSize + 6;
              final double subtitleSize = compact
                  ? 20
                  : WinOverlayUi.titleFontSize;
              final double summarySize = compact
                  ? 14
                  : WinOverlayUi.summaryFontSize;
              final double timeSize = compact
                  ? 16
                  : WinOverlayUi.rescueTimeFontSize;
              final double hPad = compact
                  ? 20
                  : WinOverlayUi.summaryHorizontalPadding;

              final Widget content = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: spacing,
                children: [
                  Text(
                    WinOverlayUi.victoryExclamation,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      color: WinOverlayUi.titleColor,
                    ),
                  ),
                  Text(
                    WinOverlayUi.victoryTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w700,
                      color: WinOverlayUi.titleColor,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Text(
                      WinOverlayUi.victorySummary,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: summarySize,
                        fontWeight: FontWeight.w500,
                        color: WinOverlayUi.summaryColor,
                        height: WinOverlayUi.summaryLineHeight,
                      ),
                    ),
                  ),
                  Text(
                    '${WinOverlayUi.rescueTimePrefix} ${widget.winningTime}',
                    style: TextStyle(
                      fontSize: timeSize,
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
                        : () => _runRestart(widget.onReplay),
                    child: Text(
                      _isRestarting
                          ? WinOverlayUi.restartingLabel
                          : WinOverlayUi.replayAction,
                    ),
                  ),
                ],
              );

              return ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: WinOverlayUi.maxWidth,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(WinOverlayUi.cardRadius),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(AssetPaths.uiTooltip),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: compact
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            child: content,
                          )
                        : AspectRatio(
                            aspectRatio: WinOverlayUi.cardAspectRatio,
                            child: content,
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
