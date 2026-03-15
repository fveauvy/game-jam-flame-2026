import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/game/character/generator/procedural_character_generator.dart';
import 'package:game_jam/game/character/model/character_profile.dart';
import 'package:game_jam/game/character/pools/character_pools_repository.dart';

void main() {
  const CharacterPools pools = CharacterPools(
    namePool: CharacterNamePool(
      adjectives: <String>['Brave', 'Tiny', 'Swift'],
      nouns: <String>['Tadpole', 'Froglet', 'Leaper'],
      titles: <String>['Mk I', 'Prime', 'Patrol'],
    ),
    colors: <CharacterColorPoolItem>[
      CharacterColorPoolItem(id: 'pond_green', hex: '#2A9D8F'),
      CharacterColorPoolItem(id: 'moss', hex: '#6B8E23'),
      CharacterColorPoolItem(id: 'mud', hex: '#8D6E63'),
    ],
  );

  test('same seed gives same profile', () async {
    final ProceduralCharacterGenerator generator = ProceduralCharacterGenerator(
      pools: pools,
    );

    final CharacterProfile a = await generator.generate(seed: 1337);
    final CharacterProfile b = await generator.generate(seed: 1337);

    expect(a, b);
    expect(a.traits.speed, isNotNull);
    expect(a.traits.size, isNotNull);
    expect(a.traits.intelligence, isNotNull);
    expect(a.traits.health, isNotNull);
  });

  test('different seeds usually change profile', () async {
    final ProceduralCharacterGenerator generator = ProceduralCharacterGenerator(
      pools: pools,
    );

    final CharacterProfile a = await generator.generate(seed: 1337);
    final CharacterProfile b = await generator.generate(seed: 1338);

    final bool sameName = a.name == b.name;
    final bool sameSprite = a.spriteId == b.spriteId;
    final bool sameSpeed = a.traits.speed == b.traits.speed;
    final bool sameSize = a.traits.size == b.traits.size;
    final bool sameIntelligence =
        a.traits.intelligence == b.traits.intelligence;
    final bool sameHealth = a.traits.health == b.traits.health;
    expect(
      sameName &&
          sameSprite &&
          sameSpeed &&
          sameSize &&
          sameIntelligence &&
          sameHealth,
      isFalse,
    );
  });

  test('seed maps deterministically to frog sprite index', () async {
    final ProceduralCharacterGenerator generator = ProceduralCharacterGenerator(
      pools: pools,
    );

    // Player sprites restricted to [10, 11, 12, 13, 14].
    final CharacterProfile s0 = await generator.generate(seed: 0);
    final CharacterProfile s4 = await generator.generate(seed: 4);
    final CharacterProfile s5 = await generator.generate(seed: 5);

    expect(s0.spriteId, 'frog-10');
    expect(s0.spriteAssetPath, 'assets/images/gronouy/frog-10.png');
    expect(s4.spriteId, 'frog-14');
    expect(s4.spriteAssetPath, 'assets/images/gronouy/frog-14.png');
    // Wraps around.
    expect(s5.spriteId, 'frog-10');
    expect(s5.spriteAssetPath, 'assets/images/gronouy/frog-10.png');
  });

  test('traits stay within configured ranges', () async {
    final ProceduralCharacterGenerator generator = ProceduralCharacterGenerator(
      pools: pools,
    );

    final CharacterProfile profile = await generator.generate(seed: 2026);

    expect(profile.traits.speed, inInclusiveRange(0.7, 1.5));
    expect(profile.traits.size, inInclusiveRange(0.8, 1.25));
    expect(profile.traits.intelligence, inInclusiveRange(0.5, 2.0));
    expect(profile.traits.health, inInclusiveRange(60, 150));
  });

  test('generated name uses either adjective or title', () async {
    final ProceduralCharacterGenerator generator = ProceduralCharacterGenerator(
      pools: pools,
    );

    for (int seed = 0; seed < 50; seed++) {
      final CharacterProfile profile = await generator.generate(seed: seed);
      final bool hasAdjective = (profile.name.adjective ?? '')
          .trim()
          .isNotEmpty;
      final bool hasTitle = (profile.name.title ?? '').trim().isNotEmpty;

      expect(hasAdjective || hasTitle, isTrue);
      expect(hasAdjective && hasTitle, isFalse);
    }
  });
}
