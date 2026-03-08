import 'package:game_jam/game/character/generator/character_generator.dart';
import 'package:game_jam/game/character/infra/seeded_rng.dart';
import 'package:game_jam/game/character/model/character_name.dart';
import 'package:game_jam/game/character/model/character_profile.dart';
import 'package:game_jam/game/character/model/character_traits.dart';
import 'package:game_jam/game/character/pools/character_pools_repository.dart';
import 'package:game_jam/core/constants/asset_paths.dart';
import 'package:game_jam/core/constants/gameplay_tuning.dart';

class ProceduralCharacterGenerator implements CharacterGenerator {
  ProceduralCharacterGenerator({required CharacterPools pools})
    : _pools = pools;

  static const int _traitPrecision = 1000;
  static const int _minHealth = 60;
  static const int _maxHealth = 150;

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
    final int spriteNumber = _resolveSpriteNumber(seed);

    final double speedMultiplier = _rollTrait(rng: rng, min: 0.7, max: 1.5);
    final double sizeMultiplier = _rollTrait(rng: rng, min: 0.8, max: 1.25);
    final double intelligence = _rollTrait(rng: rng, min: 0.5, max: 2.0);
    final int health = _rollHealth(rng);

    return CharacterProfile(
      name: CharacterName(adjective: adjective, noun: noun, batch: batch),
      spriteId: 'frog-$spriteNumber',
      spriteAssetPath: AssetPaths.frogSpriteAssetPath(spriteNumber),
      traits: CharacterTraits(
        speed: speedMultiplier,
        size: sizeMultiplier,
        intelligence: intelligence,
        health: health,
      ),
    );
  }

  int _rollHealth(SeededRng rng) {
    return _minHealth + rng.nextInt(_maxHealth - _minHealth + 1);
  }

  int _resolveSpriteNumber(int seed) {
    return (seed % GameplayTuning.frogSpriteCount) + 1;
  }

  double _rollTrait({
    required SeededRng rng,
    required double min,
    required double max,
  }) {
    final double t = rng.nextInt(_traitPrecision + 1) / _traitPrecision;
    return min + (max - min) * t;
  }
}
