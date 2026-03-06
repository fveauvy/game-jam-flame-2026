import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:game_jam/app/routes.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/utils/time_utils.dart';
import 'package:game_jam/game/character/generator/character_generator.dart';
import 'package:game_jam/game/character/generator/procedural_character_generator.dart';
import 'package:game_jam/game/character/infra/json_character_pools_repository.dart';
import 'package:game_jam/game/character/model/character_profile.dart';
import 'package:game_jam/game/character/pools/character_pools_repository.dart';
import 'package:game_jam/game/camera/camera_controller.dart';
import 'package:game_jam/game/components/player/player_component.dart';
import 'package:game_jam/game/components/ui/hud_component.dart';
import 'package:game_jam/game/input/input_state.dart';
import 'package:game_jam/game/input/keyboard_input.dart';
import 'package:game_jam/game/systems/collision_system.dart';
import 'package:game_jam/game/systems/spawn_system.dart';
import 'package:game_jam/game/world/level_1.dart';
import 'package:game_jam/game/world/world_root.dart';

enum GamePhase { menu, playing, paused, gameOver }

class MyGame extends FlameGame<WorldRoot> with KeyboardEvents {
  MyGame({
    CharacterGenerator? characterGenerator,
    CharacterPoolsRepository? characterPoolsRepository,
    int? characterSeed,
  }) : _characterGenerator = characterGenerator,
       _characterPoolsRepository =
           characterPoolsRepository ?? JsonCharacterPoolsRepository(),
       characterSeed = characterSeed ?? GameConfig.defaultCharacterSeed,
       super(
         world: WorldRoot(),
         camera: CameraComponent.withFixedResolution(
           width: GameConfig.baseWidth,
           height: GameConfig.baseHeight,
         ),
       );

  final InputState inputState = InputState();
  final KeyboardInput keyboardInput = KeyboardInput();
  final ValueNotifier<GamePhase> phase = ValueNotifier<GamePhase>(
    GamePhase.menu,
  );
  final CharacterGenerator? _characterGenerator;
  final CharacterPoolsRepository _characterPoolsRepository;
  final int characterSeed;

  late final PlayerComponent _player;
  late final GameCameraController _cameraController;
  CharacterProfile? generatedCharacterProfile;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    generatedCharacterProfile = await generateCharacterProfile();

    final Level1 level = Level1();
    _player = PlayerComponent(
      inputState: inputState,
      profile: generatedCharacterProfile!,
      startPosition: GameConfig.playerSpawn,
    );

    world.addAll([
      level,
      _player,
      SpawnSystem(),
      CollisionSystem(),
      HudComponent(),
    ]);
    world.bindPlayer(_player);

    _cameraController = GameCameraController(
      camera: camera,
      target: _player,
      worldSize: GameConfig.worldSize,
      viewportSize: Vector2(GameConfig.baseWidth, GameConfig.baseHeight),
    );
    _cameraController.attach();

    overlays.add(AppOverlays.menu);
  }

  Future<CharacterProfile> generateCharacterProfile() async {
    final CharacterGenerator generator;
    if (_characterGenerator != null) {
      generator = _characterGenerator;
    } else {
      final CharacterPools pools = await _characterPoolsRepository.loadPools();
      generator = ProceduralCharacterGenerator(pools: pools);
    }

    return generator.generate(seed: characterSeed);
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    return keyboardInput.handleEvent(event, inputState);
  }

  @override
  void update(double dt) {
    super.update(clampDeltaTime(dt, GameConfig.maxDeltaTime));

    if (inputState.pausePressed) {
      togglePause();
    }
    _cameraController.update();
    inputState.clearTransient();
  }

  void startGame() {
    world.reset();
    phase.value = GamePhase.playing;
    resumeEngine();

    overlays
      ..remove(AppOverlays.menu)
      ..remove(AppOverlays.gameOver)
      ..remove(AppOverlays.pause)
      ..add(AppOverlays.touchControls);
  }

  void togglePause() {
    if (phase.value == GamePhase.menu || phase.value == GamePhase.gameOver) {
      return;
    }

    if (phase.value == GamePhase.playing) {
      phase.value = GamePhase.paused;
      pauseEngine();
      overlays
        ..add(AppOverlays.pause)
        ..remove(AppOverlays.touchControls);
      return;
    }

    phase.value = GamePhase.playing;
    resumeEngine();
    overlays
      ..remove(AppOverlays.pause)
      ..add(AppOverlays.touchControls);
  }

  void endGame() {
    phase.value = GamePhase.gameOver;
    pauseEngine();
    overlays
      ..remove(AppOverlays.pause)
      ..remove(AppOverlays.touchControls)
      ..add(AppOverlays.gameOver);
  }
}
