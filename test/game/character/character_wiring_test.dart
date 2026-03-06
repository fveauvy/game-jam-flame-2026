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
        name: CharacterName(adjective: 'Brave', noun: 'Tadpole', batch: 'Mk I'),
        colorId: 'pond_green',
        colorHex: '#2A9D8F',
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

  test('setCharacterSeedCode updates current debug state', () async {
    final CharacterProfile profile = const CharacterProfile(
      name: CharacterName(adjective: 'Tiny', noun: 'Froglet', batch: ''),
      colorId: 'moss',
      colorHex: '#6B8E23',
    );
    final _FakeCharacterGenerator generator = _FakeCharacterGenerator(profile);
    final MyGame game = MyGame(characterGenerator: generator);

    await game.setCharacterSeedCode('4SFE6');

    expect(game.characterDebugState.value, isNotNull);
    expect(game.characterDebugState.value!.seedCode, '4SFE6');
    expect(game.characterDebugState.value!.seedInt, SeedCode.decode('4SFE6'));
    expect(game.characterDebugState.value!.profile, profile);
  });
}
