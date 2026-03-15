class CharacterName {
  const CharacterName({this.adjective, required this.noun, this.title});

  final String? adjective;
  final String noun;
  final String? title;

  static final RegExp _noCommaTitleStart = RegExp(
    r'^(of|from|in|on|that|the|who|which)\b',
    caseSensitive: false,
  );

  String get display {
    final String trimmedAdjective = (adjective ?? '').trim();
    final String trimmedTitle = (title ?? '').trim();
    final String baseName = trimmedAdjective.isEmpty
        ? noun
        : '$trimmedAdjective $noun';
    if (trimmedTitle.isEmpty) {
      return baseName;
    }

    final String separator = _noCommaTitleStart.hasMatch(trimmedTitle)
        ? ' '
        : ', ';
    return '$baseName$separator$trimmedTitle';
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
