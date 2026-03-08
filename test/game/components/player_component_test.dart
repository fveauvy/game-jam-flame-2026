import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/core/entities/player_vertical_position.dart';
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
      spriteId: 'frog-1',
      spriteAssetPath: 'assets/images/gronouy/frog-1.png',
      traits: CharacterTraits(health: 123),
    );

    expect(PlayerComponent.resolveMaxHealth(profile), 123);
  });

  test('resolveMaxHealth falls back to default value', () {
    const CharacterProfile profile = CharacterProfile(
      name: CharacterName(adjective: 'Brave', noun: 'Tadpole'),
      spriteId: 'frog-1',
      spriteAssetPath: 'assets/images/gronouy/frog-1.png',
      traits: CharacterTraits.empty,
    );

    expect(PlayerComponent.resolveMaxHealth(profile), 100);
  });

  test('land ignores dive, but auto-drops to water level in water tile', () {
    final staysLand = PlayerComponent.resolveVerticalPosition(
      current: PlayerVerticalPosition.land,
      isInWater: false,
      jumpPressed: false,
      divePressed: true,
      canStayOnLand: true,
      jumpActive: false,
    );
    final entersWater = PlayerComponent.resolveVerticalPosition(
      current: PlayerVerticalPosition.land,
      isInWater: true,
      jumpPressed: false,
      divePressed: true,
      canStayOnLand: false,
      jumpActive: false,
    );

    expect(staysLand, PlayerVerticalPosition.land);
    expect(entersWater, PlayerVerticalPosition.waterLevel);
  });

  test('water-level dive goes underwater', () {
    final next = PlayerComponent.resolveVerticalPosition(
      current: PlayerVerticalPosition.waterLevel,
      isInWater: true,
      jumpPressed: false,
      divePressed: true,
      canStayOnLand: false,
      jumpActive: false,
    );

    expect(next, PlayerVerticalPosition.underwater);
  });

  test('water-level does not become land from jump flag alone', () {
    final withJump = PlayerComponent.resolveVerticalPosition(
      current: PlayerVerticalPosition.waterLevel,
      isInWater: true,
      jumpPressed: true,
      divePressed: false,
      canStayOnLand: true,
      jumpActive: false,
    );

    expect(withJump, PlayerVerticalPosition.waterLevel);
  });

  test('underwater jump only goes up one level', () {
    final jumpUp = PlayerComponent.resolveVerticalPosition(
      current: PlayerVerticalPosition.underwater,
      isInWater: true,
      jumpPressed: true,
      divePressed: false,
      canStayOnLand: true,
      jumpActive: false,
    );

    expect(jumpUp, PlayerVerticalPosition.waterLevel);
  });

  test('water-level and underwater return to water-level outside water', () {
    final fromSurface = PlayerComponent.resolveVerticalPosition(
      current: PlayerVerticalPosition.waterLevel,
      isInWater: false,
      jumpPressed: false,
      divePressed: false,
      canStayOnLand: false,
      jumpActive: false,
    );
    final fromUnderwater = PlayerComponent.resolveVerticalPosition(
      current: PlayerVerticalPosition.underwater,
      isInWater: false,
      jumpPressed: false,
      divePressed: false,
      canStayOnLand: false,
      jumpActive: false,
    );

    expect(fromSurface, PlayerVerticalPosition.waterLevel);
    expect(fromUnderwater, PlayerVerticalPosition.waterLevel);
  });

  test('land can stay on lily even above water', () {
    final next = PlayerComponent.resolveVerticalPosition(
      current: PlayerVerticalPosition.land,
      isInWater: true,
      jumpPressed: false,
      divePressed: false,
      canStayOnLand: true,
      jumpActive: false,
    );

    expect(next, PlayerVerticalPosition.land);
  });

  test('jump-active always resolves as land', () {
    final next = PlayerComponent.resolveVerticalPosition(
      current: PlayerVerticalPosition.waterLevel,
      isInWater: true,
      jumpPressed: false,
      divePressed: true,
      canStayOnLand: false,
      jumpActive: true,
    );

    expect(next, PlayerVerticalPosition.land);
  });
}
