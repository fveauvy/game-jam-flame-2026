class CharacterName {
  const CharacterName({
    required this.adjective,
    required this.noun,
    this.batch,
  });

  final String adjective;
  final String noun;
  final String? batch;

  String get display {
    final String trimmedBatch = (batch ?? '').trim();
    if (trimmedBatch.isEmpty) {
      return '$adjective $noun';
    }
    return '$adjective $noun $trimmedBatch';
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
