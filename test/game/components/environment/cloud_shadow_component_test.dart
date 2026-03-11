import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/game/components/environment/cloud_shadow_component.dart';

void main() {
  test('wind direction is deterministic for same seed', () {
    final first = CloudShadowComponent.windDirectionFromSeed(12345);
    final second = CloudShadowComponent.windDirectionFromSeed(12345);

    expect(first.x, closeTo(second.x, 0.000001));
    expect(first.y, closeTo(second.y, 0.000001));
  });

  test('cloud count is deterministic for same seed', () {
    final first = CloudShadowComponent.cloudCountFromSeed(54321);
    final second = CloudShadowComponent.cloudCountFromSeed(54321);

    expect(first, second);
  });

  test('wind speed is deterministic for same seed', () {
    final first = CloudShadowComponent.windSpeedFromSeed(99999);
    final second = CloudShadowComponent.windSpeedFromSeed(99999);

    expect(first, closeTo(second, 0.000001));
  });
}
