import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/game/my_game.dart';

void main() {
  test('game starts in menu phase', () {
    final MyGame game = MyGame();
    expect(game.phase.value, GamePhase.menu);
  });

  test('startGame is ignored while paused', () {
    final MyGame game = MyGame();
    game.phase.value = GamePhase.paused;

    game.startGame();

    expect(game.phase.value, GamePhase.paused);
  });
}
