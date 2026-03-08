import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/game/character/model/character_name.dart';
import 'package:game_jam/game/character/model/character_profile.dart';
import 'package:game_jam/game/character/model/character_traits.dart';
import 'package:game_jam/game/components/player/player_component.dart';

void main() {
  test('normalizeMoveAxis keeps cardinal direction unchanged', () {
    final velocity = PlayerComponent.normalizeMoveAxis(0, 1);

    expect(velocity.x, 0);
    expect(velocity.y, 1);
  });

  test('normalizeMoveAxis normalizes diagonal movement', () {
    final velocity = PlayerComponent.normalizeMoveAxis(1, 1);

    expect(velocity.length, closeTo(1, 0.000001));
    expect(velocity.x, closeTo(0.707106, 0.000001));
    expect(velocity.y, closeTo(0.707106, 0.000001));
  });

  test('shouldRenderGlasses enables frames at threshold', () {
    expect(PlayerComponent.shouldRenderGlasses(1.69), isFalse);
    expect(PlayerComponent.shouldRenderGlasses(1.7), isTrue);
    expect(PlayerComponent.shouldRenderGlasses(2.0), isTrue);
  });

  test('resolveMaxHealth uses trait when available', () {
    const CharacterProfile profile = CharacterProfile(
      name: CharacterName(adjective: 'Brave', noun: 'Tadpole'),
      colorId: 'pond_green',
      colorHex: '#2A9D8F',
      traits: CharacterTraits(health: 123),
    );

    expect(PlayerComponent.resolveMaxHealth(profile), 123);
  });

  test('resolveMaxHealth falls back to default value', () {
    const CharacterProfile profile = CharacterProfile(
      name: CharacterName(adjective: 'Brave', noun: 'Tadpole'),
      colorId: 'pond_green',
      colorHex: '#2A9D8F',
      traits: CharacterTraits.empty,
    );

    expect(PlayerComponent.resolveMaxHealth(profile), 100);
  });
}
