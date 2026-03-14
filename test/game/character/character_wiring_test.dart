import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/game/character/generator/character_generator.dart';
import 'package:game_jam/game/character/infra/seed_code.dart';
import 'package:game_jam/game/character/model/character_name.dart';
import 'package:game_jam/game/character/model/character_profile.dart';
import 'package:game_jam/game/my_game.dart';

class _FakeCharacterGenerator implements CharacterGenerator {
  _FakeCharacterGenerator(this.profile);

  final CharacterProfile profile;
  int? lastSeed;

  @override
  Future<CharacterProfile> generate({required int seed}) async {
    lastSeed = seed;
    return profile;
  }
}

void main() {
  test(
    'game uses injected character generator for character profile',
    () async {
      const CharacterProfile profile = CharacterProfile(
        name: CharacterName(adjective: 'Brave', noun: 'Tadpole', title: 'Mk I'),
        spriteId: 'frog-1',
        spriteAssetPath: 'assets/images/gronouy/frog-1.png',
      );
      final _FakeCharacterGenerator generator = _FakeCharacterGenerator(
        profile,
      );
      final MyGame game = MyGame(
        characterGenerator: generator,
        characterSeedCode: '4SFE6',
      );

      final CharacterProfile generated = await game.generateCharacterProfile(
        seedCode: '4SFE6',
      );

      expect(generator.lastSeed, SeedCode.decode('4SFE6'));
      expect(generated, profile);
    },
  );

  test('setCharacterSeedCode updates current generation state', () async {
    final CharacterProfile profile = const CharacterProfile(
      name: CharacterName(adjective: 'Tiny', noun: 'Froglet', title: ''),
      spriteId: 'frog-2',
      spriteAssetPath: 'assets/images/gronouy/frog-2.png',
    );
    final _FakeCharacterGenerator generator = _FakeCharacterGenerator(profile);
    final MyGame game = MyGame(characterGenerator: generator);

    await game.setCharacterSeedCode('4SFE6');

    expect(game.characterGenerationState.value, isNotNull);
    expect(game.characterGenerationState.value!.seedCode, '4SFE6');
    expect(
      game.characterGenerationState.value!.seedInt,
      SeedCode.decode('4SFE6'),
    );
    expect(game.characterGenerationState.value!.profile, profile);
  });

  test('setMenuSeedCode updates seed while in menu phase', () async {
    final CharacterProfile profile = const CharacterProfile(
      name: CharacterName(adjective: 'Swift', noun: 'Frog', title: ''),
      spriteId: 'frog-3',
      spriteAssetPath: 'assets/images/gronouy/frog-3.png',
    );
    final _FakeCharacterGenerator generator = _FakeCharacterGenerator(profile);
    final MyGame game = MyGame(characterGenerator: generator);
    game.phase.value = GamePhase.menu;

    await game.setMenuSeedCode('9ABCD');

    expect(game.characterSeedCode, '9ABCD');
    expect(game.characterGenerationState.value, isNotNull);
    expect(game.characterGenerationState.value!.seedCode, '9ABCD');
  });
}
