abstract final class UiTiming {
  // Startup and transition durations.
  static const Duration splashScreenDuration = Duration(milliseconds: 2500);
  static const Duration frogAnimationDuration = Duration(milliseconds: 140);
}

abstract final class MenuUi {
  // Menu overlay layout.
  static const double panelMaxWidth = 420;
  static const double panelPadding = 24;
  static const double overlayInsetHorizontal = 200;
  static const double overlayInsetVertical = 100;

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
  static const String controlsHint =
      'Pick: Arrows/Gamepad  Confirm: Enter/A  Pause: Esc';
}
