import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:game_jam/app/routes.dart';
import 'package:game_jam/audio/audio_settings.dart';
import 'package:game_jam/audio/audio_settings_store.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/config/gameplay_tuning.dart';
import 'package:game_jam/core/config/physics_tuning.dart';
import 'package:game_jam/core/leaderboard/leaderboard_client.dart';
import 'package:game_jam/core/utils/time_utils.dart';
import 'package:game_jam/game/camera/camera_controller.dart';
import 'package:game_jam/game/character/generator/character_generator.dart';
import 'package:game_jam/game/character/generator/procedural_character_generator.dart';
import 'package:game_jam/game/character/infra/json_character_pools_repository.dart';
import 'package:game_jam/game/character/infra/seed_code.dart';
import 'package:game_jam/game/character/model/character_generation_state.dart';
import 'package:game_jam/game/character/model/character_profile.dart';
import 'package:game_jam/game/character/pools/character_pools_repository.dart';
import 'package:game_jam/game/components/allies/egg_component.dart';
import 'package:game_jam/game/components/enemies/bird/bird_component.dart';
import 'package:game_jam/game/components/environment/fly_component.dart';
import 'package:game_jam/game/components/environment/frog_house_component.dart';
import 'package:game_jam/game/components/environment/water_shader_layer.dart';
import 'package:game_jam/game/components/player/player_component.dart';
import 'package:game_jam/game/components/player/water_ripple_component.dart';
import 'package:game_jam/game/components/ui/hud_component.dart';
import 'package:game_jam/game/components/ui/menu_component.dart';
import 'package:game_jam/game/game_state.dart';
import 'package:game_jam/game/input/gamepad_input.dart';
import 'package:game_jam/game/input/input_state.dart';
import 'package:game_jam/game/input/keyboard_input.dart';
import 'package:game_jam/game/input/touch_controller.dart';
import 'package:game_jam/game/world/generated_level.dart';
import 'package:game_jam/game/world/world_mixin.dart';
import 'package:game_jam/game/world/world_root.dart';

enum GamePhase { intro, menu, playing, paused, gameOver, loading, win }

class MyGame extends FlameGame<WorldRoot>
    with KeyboardEvents, HasGameReference<MyGame> {
  MyGame({
    CharacterGenerator? characterGenerator,
    CharacterPoolsRepository? characterPoolsRepository,
    String? characterSeedCode,
    Random? random,
    LeaderboardClient leaderboardClient = const LeaderboardClient(),
  }) : _characterGenerator = characterGenerator,
       _characterPoolsRepository =
           characterPoolsRepository ?? JsonCharacterPoolsRepository(),
       _characterSeedCode = SeedCode.normalize(
         characterSeedCode ?? GameConfig.defaultCharacterSeedCode,
       ),
       _random = random ?? Random(),
       _leaderboardClient = leaderboardClient,
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
  final ValueNotifier<AudioSettings> audioSettings =
      ValueNotifier<AudioSettings>(AudioSettings.defaults);
  final ValueNotifier<bool> gamepadConnected = ValueNotifier<bool>(false);

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
  late final BirdComponent _birdEnemy;
  GameState gameState = GameState();

  int _profileRequestId = 0;
  String _characterSeedCode;
  int _menuNavDirection = 0;
  double _menuNavRepeatTimer = 0;
  bool _bgmStarted = false;
  bool _awaitingWebAudioGesture = false;
  bool _webAudioAutoplayWarningLogged = false;
  AudioPlayer? _gameplayMusicPlayer;
  AudioPlayer? _victoryMusicPlayer;
  int? _winningRunElapsedTimeInMs;
  final AudioSettingsStore _audioSettingsStore = AudioSettingsStore();
  final LeaderboardClient _leaderboardClient;
  static const String _menuBgmAsset = 'mud-ambient.mp3';
  static const String _gameplayBgmAsset = 'music.mp3';
  static const String _victoryBgmAsset = AssetPaths.victoryMusic;
  static const double _menuHoverSfxVolume = 0.45;
  static const double _menuSelectSfxVolume = 0.7;

  late GeneratedLevel _level;

  late final MenuComponent _menu;

  String get characterSeedCode => _characterSeedCode;
  GeneratedLevel get level => _level;
  CharacterProfile? get generatedCharacterProfile => characterState.value;
  int? get playerRemainingHealth =>
      _isPlayerReady ? _player.remainingHealth : null;
  int? get playerMaxHealth => _isPlayerReady ? _player.maxHealth : null;
  int? get playerMoistureLevel => _isPlayerReady ? _player.moistureLevel : null;
  AudioSettings get currentAudioSettings => audioSettings.value;
  int? get winningRunElapsedTimeInMs => _winningRunElapsedTimeInMs;
  String get winningRunFormattedTime {
    final int? elapsed = _winningRunElapsedTimeInMs;
    if (elapsed == null) {
      return '--:--';
    }
    return _formatElapsedTime(elapsed);
  }

  List<PlayerComponent> get playerCandidates => _playerList;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadAudioSettings();

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

    _birdEnemy = BirdComponent(
      position: Vector2(GameConfig.worldSize.x - 200, 100),
      size: Vector2(200, 100),
    );

    await world.add(_level);
    await world.addAll([
      WaterShaderLayer(level: _level),
      ..._waterRipples,
      ..._playerList,
      ..._buildInitialFlies(),
      _buildInitialWoodBoards(),
      _birdEnemy,
    ]);

    // Bind the initially selected player.
    world.bindPlayer(_player);
    _isPlayerReady = true;

    await camera.viewport.add(HudComponent());

    keyboardInput = KeyboardInput(inputState);
    touchController = TouchController(inputState);
    gamepadInput = GamepadInput(inputState, connectionState: gamepadConnected);

    // Initialize gamepad input
    await gamepadInput.initialize();

    _cameraController = GameCameraController(
      viewportSize: Vector2(GameConfig.baseWidth, GameConfig.baseHeight),
      target: PositionComponent(position: GameConfig.playerSpawn),
      worldSize: GameConfig.worldSize,
      camera: camera,
    );

    _cameraController.attach();

    _menu = MenuComponent(onReroll: rerollCharacter);

    phase.value = GamePhase.intro;
    _startBgmIfNeeded();

    gameState = GameState();
  }

  Future<void> _loadAudioSettings() async {
    final AudioSettings settings = await _audioSettingsStore.load();
    audioSettings.value = settings;
    _applyAudioSettings();
  }

  Future<void> toggleMute() async {
    await _setAudioSettings(
      audioSettings.value.copyWith(muted: !audioSettings.value.muted),
    );
  }

  Future<void> setMasterVolume(double value) async {
    await _setAudioSettings(audioSettings.value.copyWith(masterVolume: value));
  }

  Future<void> setMusicVolume(double value) async {
    await _setAudioSettings(audioSettings.value.copyWith(musicVolume: value));
  }

  Future<void> setSfxVolume(double value) async {
    await _setAudioSettings(audioSettings.value.copyWith(sfxVolume: value));
  }

  Future<void> _setAudioSettings(AudioSettings settings) async {
    audioSettings.value = settings;
    _applyAudioSettings();
    await _audioSettingsStore.save(settings);
  }

  Future<void> playSfx(String asset, {double volume = 1.0}) async {
    final double effectiveVolume =
        (audioSettings.value.effectiveSfxVolume * volume).clamp(0.0, 1.0);
    if (effectiveVolume <= 0) {
      return;
    }
    await FlameAudio.play(asset, volume: effectiveVolume);
  }

  void _applyAudioSettings() {
    if (!_bgmStarted) {
      return;
    }

    final double volume = audioSettings.value.effectiveMusicVolume;
    if (phase.value == GamePhase.win) {
      unawaited(_stopAmbientBgm());
      unawaited(_stopGameplayMusic());
      unawaited(_syncVictoryMusic(volume));
      return;
    }

    unawaited(_stopVictoryMusic());
    unawaited(_syncAmbientBgm(volume));
    unawaited(_syncGameplayMusic(volume));
  }

  Future<void> _stopAmbientBgm() async {
    if (!FlameAudio.bgm.isPlaying) {
      return;
    }
    await FlameAudio.bgm.stop();
  }

  Future<void> _syncAmbientBgm(double volume) async {
    if (!FlameAudio.bgm.isPlaying) {
      await FlameAudio.bgm.play(_menuBgmAsset, volume: volume).catchError((
        error,
      ) {
        if (_handleWebAutoplayError(error)) {
          return;
        }
        debugPrint('[audio] bgm sync failed: $error');
      });
      return;
    }

    await FlameAudio.bgm.audioPlayer.setVolume(volume);
  }

  Future<void> _syncGameplayMusic(double volume) async {
    final bool shouldKeepGameplayMusic =
        phase.value == GamePhase.playing || phase.value == GamePhase.paused;
    if (!shouldKeepGameplayMusic || volume <= 0) {
      await _stopGameplayMusic();
      return;
    }

    final AudioPlayer? player = _gameplayMusicPlayer;
    if (player == null) {
      try {
        _gameplayMusicPlayer = await FlameAudio.loopLongAudio(
          _gameplayBgmAsset,
          volume: volume,
        );
      } catch (error) {
        if (_handleWebAutoplayError(error)) {
          return;
        }
        debugPrint('[audio] gameplay music start failed: $error');
      }
      return;
    }

    await player.setVolume(volume);
  }

  Future<void> _stopGameplayMusic() async {
    final AudioPlayer? player = _gameplayMusicPlayer;
    if (player == null) {
      return;
    }
    await player.stop();
    await player.dispose();
    _gameplayMusicPlayer = null;
  }

  Future<void> _syncVictoryMusic(double volume) async {
    if (volume <= 0) {
      await _stopVictoryMusic();
      return;
    }

    final AudioPlayer? player = _victoryMusicPlayer;
    if (player == null) {
      try {
        _victoryMusicPlayer = await FlameAudio.loopLongAudio(
          _victoryBgmAsset,
          volume: volume,
        );
      } catch (error) {
        if (_handleWebAutoplayError(error)) {
          return;
        }
        debugPrint('[audio] victory music start failed: $error');
      }
      return;
    }

    await player.setVolume(volume);
  }

  Future<void> _stopVictoryMusic() async {
    final AudioPlayer? player = _victoryMusicPlayer;
    if (player == null) {
      return;
    }
    await player.stop();
    await player.dispose();
    _victoryMusicPlayer = null;
  }

  Future<bool> publishWinningScore(String playerName) async {
    final String normalizedName = playerName.trim();
    final int? score =
        _winningRunElapsedTimeInMs ??
        (phase.value == GamePhase.win ? gameState.elapsedTimeInMs : null);
    if (normalizedName.isEmpty || score == null) {
      return false;
    }

    return _leaderboardClient.submitScore(
      playerName: normalizedName,
      elapsedTimeInMs: score,
      seedCode: _characterSeedCode,
    );
  }

  Future<void> retrySeedFromWin() async {
    await _restartRunFromWin();
  }

  Future<void> restartWithNewSeedFromWin() async {
    await _restartRunFromWin(useNewSeed: true);
  }

  Future<void> _restartRunFromWin({
    bool useNewSeed = false,
    String? seedCode,
  }) async {
    if (phase.value != GamePhase.win) {
      return;
    }

    phase.value = GamePhase.menu;
    _applyAudioSettings();
    _resetMenuInputState();
    _resetRunState();
    resumeEngine();
    overlays
      ..remove(AppOverlays.pause)
      ..remove(AppOverlays.touchControls)
      ..remove(AppOverlays.gameOver)
      ..remove(AppOverlays.winOverlay);

    if (isLoaded && _menu.parent == null) {
      await world.add(_menu);
    }

    if (isLoaded) {
      final String normalizedSeed = (seedCode ?? '').trim();
      if (normalizedSeed.isNotEmpty) {
        await setCharacterSeedCode(normalizedSeed);
        await _rebuildMenuCandidates();
      } else if (useNewSeed) {
        await rerollCharacter();
      } else {
        await _rebuildMenuCandidates();
      }

      _cameraController.target = PositionComponent(
        position: GameConfig.playerSpawn,
      );
    }

    startGame();
  }

  bool _handleWebAutoplayError(Object error) {
    if (!kIsWeb) {
      return false;
    }
    final String value = error.toString().toLowerCase();
    final bool isAutoplayBlock =
        value.contains('audiocontext') ||
        value.contains('notallowederror') ||
        value.contains('user gesture') ||
        value.contains('autoplay');
    if (!isAutoplayBlock) {
      return false;
    }

    _awaitingWebAudioGesture = true;
    if (!_webAudioAutoplayWarningLogged) {
      _webAudioAutoplayWarningLogged = true;
      debugPrint('[audio] autoplay blocked, retry on first user gesture');
    }
    return true;
  }

  void notifyUserGesture() {
    if (!isLoaded) {
      return;
    }
    unawaited(gamepadInput.notifyUserGesture());
    if (!_awaitingWebAudioGesture) {
      return;
    }
    _awaitingWebAudioGesture = false;
    _webAudioAutoplayWarningLogged = false;
    _applyAudioSettings();
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

  Future<void> setMenuSeedCode(String seedCode) async {
    if (phase.value != GamePhase.menu) {
      return;
    }
    await setCharacterSeedCode(seedCode);
    if (isLoaded) {
      await _rebuildMenuCandidates();
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

    if (isLoaded) {
      await _rebuildMenuCandidates();
    }
  }

  Future<CharacterGenerationState> _buildCharacterListGenerationState({
    required String seedCode,
  }) async {
    final String normalizedCode = SeedCode.normalize(seedCode);
    final int seedInt = SeedCode.decode(normalizedCode);
    final List<String> candidateSeedCodes = <String>[];
    final List<CharacterProfile> candidateProfiles = <CharacterProfile>[];
    final Set<String> usedSpriteIds = <String>{};
    final Set<String> usedAdjectives = <String>{};
    final Set<String> usedTitles = <String>{};
    final Set<String> usedDisplayNames = <String>{};

    int index = 0;
    while (index < GameplayTuning.menuCharacterCandidateUniqueAttempts &&
        candidateProfiles.length < GameplayTuning.menuCharacterCandidateCount) {
      final String code = _candidateSeedCode(seedInt: seedInt, index: index);
      final CharacterProfile profile = await generateCharacterProfile(
        seedCode: code,
      );
      if (_canAcceptPreferredCandidate(
        profile: profile,
        usedSpriteIds: usedSpriteIds,
        usedAdjectives: usedAdjectives,
        usedTitles: usedTitles,
        usedDisplayNames: usedDisplayNames,
      )) {
        _rememberPreferredCandidate(
          profile: profile,
          usedSpriteIds: usedSpriteIds,
          usedAdjectives: usedAdjectives,
          usedTitles: usedTitles,
          usedDisplayNames: usedDisplayNames,
        );
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

  bool _canAcceptPreferredCandidate({
    required CharacterProfile profile,
    required Set<String> usedSpriteIds,
    required Set<String> usedAdjectives,
    required Set<String> usedTitles,
    required Set<String> usedDisplayNames,
  }) {
    if (usedSpriteIds.contains(profile.spriteId)) {
      return false;
    }

    final String adjective = _normalizeNameKey(profile.name.adjective);
    if (adjective.isNotEmpty && usedAdjectives.contains(adjective)) {
      return false;
    }

    final String title = _normalizeNameKey(profile.name.title);
    if (title.isNotEmpty && usedTitles.contains(title)) {
      return false;
    }

    final String displayName = _normalizeNameKey(profile.name.display);
    if (displayName.isNotEmpty && usedDisplayNames.contains(displayName)) {
      return false;
    }

    return true;
  }

  void _rememberPreferredCandidate({
    required CharacterProfile profile,
    required Set<String> usedSpriteIds,
    required Set<String> usedAdjectives,
    required Set<String> usedTitles,
    required Set<String> usedDisplayNames,
  }) {
    usedSpriteIds.add(profile.spriteId);

    final String adjective = _normalizeNameKey(profile.name.adjective);
    if (adjective.isNotEmpty) {
      usedAdjectives.add(adjective);
    }

    final String title = _normalizeNameKey(profile.name.title);
    if (title.isNotEmpty) {
      usedTitles.add(title);
    }

    final String displayName = _normalizeNameKey(profile.name.display);
    if (displayName.isNotEmpty) {
      usedDisplayNames.add(displayName);
    }
  }

  String _normalizeNameKey(String? value) {
    return (value ?? '').trim().toLowerCase();
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

  FrogHouseComponent _buildInitialWoodBoards() {
    return FrogHouseComponent(
      position:
          GameConfig.playerSpawn -
          Vector2.all(PhysicsTuning.frogHousePositionOffset),
      size: Vector2.all(PhysicsTuning.frogHouseSize),
    );
  }

  static bool isValidEggSpawnPosition({
    required bool isOnThorn,
    required bool isOnLeaf,
  }) {
    return !isOnThorn && !isOnLeaf;
  }

  Future<void> _resetWorldPopulation() async {
    final List<EggComponent> eggs = world.children
        .whereType<EggComponent>()
        .toList();
    final List<FlyComponent> flies = world.children
        .whereType<FlyComponent>()
        .toList();

    for (final EggComponent egg in eggs) {
      egg.removeFromParent();
    }
    for (final FlyComponent fly in flies) {
      fly.removeFromParent();
    }
    final frogHouse = world.children
        .whereType<FrogHouseComponent>()
        .firstOrNull;
    for (final egg
        in frogHouse?.children.whereType<EggComponent>() ?? <EggComponent>[]) {
      egg.removeFromParent();
    }

    await _level.onUpdateSeed();
    await world.addAll([..._buildInitialFlies()]);
  }

  void _resetRunState() {
    gameState.reset();
    world.reset();
    if (isLoaded) {
      _birdEnemy.resetForNewRun();
    }
    if (isLoaded) {
      unawaited(_resetWorldPopulation());
    }
  }

  void pointCharacterCandidate(int index, {bool withSfx = true}) {
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
    if (withSfx) {
      unawaited(_playRandomMenuFrogVoice(volume: _menuHoverSfxVolume));
    }
  }

  Future<void> _playRandomMenuFrogVoice({required double volume}) async {
    if (phase.value != GamePhase.menu) {
      return;
    }
    final List<String> sfx = AssetPaths.frogMenuVoiceSfx;
    if (sfx.isEmpty) {
      return;
    }
    await playSfx(sfx[_random.nextInt(sfx.length)], volume: volume);
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
    pointCharacterCandidate(index, withSfx: false);
    unawaited(_playRandomMenuFrogVoice(volume: _menuSelectSfxVolume));

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

    if (phase.value == GamePhase.intro) {
      if (inputState.confirmPressed || inputState.jumpPressed) {
        unawaited(continueFromIntro());
      }
    }

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

    final CharacterGenerationState? state = characterGenerationState.value;

    if (phase.value == GamePhase.menu &&
        state != null &&
        state.selectedIndex >= 0 &&
        state.selectedIndex < _playerList.length) {
      _player = _playerList[state.selectedIndex];
      world.bindPlayer(_player);
      _cameraController.target = _player;
    }

    // Hide the menu and remove non-selected candidates when the game starts.
    if (phase.value == GamePhase.menu) {
      if (isLoaded && _menu.parent != null) {
        world.remove(_menu);
      }
      _cleanupMenuCandidates();
    }

    if (state != null) {
      _characterSeedCode = state.selectedSeedCode;
      _randomSeeded = Random(SeedCode.decode(_characterSeedCode));
      characterState.value = state.profile;
      if (isLoaded) {
        _player.applyProfile(state.profile);
      }
    }

    _resetRunState();
    _winningRunElapsedTimeInMs = null;
    phase.value = GamePhase.playing;
    _applyAudioSettings();
    resumeEngine();

    overlays
      ..remove(AppOverlays.gameOver)
      ..remove(AppOverlays.pause)
      ..add(AppOverlays.touchControls);
  }

  Future<void> continueFromIntro() async {
    if (phase.value != GamePhase.intro) {
      return;
    }

    phase.value = GamePhase.menu;
    _resetMenuInputState();

    if (isLoaded && _menu.parent == null) {
      await world.add(_menu);
    }
  }

  void _startBgmIfNeeded() {
    if (_bgmStarted) {
      return;
    }
    _bgmStarted = true;
    _applyAudioSettings();
  }

  void togglePause() {
    if (phase.value == GamePhase.intro ||
        phase.value == GamePhase.menu ||
        phase.value == GamePhase.gameOver) {
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
    _applyAudioSettings();
    inputState.clearPausePressed();
    resumeEngine();
    overlays
      ..remove(AppOverlays.pause)
      ..add(AppOverlays.touchControls);
  }

  void endGame() {
    phase.value = GamePhase.gameOver;
    _applyAudioSettings();
    pauseEngine();
    overlays
      ..remove(AppOverlays.pause)
      ..remove(AppOverlays.touchControls)
      ..add(AppOverlays.gameOver);
  }

  void winGame() {
    _winningRunElapsedTimeInMs = gameState.elapsedTimeInMs;
    phase.value = GamePhase.win;
    _applyAudioSettings();
    pauseEngine();
    overlays
      ..remove(AppOverlays.pause)
      ..remove(AppOverlays.touchControls)
      ..add(AppOverlays.winOverlay);
  }

  Future<void> restartToMenu() async {
    if (phase.value != GamePhase.paused &&
        phase.value != GamePhase.gameOver &&
        phase.value != GamePhase.win) {
      return;
    }

    phase.value = GamePhase.menu;
    _applyAudioSettings();
    _resetMenuInputState();
    _resetRunState();
    resumeEngine();
    overlays
      ..remove(AppOverlays.pause)
      ..remove(AppOverlays.touchControls)
      ..remove(AppOverlays.gameOver)
      ..remove(AppOverlays.winOverlay);

    // Re-show the menu overlay.
    if (isLoaded && _menu.parent == null) {
      await world.add(_menu);
    }

    if (isLoaded) {
      await _rebuildMenuCandidates();

      _cameraController.target = PositionComponent(
        position: GameConfig.playerSpawn,
      );
    }
  }

  void _resetMenuInputState() {
    inputState.moveAxisX = 0;
    inputState.moveAxisY = 0;
    inputState.clearTransient();
    _menuNavDirection = 0;
    _menuNavRepeatTimer = 0;
  }

  String _formatElapsedTime(int elapsedTimeInMs) {
    final int totalSeconds = elapsedTimeInMs ~/ 1000;
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
