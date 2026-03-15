import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/core/config/gameplay_tuning.dart';
import 'package:game_jam/game/character/generator/character_generator.dart';
import 'package:game_jam/game/character/infra/seed_code.dart';
import 'package:game_jam/game/character/model/character_name.dart';
import 'package:game_jam/game/character/model/character_profile.dart';
import 'package:game_jam/game/my_game.dart';

class _FakeCharacterGenerator implements CharacterGenerator {
  _FakeCharacterGenerator(this.profiles)
    : assert(profiles.isNotEmpty, 'profiles must not be empty');

  final List<CharacterProfile> profiles;
  int? lastSeed;
  int callCount = 0;

  @override
  Future<CharacterProfile> generate({required int seed}) async {
    lastSeed = seed;
    final int index = callCount < profiles.length
        ? callCount
        : profiles.length - 1;
    callCount++;
    return profiles[index];
  }
}

String _nameKey(String? value) => (value ?? '').trim().toLowerCase();

void main() {
  test(
    'game uses injected character generator for character profile',
    () async {
      const CharacterProfile profile = CharacterProfile(
        name: CharacterName(adjective: 'Brave', noun: 'Tadpole', title: 'Mk I'),
        spriteId: 'frog-1',
        spriteAssetPath: 'assets/images/gronouy/frog-1.png',
      );
      final _FakeCharacterGenerator generator = _FakeCharacterGenerator([
        profile,
      ]);
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
    final _FakeCharacterGenerator generator = _FakeCharacterGenerator([
      profile,
    ]);
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
    final _FakeCharacterGenerator generator = _FakeCharacterGenerator([
      profile,
    ]);
    final MyGame game = MyGame(characterGenerator: generator);
    game.phase.value = GamePhase.menu;

    await game.setMenuSeedCode('9ABCD');

    expect(game.characterSeedCode, '9ABCD');
    expect(game.characterGenerationState.value, isNotNull);
    expect(game.characterGenerationState.value!.seedCode, '9ABCD');
  });

  test(
    'candidate generation prefers unique adjective title and display',
    () async {
      final List<CharacterProfile> sequence = <CharacterProfile>[
        const CharacterProfile(
          name: CharacterName(
            adjective: 'Brave',
            noun: 'Craig',
            title: 'from the Future',
          ),
          spriteId: 'frog-1',
          spriteAssetPath: 'assets/images/gronouy/frog-1.png',
        ),
        const CharacterProfile(
          name: CharacterName(
            adjective: 'Swift',
            noun: 'Swimmer',
            title: 'from the Future',
          ),
          spriteId: 'frog-2',
          spriteAssetPath: 'assets/images/gronouy/frog-2.png',
        ),
        const CharacterProfile(
          name: CharacterName(
            adjective: 'Brave',
            noun: 'Guardian',
            title: 'of the Bog',
          ),
          spriteId: 'frog-3',
          spriteAssetPath: 'assets/images/gronouy/frog-3.png',
        ),
        const CharacterProfile(
          name: CharacterName(
            adjective: 'Brave',
            noun: 'Craig',
            title: 'from the Future',
          ),
          spriteId: 'frog-4',
          spriteAssetPath: 'assets/images/gronouy/frog-4.png',
        ),
        const CharacterProfile(
          name: CharacterName(
            adjective: 'Tiny',
            noun: 'Toad',
            title: 'of the Marsh',
          ),
          spriteId: 'frog-5',
          spriteAssetPath: 'assets/images/gronouy/frog-5.png',
        ),
        const CharacterProfile(
          name: CharacterName(
            adjective: 'Nimble',
            noun: 'Leaper',
            title: 'Keeper of Echoes',
          ),
          spriteId: 'frog-6',
          spriteAssetPath: 'assets/images/gronouy/frog-6.png',
        ),
        const CharacterProfile(
          name: CharacterName(
            adjective: 'Warty',
            noun: 'Bullfrog',
            title: 'of the Lily Court',
          ),
          spriteId: 'frog-7',
          spriteAssetPath: 'assets/images/gronouy/frog-7.png',
        ),
        const CharacterProfile(
          name: CharacterName(
            adjective: 'Croaking',
            noun: 'Polliwog',
            title: 'the Unstoppable',
          ),
          spriteId: 'frog-8',
          spriteAssetPath: 'assets/images/gronouy/frog-8.png',
        ),
      ];
      final _FakeCharacterGenerator generator = _FakeCharacterGenerator(
        sequence,
      );
      final MyGame game = MyGame(characterGenerator: generator);

      await game.setCharacterSeedCode('6DCE9');

      final List<CharacterProfile> profiles =
          game.characterGenerationState.value!.candidateProfiles;
      expect(profiles.length, GameplayTuning.menuCharacterCandidateCount);

      final List<String> adjectives = profiles
          .map((p) => _nameKey(p.name.adjective))
          .where((value) => value.isNotEmpty)
          .toList();
      final List<String> titles = profiles
          .map((p) => _nameKey(p.name.title))
          .where((value) => value.isNotEmpty)
          .toList();
      final List<String> displays = profiles
          .map((p) => _nameKey(p.name.display))
          .toList();

      expect(adjectives.toSet().length, adjectives.length);
      expect(titles.toSet().length, titles.length);
      expect(displays.toSet().length, displays.length);
      expect(
        generator.callCount,
        greaterThan(GameplayTuning.menuCharacterCandidateCount),
      );
    },
  );

  test('candidate generation falls back to duplicates when needed', () async {
    const CharacterProfile repeated = CharacterProfile(
      name: CharacterName(
        adjective: 'Brave',
        noun: 'Craig',
        title: 'from the Future',
      ),
      spriteId: 'frog-1',
      spriteAssetPath: 'assets/images/gronouy/frog-1.png',
    );
    final _FakeCharacterGenerator generator = _FakeCharacterGenerator([
      repeated,
    ]);
    final MyGame game = MyGame(characterGenerator: generator);

    await game.setCharacterSeedCode('6DCE9');

    final List<CharacterProfile> profiles =
        game.characterGenerationState.value!.candidateProfiles;
    expect(profiles.length, GameplayTuning.menuCharacterCandidateCount);

    final List<String> displays = profiles
        .map((p) => _nameKey(p.name.display))
        .toList();
    expect(displays.toSet().length, lessThan(displays.length));
    expect(
      generator.callCount,
      greaterThanOrEqualTo(GameplayTuning.menuCharacterCandidateUniqueAttempts),
    );
  });
}
