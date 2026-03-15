import 'dart:ui';

abstract final class UiTiming {
  // Startup and transition durations.
  static const Duration splashScreenDuration = Duration(milliseconds: 6000);
  static const Duration frogAnimationDuration = Duration(milliseconds: 140);
}

abstract final class MenuUi {
  // Menu overlay layout.
  static const double panelMaxWidth = 420;
  static const double panelPadding = 24;
  static const double overlayInsetHorizontal = 200;
  static const double overlayInsetVertical = 100;
  static const double menuWidthFactor = 0.6;
  static const double menuHeightFactor = 0.42;

  // Header and seed controls.
  static const double titleFontSize = 28;
  static const double seedInputWidth = 170;
  static const double seedInputHeight = 50;
  static const int seedCodeLength = 5;
  static const double seedLetterSpacing = 6;
  static const double seedHintLetterSpacing = 1.5;
  static const double refreshIconSize = 20;

  // Section spacing.
  static const double sectionSpacing = 12;
  static const double pickerTopSpacing = 20;
  static const double pickerBottomSpacing = 14;

  // Detail card layout.
  static const double detailsRadius = 12;
  static const double detailsPadding = 12;
  static const double detailsRowSpacing = 6;
  static const double detailsLabelWidth = 56;
  static const double detailsBackgroundAlpha = 0.25;

  // Candidate frog card visuals.
  static const double frogGridSpacing = 12;
  static const double frogCardSize = 82;
  static const double frogCardPadding = 8;
  static const double frogScaleHighlighted = 1.08;
  static const double frogScaleIdle = 1;
  static const double frogBackgroundAlphaHighlighted = 0.34;
  static const double frogBackgroundAlphaIdle = 0.2;

  // Copy and hints.
  static const String title = 'GRONOUŸ';
  static const String subtitle = "Tadpole's Big Frogger";
  static const String storyHint =
      'A young tadpole needs a guardian\nin the dangerous marsh.';
  static const String prePickControlsHint =
      'Choose your frog, then survive.\n'
      'Move WASD/Arrows/Stick | Confirm Enter/A\n'
      'Jump Space/A | Dive Shift/B | Lick J/X | Pause Esc/Start';
  static const String controlsHint =
      'Pick: Arrows/Gamepad  Confirm: Enter/A  Pause: Esc';
  static const double storyHintFontSize = 10;
  static const double prePickControlsFontSize = 9;
}

abstract final class IntroStoryUi {
  static const double overlayBackgroundAlpha = 0.45;
  static const double imageOverlayTopAlpha = 0.4;
  static const double imageOverlayBottomAlpha = 0.7;
  static const double cardMaxWidth = 760;
  static const double cardOuterPadding = 24;
  static const double cardRadius = 18;
  static const double cardInnerPaddingHorizontal = 22;
  static const double cardInnerPaddingVertical = 18;
  static const double titleBottomSpacing = 12;
  static const double actionsTopSpacing = 16;
  static const double actionHintLeftSpacing = 10;
  static const double titleFontSize = 30;
  static const double storyFontSize = 17;
  static const double storyLineHeight = 1.45;
  static const double actionHintFontSize = 14;

  static const Color fallbackGradientTop = Color(0xFF1A2E23);
  static const Color fallbackGradientBottom = Color(0xFF0B1713);
  static const Color cardBackground = Color(0xD815231C);
  static const Color cardBorder = Color(0x66F4D8A8);
  static const Color titleColor = Color(0xFFF8E5B9);
  static const Color bodyColor = Color(0xFFE8EFE7);
  static const Color actionHintColor = Color(0xFFC3D2C7);

  static const String title = 'Big Brother of the Marsh';
  static const String story =
      'The marsh is awake, and your little brothers are still scattered across the water.\n'
      'You are the eldest frog left to guard them. Watch for thorn patches, hungry birds overhead, and fish that strike from below.\n'
      'Choose wisely: each seed calls a different guardian, and every run tells a new rescue story.';
  static const String continueLabel = 'Continue';
  static const String continueHint = 'or press Space';
}

abstract final class WinOverlayUi {
  static const double overlayBackgroundAlpha = 0.45;
  static const double maxWidth = 560;
  static const double cardRadius = 18;
  static const double cardAspectRatio = 773 / 801;
  static const double contentSpacing = 18;
  static const double summaryHorizontalPadding = 36;
  static const double titleFontSize = 30;
  static const double summaryFontSize = 18;
  static const double summaryLineHeight = 1.35;
  static const double rescueTimeFontSize = 22;

  static const Color titleColor = Color(0xFF2A170E);
  static const Color summaryColor = Color(0xFF3B2418);
  static const Color rescueTimeColor = Color(0xFF1A0C05);

  static const String duplicatePublishMessage =
      'Score already published for this run.';
  static const String publishDialogTitle = 'Publish Score';
  static const String publishNameLabel = 'Player name';
  static const String publishNameHint = 'Enter your name';
  static const String seedDialogTitle = 'Set Seed';
  static const String seedLabel = 'Seed code';
  static const String seedHint = '5 letters/numbers';
  static const String seedAllowedCharactersPattern = r'[a-zA-Z0-9]';
  static const String cancelAction = 'Cancel';
  static const String startAction = 'Start';
  static const String seedLengthError = 'Seed must be 5 characters.';
  static const String seedInvalidError =
      'Invalid seed. Use 2-9 and A-Z (no 0, 1, I, O).';
  static const String publishSuccessMessage = 'Score published.';
  static const String publishFailMessage = 'Score publish failed.';
  static const String victoryExclamation = 'You did it ribbit!';
  static const String victoryTitle = 'The little brothers are safe.';
  static const String victorySummary =
      'You brought every egg home before the marsh could take them.';
  static const String rescueTimePrefix = 'Rescue time:';
  static const String publishingLabel = 'Publishing...';
  static const String publishedLabel = 'Published';
  static const String publishAction = 'Publish Score';
  static const String restartingLabel = 'Restarting...';
  static const String replayAction = 'Replay';
  static const String startWithSeedAction = 'Start with seed...';
}

abstract final class HotkeyOverlayUi {
  static const double panelRight = 24;
  static const double panelBottom = 34;
  static const double panelWidth = 236;
  static const double panelRadius = 14;
  static const double panelBorderWidth = 1;
  static const double panelPadding = 12;
  static const double panelRowGap = 8;
  static const double panelSectionGap = 10;
  static const double iconSize = 16;
  static const double keyGap = 6;
  static const double keyHorizontalPadding = 8;
  static const double keyVerticalPadding = 4;
  static const double keyRadius = 8;
  static const double titleFontSize = 16;
  static const double labelFontSize = 12;
  static const double keyFontSize = 12;

  static const Color panelBackground = Color(0xB318212A);
  static const Color panelBorder = Color(0x6694A8BE);
  static const Color titleColor = Color(0xFFE7F1FD);
  static const Color labelColor = Color(0xFFC9D7E8);
  static const Color keyTextColor = Color(0xFFF5FAFF);
  static const Color keyBackground = Color(0x334E5F73);
  static const Color keyBorder = Color(0x668CA3BB);

  static const String keyboardTitle = 'Keyboard';
  static const String gamepadTitle = 'Gamepad';
}
