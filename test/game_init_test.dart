import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/game/my_game.dart';

void main() {
  test('game starts in menu phase', () {
    final MyGame game = MyGame();
    expect(game.phase.value, GamePhase.menu);
  });
}
