import 'package:game_jam/game/character/generator/character_generator.dart';
import 'package:game_jam/game/character/infra/seeded_rng.dart';
import 'package:game_jam/game/character/model/character_name.dart';
import 'package:game_jam/game/character/model/character_profile.dart';
import 'package:game_jam/game/character/pools/character_pools_repository.dart';

class ProceduralCharacterGenerator implements CharacterGenerator {
  ProceduralCharacterGenerator({required CharacterPools pools})
    : _pools = pools;

  final CharacterPools _pools;

  @override
  Future<CharacterProfile> generate({required int seed}) async {
    final SeededRng rng = SeededRng(seed);
    final CharacterNamePool namePool = _pools.namePool;

    final String adjective = rng.pick(namePool.adjectives);
    final String noun = rng.pick(namePool.nouns);
    final String? batch = namePool.batches.isEmpty
        ? null
        : rng.pick(namePool.batches);
    final CharacterColorPoolItem color = rng.pick(_pools.colors);

    return CharacterProfile(
      name: CharacterName(adjective: adjective, noun: noun, batch: batch),
      colorId: color.id,
      colorHex: color.hex,
    );
  }
}
