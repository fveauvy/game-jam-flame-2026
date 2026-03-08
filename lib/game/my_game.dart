import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:game_jam/app/routes.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/utils/time_utils.dart';
import 'package:game_jam/game/camera/camera_controller.dart';
import 'package:game_jam/game/character/generator/character_generator.dart';
import 'package:game_jam/game/character/generator/procedural_character_generator.dart';
import 'package:game_jam/game/character/infra/json_character_pools_repository.dart';
import 'package:game_jam/game/character/infra/seed_code.dart';
import 'package:game_jam/game/character/model/character_generation_state.dart';
import 'package:game_jam/game/character/model/character_profile.dart';
import 'package:game_jam/game/character/pools/character_pools_repository.dart';
import 'package:game_jam/game/components/allies/tadpole.dart';
import 'package:game_jam/game/components/environment/fly_component.dart';
import 'package:game_jam/game/components/player/player_component.dart';
import 'package:game_jam/game/components/player/water_ripple_component.dart';
import 'package:game_jam/game/components/ui/hud_component.dart';
import 'package:game_jam/game/components/ui/menu_component.dart';
import 'package:game_jam/game/game_state.dart';
import 'package:game_jam/game/input/gamepad_input.dart';
import 'package:game_jam/game/input/input_state.dart';
import 'package:game_jam/game/input/keyboard_input.dart';
import 'package:game_jam/game/input/touch_controller.dart';
import 'package:game_jam/game/systems/collision_system.dart';
import 'package:game_jam/game/systems/spawn_system.dart';
import 'package:game_jam/game/world/generated_level.dart';
import 'package:game_jam/game/world/world_root.dart';

enum GamePhase { menu, playing, paused, gameOver, loading }

class MyGame extends FlameGame<WorldRoot>
    with KeyboardEvents, HasGameReference<MyGame>, HasCollisionDetection {
  MyGame({
    CharacterGenerator? characterGenerator,
    CharacterPoolsRepository? characterPoolsRepository,
    String? characterSeedCode,
    Random? random,
  }) : _characterGenerator = characterGenerator,
       _characterPoolsRepository =
           characterPoolsRepository ?? JsonCharacterPoolsRepository(),
       _characterSeedCode = SeedCode.normalize(
         characterSeedCode ?? GameConfig.defaultCharacterSeedCode,
       ),
       _random = random ?? Random(),
       super(
         world: WorldRoot(),
         camera: CameraComponent.withFixedResolution(
           width: GameConfig.baseWidth,
           height: GameConfig.baseHeight,
         ),
       );

  final InputState inputState = InputState();
  late final KeyboardInput keyboardInput;
  late final TouchController touchController;
  late final GamepadInput gamepadInput;
  final ValueNotifier<GamePhase> phase = ValueNotifier<GamePhase>(
    GamePhase.loading,
  );
  final ValueNotifier<CharacterProfile?> characterState =
      ValueNotifier<CharacterProfile?>(null);
  final ValueNotifier<CharacterGenerationState?> characterGenerationState =
      ValueNotifier<CharacterGenerationState?>(null);

  final CharacterGenerator? _characterGenerator;
  final CharacterPoolsRepository _characterPoolsRepository;
  late final Random _random;
  late Random _randomSeeded;

  Random get random => _randomSeeded;

  late final PlayerComponent _player;
  late final WaterRippleComponent _waterRipple;
  bool _isPlayerReady = false;
  late final GameCameraController _cameraController;
  late final GameState gameState;

  int _profileRequestId = 0;
  String _characterSeedCode;

  late GeneratedLevel _level;

  late final MenuComponent _menu;

  String get characterSeedCode => _characterSeedCode;
  CharacterProfile? get generatedCharacterProfile => characterState.value;
  int? get playerRemainingHealth =>
      _isPlayerReady ? _player.remainingHealth : null;
  int? get playerMaxHealth => _isPlayerReady ? _player.maxHealth : null;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await FlameAudio.audioCache.loadAll(['sound_effects/whawhawhawhoua.wav']);

    for (int i = 1; i <= 30; i++) {
      await images.load('gronouy/frog-$i.png');
    }
    _randomSeeded = Random(SeedCode.decode(_characterSeedCode));
    await images.load('water_lily_1.png');
    await images.load('refresh_logo.png');
    await images.load('water_lily.png');
    await images.load('water_lily.png');
    await images.load('plank_dark.png');
    await images.load('plank_light.png');
    await images.load('plank.png');
    await images.load('plank.png');
    await images.load('eggs.png');
    await images.load('fly.png');

    final CharacterGenerationState initialState =
        await _buildCharacterGenerationState(seedCode: _characterSeedCode);
    characterGenerationState.value = initialState;
    characterState.value = initialState.profile;

    _level = GeneratedLevel();
    _player = PlayerComponent(
      speedMultiplier: initialState.profile.traits.speed ?? 1,
      sizeMultiplier: initialState.profile.traits.size ?? 1,
      startPosition: GameConfig.playerSpawn,
      profile: initialState.profile,
      inputState: inputState,
    );
    _isPlayerReady = true;

    _waterRipple = WaterRippleComponent(player: _player);

    final flies = List.generate(
      10,
      (index) => FlyComponent(
        position: Vector2(
          game.random.nextDouble() * GameConfig.worldSize.x,
          game.random.nextDouble() * GameConfig.worldSize.y,
        ),
        size: Vector2.all(32),
      ),
    );

    final eggs = List.generate(
      20,
      (index) => Egg(
        position: Vector2(
          game.random.nextDouble() * GameConfig.worldSize.x,
          game.random.nextDouble() * GameConfig.worldSize.y,
        ),
        size: Vector2.all(32),
      ),
    );

    await world.addAll([
      _level,
      _waterRipple,
      _player,
      SpawnSystem(),
      CollisionSystem(),
      ...flies,
      ...eggs,
    ]);

    world.bindPlayer(_player);

    await camera.viewport.add(HudComponent());

    keyboardInput = KeyboardInput(inputState);
    touchController = TouchController(inputState);
    gamepadInput = GamepadInput(inputState);

    // Initialize gamepad input
    await gamepadInput.initialize();

    _cameraController = GameCameraController(
      camera: camera,
      target: _player,
      worldSize: GameConfig.worldSize,
      viewportSize: Vector2(GameConfig.baseWidth, GameConfig.baseHeight),
    );
    _cameraController.attach();

    _menu = MenuComponent(
      onStart: () async {
        startGame();
      },
      onReroll: () async {
        await rerollCharacter();
      },
    );
    await camera.viewport.add(_menu);

    phase.value = GamePhase.menu;

    gameState = GameState();
  }

  Future<CharacterProfile> generateCharacterProfile({
    required String seedCode,
  }) async {
    final int seed = SeedCode.decode(seedCode);
    final CharacterGenerator generator;
    final CharacterGenerator? injectedGenerator = _characterGenerator;
    if (injectedGenerator != null) {
      generator = injectedGenerator;
    } else {
      final CharacterPools pools = await _characterPoolsRepository.loadPools();
      generator = ProceduralCharacterGenerator(pools: pools);
    }
    return generator.generate(seed: seed);
  }

  Future<void> setCharacterSeedCode(String seedCode) async {
    final String normalizedCode = SeedCode.normalize(seedCode);
    final int requestId = ++_profileRequestId;
    final CharacterGenerationState nextState =
        await _buildCharacterGenerationState(seedCode: normalizedCode);
    if (requestId != _profileRequestId) {
      return;
    }

    _characterSeedCode = normalizedCode;
    _randomSeeded = Random(SeedCode.decode(normalizedCode));
    characterGenerationState.value = nextState;
    characterState.value = nextState.profile;
    if (isLoaded) {
      _player.applyProfile(nextState.profile);
      await _level.onUpdateSeed();
    }
  }

  Future<void> rerollCharacter() async {
    if (phase.value != GamePhase.menu) {
      return;
    }

    String nextCode = _characterSeedCode;
    for (int i = 0; i < 8; i++) {
      final String candidate = SeedCode.randomCode(_random);
      if (candidate != _characterSeedCode) {
        nextCode = candidate;
        break;
      }
    }
    await setCharacterSeedCode(nextCode);
  }

  Future<CharacterGenerationState> _buildCharacterGenerationState({
    required String seedCode,
  }) async {
    final String normalizedCode = SeedCode.normalize(seedCode);
    final int seedInt = SeedCode.decode(normalizedCode);
    final CharacterProfile profile = await generateCharacterProfile(
      seedCode: normalizedCode,
    );
    return CharacterGenerationState(
      seedCode: normalizedCode,
      seedInt: seedInt,
      profile: profile,
    );
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    return keyboardInput.handleEvent(event);
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
    if (phase.value != GamePhase.menu && phase.value != GamePhase.gameOver) {
      return;
    }

    // Hide the menu when the game starts (for example, when tapping the frog).
    camera.viewport.remove(_menu);

    world.reset();
    phase.value = GamePhase.playing;
    resumeEngine();

    overlays
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
    inputState.clearPausePressed();
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

  @override
  bool get debugMode => false;
}
