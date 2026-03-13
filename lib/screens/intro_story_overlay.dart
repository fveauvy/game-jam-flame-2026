import 'package:flutter/material.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/core/config/ui_config.dart';

class IntroStoryOverlay extends StatelessWidget {
  const IntroStoryOverlay({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(
        alpha: IntroStoryUi.overlayBackgroundAlpha,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AssetPaths.splashScreen,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      IntroStoryUi.fallbackGradientTop,
                      IntroStoryUi.fallbackGradientBottom,
                    ],
                  ),
                ),
              );
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.black.withValues(
                    alpha: IntroStoryUi.imageOverlayTopAlpha,
                  ),
                  Colors.black.withValues(
                    alpha: IntroStoryUi.imageOverlayBottomAlpha,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: IntroStoryUi.cardMaxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(IntroStoryUi.cardOuterPadding),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: IntroStoryUi.cardBackground,
                      borderRadius: BorderRadius.circular(
                        IntroStoryUi.cardRadius,
                      ),
                      border: Border.all(color: IntroStoryUi.cardBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        IntroStoryUi.cardInnerPaddingHorizontal,
                        IntroStoryUi.cardInnerPaddingVertical,
                        IntroStoryUi.cardInnerPaddingHorizontal,
                        IntroStoryUi.cardInnerPaddingVertical,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            IntroStoryUi.title,
                            style: TextStyle(
                              color: IntroStoryUi.titleColor,
                              fontSize: IntroStoryUi.titleFontSize,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(
                            height: IntroStoryUi.titleBottomSpacing,
                          ),
                          const Text(
                            IntroStoryUi.story,
                            style: TextStyle(
                              color: IntroStoryUi.bodyColor,
                              fontSize: IntroStoryUi.storyFontSize,
                              height: IntroStoryUi.storyLineHeight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(
                            height: IntroStoryUi.actionsTopSpacing,
                          ),
                          Row(
                            children: [
                              FilledButton(
                                onPressed: onContinue,
                                child: const Text(IntroStoryUi.continueLabel),
                              ),
                              const SizedBox(
                                width: IntroStoryUi.actionHintLeftSpacing,
                              ),
                              const Text(
                                IntroStoryUi.continueHint,
                                style: TextStyle(
                                  color: IntroStoryUi.actionHintColor,
                                  fontSize: IntroStoryUi.actionHintFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
