import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:game_jam/app/routes.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/config/gameplay_tuning.dart';
import 'package:game_jam/core/config/physics_tuning.dart';
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
import 'package:game_jam/game/components/enemies/bird_enemy_component.dart';
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
import 'package:game_jam/game/world/world_mixin.dart';
import 'package:game_jam/game/world/world_root.dart';

enum GamePhase { menu, playing, paused, gameOver, loading }

class MyGame extends FlameGame<WorldRoot>
    with KeyboardEvents, HasGameReference<MyGame> {
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

  @override
  bool get debugMode => false;

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

  late PlayerComponent _player;
  late final List<PlayerComponent> _playerList;
  late final List<WaterRippleComponent> _waterRipples;
  bool _isPlayerReady = false;
  late final GameCameraController _cameraController;
  GameState gameState = GameState();

  int _profileRequestId = 0;
  String _characterSeedCode;
  int _menuNavDirection = 0;
  double _menuNavRepeatTimer = 0;
  bool _bgmStarted = false;

  late GeneratedLevel _level;

  late final MenuComponent _menu;

  String get characterSeedCode => _characterSeedCode;
  CharacterProfile? get generatedCharacterProfile => characterState.value;
  int? get playerRemainingHealth =>
      _isPlayerReady ? _player.remainingHealth : null;
  int? get playerMaxHealth => _isPlayerReady ? _player.maxHealth : null;

  List<PlayerComponent> get playerCandidates => _playerList;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _randomSeeded = Random(SeedCode.decode(_characterSeedCode));

    _level = GeneratedLevel();

    // Frogs generation
    final CharacterGenerationState initialState =
        await _buildCharacterListGenerationState(seedCode: _characterSeedCode);

    characterGenerationState.value = initialState;
    characterState.value = initialState.profile;

    _playerList = _buildInitialFrogs(
      initialState.candidateProfiles,
      inputState,
    );

    // Default selected player is the first candidate.
    _player = _playerList.first;

    // One water ripple component per player.
    _waterRipples = _playerList
        .map((player) => WaterRippleComponent(player: player))
        .toList();

    final bird = BirdEnemyComponent(
      initialPosition: Vector2(180, 920) + Vector2.all(200),
      initialSize: Vector2.all(100),
    );

    await world.add(_level);
    await world.addAll([
      ..._waterRipples,
      ..._playerList,
      SpawnSystem(),
      CollisionSystem(),
      ..._buildInitialFlies(),
      ..._buildInitialEggs(),
      bird,
    ]);

    // Bind the initially selected player.
    world.bindPlayer(_player);
    _isPlayerReady = true;

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
        await _buildCharacterListGenerationState(seedCode: normalizedCode);
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

  Future<CharacterGenerationState> _buildCharacterListGenerationState({
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

  List<PlayerComponent> _buildInitialFrogs(
    List<CharacterProfile> candidateProfiles,
    InputState inputState,
  ) {
    final List<Vector2> safeSpawnPositions =
        WorldMixin.candidateSafeZoneSpawnPositions(
          count: GameplayTuning.menuCharacterCandidateCount,
        );

    return List<PlayerComponent>.generate(
      GameplayTuning.menuCharacterCandidateCount,
      (int index) {
        final CharacterProfile profile = candidateProfiles[index];
        final Vector2 position = safeSpawnPositions[index];

        return PlayerComponent(
          speedMultiplier: profile.traits.speed ?? 1,
          sizeMultiplier: profile.traits.size ?? 1,
          startPosition: position,
          inputState: inputState,
          profile: profile,
        );
      },
    );
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
        position: _randomEggPosition(),
        size: Vector2.all(GameplayTuning.worldPickupSize),
      ),
    );
  }

  Vector2 _randomEggPosition() {
    for (int i = 0; i < GameplayTuning.eggSpawnMaxRetries; i++) {
      final Vector2 candidate = Vector2(
        (random.nextDouble() * GameConfig.worldSize.x).clamp(
          PhysicsTuning.playerBaseSize,
          GameConfig.worldSize.x - PhysicsTuning.playerBaseSize,
        ),
        (random.nextDouble() * GameConfig.worldSize.y).clamp(
          PhysicsTuning.playerBaseSize,
          GameConfig.worldSize.y - PhysicsTuning.playerBaseSize,
        ),
      );
      if (!_level.isPositionOnThorn(candidate)) {
        return candidate;
      }
    }
    return GameConfig.playerSpawn.clone();
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

  /// Rebuilds all menu candidate frogs and their water ripples from the
  /// current [characterGenerationState]. Called when returning to the menu
  /// after a play session, since [_cleanupMenuCandidates] removed all but the
  /// active player.
  Future<void> _rebuildMenuCandidates() async {
    final CharacterGenerationState? state = characterGenerationState.value;
    if (state == null) {
      return;
    }

    // Drop whatever is left in the lists from the previous session.
    for (final PlayerComponent p in List<PlayerComponent>.from(_playerList)) {
      p.removeFromParent();
    }
    _playerList.clear();

    for (final WaterRippleComponent r in List<WaterRippleComponent>.from(
      _waterRipples,
    )) {
      r.removeFromParent();
    }
    _waterRipples.clear();

    // Rebuild players and ripples from the freshly-generated profiles.
    final List<PlayerComponent> newPlayers = _buildInitialFrogs(
      state.candidateProfiles,
      inputState,
    );
    final List<WaterRippleComponent> newRipples = newPlayers
        .map((PlayerComponent p) => WaterRippleComponent(player: p))
        .toList();

    _playerList.addAll(newPlayers);
    _waterRipples.addAll(newRipples);

    _player = _playerList.first;
    world.bindPlayer(_player);
    _cameraController.target = _player;

    await world.addAll([..._waterRipples, ..._playerList]);
  }

  /// Called when a player candidate frog is tapped in the menu.
  void onPlayerTapped(PlayerComponent tapped) {
    if (phase.value != GamePhase.menu) {
      return;
    }

    final int index = _playerList.indexOf(tapped);
    if (index == -1) {
      return;
    }

    // Update the selected candidate in the generation state.
    pointCharacterCandidate(index);

    // Switch the active player reference and make the camera follow it.
    _player = tapped;
    world.bindPlayer(_player);
    _cameraController.target = _player;

    // Start the game with this selected player.
    // startGame() will handle removing the other candidates.
    startGame();
  }

  /// Removes all non-active player candidates and their water ripples from the
  /// world. Called once when transitioning from menu to playing, regardless of
  /// whether the game was started via tap or keyboard.
  void _cleanupMenuCandidates() {
    for (final PlayerComponent player in List<PlayerComponent>.from(
      _playerList,
    )) {
      if (player != _player) {
        player.removeFromParent();
      }
    }
    _playerList.removeWhere((PlayerComponent p) => p != _player);

    for (final WaterRippleComponent ripple in List<WaterRippleComponent>.from(
      _waterRipples,
    )) {
      if (ripple.player != _player) {
        ripple.removeFromParent();
      }
    }
    _waterRipples.removeWhere((WaterRippleComponent r) => r.player != _player);
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
    if (phase.value == GamePhase.playing) {
      gameState.elapsedTimeInMs += (dt * 1000).toInt();
    }
    _cameraController.update();
    inputState.clearTransient();
  }

  void startGame() {
    if (phase.value != GamePhase.menu && phase.value != GamePhase.gameOver) {
      return;
    }

    _startBgmIfNeeded();

    // Hide the menu and remove non-selected candidates when the game starts.
    if (phase.value == GamePhase.menu) {
      if (isLoaded && _menu.parent != null) {
        camera.viewport.remove(_menu);
      }
      _cleanupMenuCandidates();
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

  void _startBgmIfNeeded() {
    if (_bgmStarted) {
      return;
    }
    _bgmStarted = true;
    unawaited(
      FlameAudio.bgm.play('mud-ambient.mp3', volume: .25).catchError((error) {
        _bgmStarted = false;
        debugPrint('[audio] bgm start failed: $error');
      }),
    );
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

  Future<void> restartToMenu() async {
    if (phase.value != GamePhase.paused && phase.value != GamePhase.gameOver) {
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

    // Re-show the menu overlay.
    if (isLoaded && _menu.parent == null) {
      await camera.viewport.add(_menu);
    }

    if (isLoaded) {
      // Reroll picks new profiles into characterGenerationState, then
      // _rebuildMenuCandidates spawns the full frog carousel from those profiles.
      await rerollCharacter();
      await _rebuildMenuCandidates();
    }
  }
}
