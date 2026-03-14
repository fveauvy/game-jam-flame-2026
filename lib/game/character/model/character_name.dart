class CharacterName {
  const CharacterName({
    required this.adjective,
    required this.noun,
    this.title,
  });

  final String adjective;
  final String noun;
  final String? title;

  static final RegExp _noCommaTitleStart = RegExp(
    r'^(of|from|in|on|that|the|who|which)\b',
    caseSensitive: false,
  );

  String get display {
    final String trimmedTitle = (title ?? '').trim();
    if (trimmedTitle.isEmpty) {
      return '$adjective $noun';
    }

    final String separator = _noCommaTitleStart.hasMatch(trimmedTitle)
        ? ' '
        : ', ';
    return '$adjective $noun$separator$trimmedTitle';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CharacterName &&
        other.adjective == adjective &&
        other.noun == noun &&
        other.title == title;
  }

  @override
  int get hashCode => Object.hash(adjective, noun, title);
}
