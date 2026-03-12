import 'dart:convert';

abstract final class LeaderboardConfig {
  static const String submitUrl = String.fromEnvironment(
    'LEADERBOARD_SUBMIT_URL',
    defaultValue: '',
  );
  static const String _keyPartA = String.fromEnvironment(
    'LEADERBOARD_KEY_PART_A',
    defaultValue: '',
  );
  static const String _keyPartB = String.fromEnvironment(
    'LEADERBOARD_KEY_PART_B',
    defaultValue: '',
  );

  static String resolveSubmitKey() {
    if (_keyPartA.isEmpty || _keyPartB.isEmpty) {
      return '';
    }
    final String merged = _keyPartB + _keyPartA;
    final String normalized = merged.replaceAll('-', '+').replaceAll('_', '/');
    return utf8.decode(base64.decode(normalized));
  }
}
