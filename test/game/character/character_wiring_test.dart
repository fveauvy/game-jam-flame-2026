import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/game/character/generator/character_generator.dart';
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
      final CharacterProfile profile = CharacterProfile(
        name: const CharacterName(
          adjective: 'Brave',
          noun: 'Tadpole',
          batch: 'Mk I',
        ),
        colorId: 'pond_green',
        colorHex: '#2A9D8F',
      );
      final _FakeCharacterGenerator generator = _FakeCharacterGenerator(
        profile,
      );
      final MyGame game = MyGame(
        characterGenerator: generator,
        characterSeed: 42,
      );

      final CharacterProfile generated = await game.generateCharacterProfile();

      expect(generator.lastSeed, 42);
      expect(generated, profile);
    },
  );
}
