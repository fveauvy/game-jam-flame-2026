import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/app/routes.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/game/character/model/character_debug_state.dart';
import 'package:game_jam/game/input/touch_input.dart';
import 'package:game_jam/game/my_game.dart';
import 'package:game_jam/screens/game_over_overlay.dart';
import 'package:game_jam/screens/menu_screen.dart';
import 'package:game_jam/screens/pause_overlay.dart';

class GameJamApp extends StatefulWidget {
  const GameJamApp({super.key});

  @override
  State<GameJamApp> createState() => _GameJamAppState();
}

class _GameJamAppState extends State<GameJamApp> {
  late final MyGame _game;

  @override
  void initState() {
    super.initState();
    _game = MyGame();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: GameConfig.title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFCA311),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      home: Scaffold(
        body: ValueListenableBuilder<GamePhase>(
          valueListenable: _game.phase,
          builder: (_, GamePhase phase, _) {
            return Stack(
              children: [
                GameWidget<MyGame>(
                  game: _game,
                  overlayBuilderMap: {
                    AppOverlays.pause: (_, MyGame game) {
                      return PauseOverlay(onResume: game.togglePause);
                    },
                    AppOverlays.gameOver: (_, MyGame game) {
                      return GameOverOverlay(onRestart: game.startGame);
                    },
                    AppOverlays.touchControls: (_, MyGame game) {
                      return TouchInputOverlay(
                        input: game.inputState,
                        touchController: game.touchController,
                      );
                    },
                  },
                ),
                if (phase == GamePhase.menu)
                  ValueListenableBuilder<CharacterDebugState?>(
                    valueListenable: _game.characterDebugState,
                    builder: (_, CharacterDebugState? debugState, _) {
                      String seed = debugState?.seedCode ?? '-';
                      final inputController = TextEditingController(text: seed);
                      void onInputChange(String value) {
                        if (value.length == 5) {
                          debugPrint('Seed submitted: ${inputController.text}');
                          seed = inputController.text;
                        }
                      }

                      return MenuScreen(
                        onReroll: () async {
                          await _game.rerollCharacter();
                        },
                        viewPortSize: _game.camera.viewport.size,
                        inputController: inputController,
                        onInputChange: onInputChange,
                        onStart: _game.startGame,
                        debugState: debugState,
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
