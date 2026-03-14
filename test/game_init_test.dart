import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/core/leaderboard/leaderboard_client.dart';
import 'package:game_jam/game/my_game.dart';

class _FakeLeaderboardClient extends LeaderboardClient {
  String? playerName;
  int? elapsedTimeInMs;
  String? seedCode;

  @override
  Future<bool> submitScore({
    required String playerName,
    required int elapsedTimeInMs,
    String? seedCode,
  }) async {
    this.playerName = playerName;
    this.elapsedTimeInMs = elapsedTimeInMs;
    this.seedCode = seedCode;
    return true;
  }
}

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

  test('restartToMenu returns to menu when paused', () async {
    final MyGame game = MyGame();
    game.phase.value = GamePhase.paused;

    await game.restartToMenu();

    expect(game.phase.value, GamePhase.menu);
  });

  test('gameState reset clears eggs count', () {
    final MyGame game = MyGame();
    game.gameState.savedEggs = 3;

    game.gameState.reset();

    expect(game.gameState.savedEggs, 0);
  });

  test('restartToMenu resets eggs count', () async {
    final MyGame game = MyGame();
    game.phase.value = GamePhase.paused;
    game.gameState.savedEggs = 2;

    await game.restartToMenu();

    expect(game.gameState.savedEggs, 0);
  });

  test('restartToMenu is ignored outside paused phase', () async {
    final MyGame game = MyGame();
    game.phase.value = GamePhase.playing;

    await game.restartToMenu();

    expect(game.phase.value, GamePhase.playing);
  });

  test('publishWinningScore submits score with active seed code', () async {
    final _FakeLeaderboardClient leaderboardClient = _FakeLeaderboardClient();
    final MyGame game = MyGame(
      leaderboardClient: leaderboardClient,
      characterSeedCode: '4SFE6',
    );
    game.gameState.elapsedTimeInMs = 54321;
    game.phase.value = GamePhase.win;

    final bool result = await game.publishWinningScore('  Alice  ');

    expect(result, isTrue);
    expect(leaderboardClient.playerName, 'Alice');
    expect(leaderboardClient.elapsedTimeInMs, 54321);
    expect(leaderboardClient.seedCode, '4SFE6');
  });

  test('egg spawn position is invalid on leaf or thorn', () {
    expect(
      MyGame.isValidEggSpawnPosition(isOnThorn: false, isOnLeaf: false),
      isTrue,
    );
    expect(
      MyGame.isValidEggSpawnPosition(isOnThorn: true, isOnLeaf: false),
      isFalse,
    );
    expect(
      MyGame.isValidEggSpawnPosition(isOnThorn: false, isOnLeaf: true),
      isFalse,
    );
    expect(
      MyGame.isValidEggSpawnPosition(isOnThorn: true, isOnLeaf: true),
      isFalse,
    );
  });
}
