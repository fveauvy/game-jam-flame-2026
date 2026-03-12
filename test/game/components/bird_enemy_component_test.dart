import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/game/components/enemies/bird/bird_component.dart';
import 'package:game_jam/game/my_game.dart';

void main() {
  test('bird enemy runs only in playing phase', () {
    expect(BirdComponent.shouldRunForPhase(GamePhase.loading), isFalse);
    expect(BirdComponent.shouldRunForPhase(GamePhase.menu), isFalse);
    expect(BirdComponent.shouldRunForPhase(GamePhase.paused), isFalse);
    expect(BirdComponent.shouldRunForPhase(GamePhase.gameOver), isFalse);
    expect(BirdComponent.shouldRunForPhase(GamePhase.playing), isTrue);
  });
}
