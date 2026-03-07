class CharacterName {
  const CharacterName({
    required this.adjective,
    required this.noun,
    this.batch,
  });

  final String adjective;
  final String noun;
  final String? batch;

  static final RegExp _noCommaBatchStart = RegExp(
    r'^(of|from|in|on|that|the|who|which)\b',
    caseSensitive: false,
  );

  String get display {
    final String trimmedBatch = (batch ?? '').trim();
    if (trimmedBatch.isEmpty) {
      return '$adjective $noun';
    }

    final String separator = _noCommaBatchStart.hasMatch(trimmedBatch)
        ? ' '
        : ', ';
    return '$adjective $noun$separator$trimmedBatch';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CharacterName &&
        other.adjective == adjective &&
        other.noun == noun &&
        other.batch == batch;
  }

  @override
  int get hashCode => Object.hash(adjective, noun, batch);
}
