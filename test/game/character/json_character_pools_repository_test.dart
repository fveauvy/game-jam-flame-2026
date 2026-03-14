import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/game/character/infra/json_character_pools_repository.dart';
import 'package:game_jam/game/character/pools/character_pools_repository.dart';

void main() {
  test('loads pools from json', () async {
    final JsonCharacterPoolsRepository repo = JsonCharacterPoolsRepository(
      loader: (_) async => '''
{
  "version": 1,
  "names": {
    "adjectives": ["Brave"],
    "nouns": ["Tadpole"],
    "titles": ["Mk I"]
  },
  "colors": [
    { "id": "pond_green", "hex": "#2A9D8F" }
  ]
}
''',
    );

    final CharacterPools pools = await repo.loadPools();

    expect(pools.namePool.adjectives, <String>['Brave']);
    expect(pools.namePool.nouns, <String>['Tadpole']);
    expect(pools.namePool.titles, <String>['Mk I']);
    expect(pools.colors.first.id, 'pond_green');
  });

  test('loads legacy batches key for backward compatibility', () async {
    final JsonCharacterPoolsRepository repo = JsonCharacterPoolsRepository(
      loader: (_) async => '''
{
  "version": 1,
  "names": {
    "adjectives": ["Brave"],
    "nouns": ["Tadpole"],
    "batches": ["Legacy"]
  },
  "colors": [
    { "id": "pond_green", "hex": "#2A9D8F" }
  ]
}
''',
    );

    final CharacterPools pools = await repo.loadPools();

    expect(pools.namePool.titles, <String>['Legacy']);
  });

  test('throws on missing required lists', () async {
    final JsonCharacterPoolsRepository repo = JsonCharacterPoolsRepository(
      loader: (_) async => '{"names": {}, "colors": []}',
    );

    expect(repo.loadPools, throwsFormatException);
  });
}
