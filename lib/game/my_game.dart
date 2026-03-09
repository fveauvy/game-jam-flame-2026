import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:game_jam/app/routes.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/config/gameplay_tuning.dart';
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
import 'package:game_jam/game/game_state.dart';
import 'package:game_jam/game/input/gamepad_input.dart';
import 'package:game_jam/game/input/input_state.dart';
import 'package:game_jam/game/input/keyboard_input.dart';
import 'package:game_jam/game/input/touch_controller.dart';
import 'package:game_jam/game/systems/collision_system.dart';
import 'package:game_jam/game/systems/spawn_system.dart';
import 'package:game_jam/game/world/generated_level.dart';
import 'package:game_jam/game/world/world_root.dart';

enum GamePhase { menu, playing, paused, gameOver }

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
    GamePhase.menu,
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
  final GameState gameState = GameState();

  int _profileRequestId = 0;
  String _characterSeedCode;
  int _menuNavDirection = 0;
  double _menuNavRepeatTimer = 0;

  late GeneratedLevel _level;

  String get characterSeedCode => _characterSeedCode;
  CharacterProfile? get generatedCharacterProfile => characterState.value;
  int? get playerRemainingHealth =>
      _isPlayerReady ? _player.remainingHealth : null;
  int? get playerMaxHealth => _isPlayerReady ? _player.maxHealth : null;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _randomSeeded = Random(SeedCode.decode(_characterSeedCode));

    final CharacterGenerationState initialState =
        await _buildCharacterGenerationState(seedCode: _characterSeedCode);
    characterGenerationState.value = initialState;
    characterState.value = initialState.profile;

    _level = GeneratedLevel();
    _player = PlayerComponent(
      inputState: inputState,
      profile: initialState.profile,
      startPosition: GameConfig.playerSpawn,
      speedMultiplier: initialState.profile.traits.speed ?? 1,
      sizeMultiplier: initialState.profile.traits.size ?? 1,
    );
    _isPlayerReady = true;

    _waterRipple = WaterRippleComponent(player: _player);

    await world.addAll([
      _level,
      _waterRipple,
      _player,
      SpawnSystem(),
      CollisionSystem(),
      ..._buildInitialFlies(),
      ..._buildInitialEggs(),
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
    for (int i = 0; i < GameplayTuning.characterRerollAttempts; i++) {
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
    final List<String> candidateSeedCodes = <String>[];
    final List<CharacterProfile> candidateProfiles = <CharacterProfile>[];
    final Set<String> usedSpriteIds = <String>{};

    int index = 0;
    while (index < GameplayTuning.menuCharacterCandidateUniqueAttempts &&
        candidateProfiles.length < GameplayTuning.menuCharacterCandidateCount) {
      final String code = _candidateSeedCode(seedInt: seedInt, index: index);
      final CharacterProfile profile = await generateCharacterProfile(
        seedCode: code,
      );
      if (usedSpriteIds.add(profile.spriteId)) {
        candidateSeedCodes.add(code);
        candidateProfiles.add(profile);
      }
      index++;
    }

    while (candidateProfiles.length <
        GameplayTuning.menuCharacterCandidateCount) {
      final String code = _candidateSeedCode(seedInt: seedInt, index: index);
      final CharacterProfile profile = await generateCharacterProfile(
        seedCode: code,
      );
      candidateSeedCodes.add(code);
      candidateProfiles.add(profile);
      index++;
    }

    return CharacterGenerationState(
      seedCode: normalizedCode,
      seedInt: seedInt,
      candidateSeedCodes: candidateSeedCodes,
      candidateProfiles: candidateProfiles,
      selectedIndex: 0,
    );
  }

  String _candidateSeedCode({required int seedInt, required int index}) {
    final int candidateSeed =
        (seedInt + (index * GameplayTuning.menuCharacterCandidateSeedStep)) %
        SeedCode.maxValueExclusive;
    return SeedCode.encode(candidateSeed);
  }

  List<FlyComponent> _buildInitialFlies() {
    return List<FlyComponent>.generate(
      GameplayTuning.initialFlyCount,
      (int index) => FlyComponent(
        position: Vector2(
          random.nextDouble() * GameConfig.worldSize.x,
          random.nextDouble() * GameConfig.worldSize.y,
        ),
        size: Vector2.all(GameplayTuning.worldPickupSize),
      ),
    );
  }

  List<Egg> _buildInitialEggs() {
    return List<Egg>.generate(
      GameplayTuning.initialEggCount,
      (int index) => Egg(
        position: Vector2(
          random.nextDouble() * GameConfig.worldSize.x,
          random.nextDouble() * GameConfig.worldSize.y,
        ),
        size: Vector2.all(GameplayTuning.worldPickupSize),
      ),
    );
  }

  Future<void> _resetWorldPopulation() async {
    final List<Egg> eggs = world.children.whereType<Egg>().toList();
    final List<FlyComponent> flies = world.children
        .whereType<FlyComponent>()
        .toList();
    for (final Egg egg in eggs) {
      egg.removeFromParent();
    }
    for (final FlyComponent fly in flies) {
      fly.removeFromParent();
    }
    await world.addAll([..._buildInitialFlies(), ..._buildInitialEggs()]);
  }

  void _resetRunState() {
    gameState.reset();
    world.reset();
    if (isLoaded) {
      unawaited(_resetWorldPopulation());
    }
  }

  void pointCharacterCandidate(int index) {
    final CharacterGenerationState? state = characterGenerationState.value;
    if (state == null || index < 0 || index >= state.candidateProfiles.length) {
      return;
    }
    if (index == state.selectedIndex) {
      return;
    }
    final CharacterGenerationState nextState = state.copyWith(
      selectedIndex: index,
    );
    characterGenerationState.value = nextState;
    characterState.value = nextState.profile;
    if (isLoaded) {
      _player.applyProfile(nextState.profile);
    }
  }

  void _stepMenuCandidate(int delta) {
    final CharacterGenerationState? state = characterGenerationState.value;
    if (state == null || state.candidateProfiles.isEmpty) {
      return;
    }
    final int count = state.candidateProfiles.length;
    final int next = (state.selectedIndex + delta) % count;
    pointCharacterCandidate(next < 0 ? next + count : next);
  }

  void _updateMenuNavigation(double dt) {
    final double x = inputState.moveAxisX;
    final double y = inputState.moveAxisY;
    int direction = 0;
    if (x >= GameplayTuning.menuNavigationAxisThreshold ||
        y <= -GameplayTuning.menuNavigationAxisThreshold) {
      direction = 1;
    } else if (x <= -GameplayTuning.menuNavigationAxisThreshold ||
        y >= GameplayTuning.menuNavigationAxisThreshold) {
      direction = -1;
    }

    if (direction == 0) {
      _menuNavDirection = 0;
      _menuNavRepeatTimer = 0;
      return;
    }

    if (direction != _menuNavDirection) {
      _menuNavDirection = direction;
      _menuNavRepeatTimer = 0;
      _stepMenuCandidate(direction);
      return;
    }

    _menuNavRepeatTimer += dt;
    if (_menuNavRepeatTimer >=
        GameplayTuning.menuNavigationRepeatIntervalSeconds) {
      _menuNavRepeatTimer = 0;
      _stepMenuCandidate(direction);
    }
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

    if (phase.value == GamePhase.menu) {
      _updateMenuNavigation(dt);
      if (inputState.confirmPressed) {
        startGame();
      }
    }

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

    final CharacterGenerationState? state = characterGenerationState.value;
    if (state != null) {
      _characterSeedCode = state.selectedSeedCode;
      _randomSeeded = Random(SeedCode.decode(_characterSeedCode));
      characterState.value = state.profile;
      if (isLoaded) {
        _player.applyProfile(state.profile);
      }
    }

    _resetRunState();
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

  void restartToMenu() {
    if (phase.value != GamePhase.paused) {
      return;
    }

    phase.value = GamePhase.menu;
    inputState.clearPausePressed();
    _resetRunState();
    resumeEngine();
    overlays
      ..remove(AppOverlays.pause)
      ..remove(AppOverlays.touchControls)
      ..remove(AppOverlays.gameOver);

    if (isLoaded) {
      unawaited(rerollCharacter());
    }
  }
}
