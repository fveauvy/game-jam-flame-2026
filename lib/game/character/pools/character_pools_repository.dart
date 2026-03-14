class CharacterColorPoolItem {
  const CharacterColorPoolItem({required this.id, required this.hex});

  final String id;
  final String hex;
}

class CharacterNamePool {
  const CharacterNamePool({
    required this.adjectives,
    required this.nouns,
    required this.titles,
  });

  final List<String> adjectives;
  final List<String> nouns;
  final List<String> titles;
}

class CharacterPools {
  const CharacterPools({required this.namePool, required this.colors});

  final CharacterNamePool namePool;
  final List<CharacterColorPoolItem> colors;
}

abstract interface class CharacterPoolsRepository {
  Future<CharacterPools> loadPools();
}
