import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/app/routes.dart';
import 'package:game_jam/app/startup/startup_asset_loader.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/config/ui_config.dart';
import 'package:game_jam/game/character/model/character_profile.dart';
import 'package:game_jam/game/input/touch_input.dart';
import 'package:game_jam/game/my_game.dart';
import 'package:game_jam/screens/game_over_overlay.dart';
import 'package:game_jam/screens/pause_overlay.dart';
import 'package:game_jam/screens/startup_loading_screen.dart';
import 'package:game_jam/screens/startup_splash_screen.dart';

class GameJamApp extends StatefulWidget {
  const GameJamApp({super.key});

  @override
  State<GameJamApp> createState() => _GameJamAppState();
}

class _GameJamAppState extends State<GameJamApp> {
  final StartupAssetLoader _startupAssetLoader = StartupAssetLoader();
  MyGame? _game;
  _StartupStage _stage = _StartupStage.splash;
  String? _startupError;

  @override
  void initState() {
    super.initState();
    unawaited(_runStartupFlow());
  }

  Future<void> _runStartupFlow() async {
    debugPrint('[startup] splash begin');
    await Future<void>.delayed(UiTiming.splashScreenDuration);
    if (!mounted) {
      return;
    }

    await _retryStartup();
  }

  Future<void> _retryStartup() async {
    setState(() {
      _stage = _StartupStage.loading;
      _startupError = null;
    });

    try {
      await _startupAssetLoader.preloadAll();
      if (!mounted) {
        return;
      }
      final MyGame game = MyGame();
      setState(() {
        _game = game;
        _stage = _StartupStage.ready;
      });
      debugPrint('[startup] game ready');
    } on StartupPreloadException catch (error) {
      debugPrint('[startup] preload failure: $error');
      debugPrintStack(stackTrace: error.stackTrace);
      if (!mounted) {
        return;
      }
      setState(() {
        _stage = _StartupStage.failed;
        _startupError = '${error.category}: ${error.asset}';
      });
    } catch (error, stackTrace) {
      debugPrint('[startup] unexpected preload failure: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      setState(() {
        _stage = _StartupStage.failed;
        _startupError = error.toString();
      });
    }
  }

  Widget _buildGameStack(MyGame game) {
    return ValueListenableBuilder<GamePhase>(
      valueListenable: game.phase,
      builder: (_, GamePhase phase, _) {
        return Stack(
          children: [
            GameWidget<MyGame>(
              game: game,
              overlayBuilderMap: {
                AppOverlays.pause: (_, MyGame game) {
                  return ValueListenableBuilder<CharacterProfile?>(
                    valueListenable: game.characterState,
                    builder: (_, CharacterProfile? characterProfile, _) {
                      return PauseOverlay(
                        onResume: game.togglePause,
                        seedCode: game.characterSeedCode,
                        characterProfile: characterProfile,
                        currentHealth: game.playerRemainingHealth,
                        maxHealth: game.playerMaxHealth,
                      );
                    },
                  );
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
          ],
        );
      },
    );
  }

  // ValueListenableBuilder<GamePhase>(
  //         valueListenable: _game.phase,
  //         builder: (_, GamePhase phase, _) {
  //           return Stack(
  //             children: [
  //               GameWidget<MyGame>(
  //                 game: _game,
  //                 overlayBuilderMap: {
  //                   AppOverlays.pause: (_, MyGame game) {
  //                     return ValueListenableBuilder<CharacterProfile?>(
  //                       valueListenable: game.characterState,
  //                       builder: (_, CharacterProfile? characterProfile, _) {
  //                         return PauseOverlay(
  //                           onResume: game.togglePause,
  //                           seedCode: game.characterSeedCode,
  //                           characterProfile: characterProfile,
  //                           currentHealth: game.playerRemainingHealth,
  //                           maxHealth: game.playerMaxHealth,
  //                         );
  //                       },
  //                     );
  //                   },
  //                   AppOverlays.gameOver: (_, MyGame game) {
  //                     return GameOverOverlay(onRestart: game.startGame);
  //                   },
  //                   AppOverlays.touchControls: (_, MyGame game) {
  //                     return TouchInputOverlay(
  //                       input: game.inputState,
  //                       touchController: game.touchController,
  //                     );
  //                   },
  //                 },
  //               ),
  //             ],
  //           );
  //         },
  //       )

  @override
  Widget build(BuildContext context) {
    final MyGame? game = _game;
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
        body: switch (_stage) {
          _StartupStage.splash => const StartupSplashScreen(),
          _StartupStage.loading => const StartupLoadingScreen(isLoading: true),
          _StartupStage.failed => StartupLoadingScreen(
            isLoading: false,
            errorMessage: _startupError,
            onRetry: _retryStartup,
          ),
          _StartupStage.ready when game != null => _buildGameStack(game),
          _ => const StartupLoadingScreen(isLoading: true),
        },
      ),
    );
  }
}

enum _StartupStage { splash, loading, failed, ready }
