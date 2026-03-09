import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/game/components/enemies/bird_enemy_component.dart';
import 'package:game_jam/game/my_game.dart';

void main() {
  test('bird enemy runs only in playing phase', () {
    expect(BirdEnemyComponent.shouldRunForPhase(GamePhase.loading), isFalse);
    expect(BirdEnemyComponent.shouldRunForPhase(GamePhase.menu), isFalse);
    expect(BirdEnemyComponent.shouldRunForPhase(GamePhase.paused), isFalse);
    expect(BirdEnemyComponent.shouldRunForPhase(GamePhase.gameOver), isFalse);
    expect(BirdEnemyComponent.shouldRunForPhase(GamePhase.playing), isTrue);
  });
}
