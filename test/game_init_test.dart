import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/game/my_game.dart';

void main() {
  test('game starts in loading phase', () {
    final MyGame game = MyGame();
    expect(game.phase.value, GamePhase.loading);
  });

  test('startGame is ignored while paused', () {
    final MyGame game = MyGame();
    game.phase.value = GamePhase.paused;

    game.startGame();

    expect(game.phase.value, GamePhase.paused);
  });

  test('restartToMenu returns to menu when paused', () {
    final MyGame game = MyGame();
    game.phase.value = GamePhase.paused;

    game.restartToMenu();

    expect(game.phase.value, GamePhase.menu);
  });

  test('gameState reset clears eggs count', () {
    final MyGame game = MyGame();
    game.gameState.savedEggs = 3;

    game.gameState.reset();

    expect(game.gameState.savedEggs, 0);
  });

  test('restartToMenu resets eggs count', () {
    final MyGame game = MyGame();
    game.phase.value = GamePhase.paused;
    game.gameState.savedEggs = 2;

    game.restartToMenu();

    expect(game.gameState.savedEggs, 0);
  });

  test('restartToMenu is ignored outside paused phase', () {
    final MyGame game = MyGame();
    game.phase.value = GamePhase.playing;

    game.restartToMenu();

    expect(game.phase.value, GamePhase.playing);
  });
}
