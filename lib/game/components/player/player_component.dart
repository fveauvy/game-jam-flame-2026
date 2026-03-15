import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/core/config/gameplay_tuning.dart';
import 'package:game_jam/core/config/physics_tuning.dart';
import 'package:game_jam/core/entities/player_vertical_position.dart';
import 'package:game_jam/game/character/model/character_profile.dart';
import 'package:game_jam/game/components/allies/egg_component.dart';
import 'package:game_jam/game/components/environment/fly_component.dart';
import 'package:game_jam/game/components/environment/frog_house_component.dart';
import 'package:game_jam/game/components/environment/ground_component.dart';
import 'package:game_jam/game/components/environment/thorn_component.dart';
import 'package:game_jam/game/components/environment/water_component.dart';
import 'package:game_jam/game/components/environment/water_lily_component.dart';
import 'package:game_jam/game/components/player/frog_tongue_component.dart';
import 'package:game_jam/game/components/player/player_animation_extention.dart';
import 'package:game_jam/game/components/text/simple_text_component.dart';
import 'package:game_jam/game/input/input_state.dart';
import 'package:game_jam/game/my_game.dart';

class PlayerComponent extends SpriteAnimationComponent
    with
        HasGameReference<MyGame>,
        CollisionCallbacks,
        TapCallbacks,
        HoverCallbacks {
  PlayerComponent({
    required this.inputState,
    required CharacterProfile profile,
    required Vector2 startPosition,
    double speedMultiplier = 1.0,
    double sizeMultiplier = 1.0,
  }) : _startPosition = startPosition.clone(),
       _profile = profile,
       _baseSpeedMultiplier = speedMultiplier,
       _baseSizeMultiplier = sizeMultiplier,
       moistureLevel = GameplayTuning.initialMoistureLevel,
       super(
         position: startPosition.clone(),
         size: Vector2.all(PhysicsTuning.playerBaseSize),
         anchor: Anchor.center,
         priority: 110,
       ) {
    _applyStatsFromProfile();
    previousPosition = inputState.playerVerticalPosition;
  }

  static const Duration _damageTextDuration = Duration(seconds: 1);
  static const Duration _dryingDelay = Duration(milliseconds: 500);
  static const int _defaultHealth = 100;
  static const double _hitboxRadiusFactor = 1 / 2;
  static const double _forcedSeparationThreshold = 1.5;
  static ui.FragmentProgram? _frogOutlineProgram;
  static Future<ui.FragmentProgram>? _frogOutlineProgramLoader;

  final InputState inputState;
  final Vector2 _startPosition;
  final double _baseSpeedMultiplier;
  final double _baseSizeMultiplier;

  CharacterProfile _profile;
  double _spriteOpacity = 1.0;
  bool _isHoveredInMenu = false;
  bool _isMenuSelected = false;
  ui.FragmentShader? _frogOutlineShader;
  CircleHitbox? _hitbox;
  late double _speedMultiplier;
  late double _sizeMultiplier;
  late int _maxHealth;
  late int _remainingHealth;
  late double _hopTime;
  PlayerVerticalPosition get levelPosition => inputState.playerVerticalPosition;
  late PlayerVerticalPosition previousPosition;
  double get moveSpeed => PhysicsTuning.playerMoveSpeed;

  CharacterProfile get profile => _profile;
  int get maxHealth => _maxHealth;
  int moistureLevel;

  int get remainingHealth => _remainingHealth;
  bool _isDrying = false;
  bool isInWater = false;
  int _frogHouseContacts = 0;
  int _groundContacts = 0;
  int _lilyContacts = 0;
  bool _jumpActive = false;
  double _jumpElapsed = 0;
  double _outlinePulseTime = 0;
  double _underwaterSurfaceGraceRemaining = 0;
  Vector2 _jumpDirection = Vector2.zero();
  final Vector2 _thornKnockbackVelocity = Vector2.zero();
  double _thornInvincibilityRemaining = 0;
  double _thornFlickerElapsed = 0;
  SpriteAnimation? _boundAnimationForMoveSfx;
  int _lastMoveFrameIndex = -1;
  bool _seenLastMoveFrameInCurrentRun = false;
  double _movingCroakCooldownRemaining = 0;
  FrogTongueComponent? _tongue;

  int eggsCollected = 0;

  bool get _isTouchingGround => _groundContacts > 0;
  bool get _isTouchingLily => _lilyContacts > 0;
  bool get _isTouchingFrogHouse => _frogHouseContacts > 0;

  bool get _isMoving => inputState.moveAxisX != 0 || inputState.moveAxisY != 0;
  bool _wasMoving = false;

  Vector2 get velocity =>
      normalizeMoveAxis(inputState.moveAxisX, inputState.moveAxisY);

  @override
  void onTapDown(TapDownEvent event) {
    // In the menu, tapping a frog selects it and starts the game.
    if (game.phase.value == GamePhase.menu) {
      game.onPlayerTapped(this);
    }
    super.onTapDown(event);
  }

  @override
  void onHoverEnter() {
    super.onHoverEnter();
    if (game.phase.value != GamePhase.menu) {
      return;
    }
    _isHoveredInMenu = true;
    final int index = game.playerCandidates.indexOf(this);
    if (index != -1) {
      game.pointCharacterCandidate(index);
    }
  }

  @override
  void onHoverExit() {
    super.onHoverExit();
    _isHoveredInMenu = false;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _ensureOutlineShader();
  }

  Future<void> _ensureOutlineShader() async {
    try {
      final ui.FragmentProgram program =
          _frogOutlineProgram ??
          await (_frogOutlineProgramLoader ??= ui.FragmentProgram.fromAsset(
            'shaders/frog_outline.frag',
          ));
      _frogOutlineProgram = program;
      _frogOutlineShader = program.fragmentShader();
    } catch (error) {
      _frogOutlineShader = null;
      debugPrint('[shader] frog outline unavailable: $error');
    }
  }

  @override
  Future<void> onMount() async {
    super.onMount();
    paint = Paint()
      ..color = Colors.white.withAlpha((_spriteOpacity * 255).toInt());
    _hitbox = CircleHitbox(
      radius: resolveHitboxRadius(size.x),
      position: resolveHitboxPosition(size.x),
      anchor: Anchor.center,
    );
    // Players always spawn on land; initialise the shared input state so that
    // the correct animation, size and physics are applied from frame 1.
    inputState.playerVerticalPosition = PlayerVerticalPosition.land;
    previousPosition = PlayerVerticalPosition.land;
    animation = idleAnimation(levelPosition);
    _onAnimationChanged();
    await add(_hitbox!);
    final FrogTongueComponent tongue = FrogTongueComponent(player: this);
    _tongue = tongue;
    await game.world.add(tongue);
  }

  @override
  void onRemove() {
    _tongue?.removeFromParent();
    _tongue = null;
    super.onRemove();
  }

  static double _normalizeAngle(double value) {
    final double twoPi = 2 * pi;
    final double normalized = value % twoPi;
    if (normalized < 0) {
      return normalized + twoPi;
    }
    return normalized;
  }

  static double _shortestAngleDelta(double target, double current) {
    final double twoPi = 2 * pi;
    double delta = (target - current) % twoPi;
    if (delta > pi) {
      delta -= twoPi;
    } else if (delta < -pi) {
      delta += twoPi;
    }
    return delta;
  }

  void applyProfile(CharacterProfile profile) {
    _profile = profile;
    _applyStatsFromProfile();
    animation = idleAnimation(levelPosition);
    _onAnimationChanged();
  }

  void _applyStatsFromProfile() {
    _speedMultiplier = (_profile.traits.speed ?? _baseSpeedMultiplier).clamp(
      PhysicsTuning.minSpeedMultiplier,
      PhysicsTuning.maxSpeedMultiplier,
    );
    _sizeMultiplier = (_profile.traits.size ?? _baseSizeMultiplier).clamp(
      PhysicsTuning.minSizeMultiplier,
      PhysicsTuning.maxSizeMultiplier,
    );
    _maxHealth = resolveMaxHealth(_profile);
    _remainingHealth = _maxHealth;
    size = Vector2.all(PhysicsTuning.playerBaseSize * _sizeMultiplier);
    _syncHitbox();
  }

  void _syncHitbox() {
    final CircleHitbox? hitbox = _hitbox;
    if (hitbox == null) {
      return;
    }
    hitbox.radius = resolveHitboxRadius(size.x);
    hitbox.position.setFrom(resolveHitboxPosition(size.x));
  }

  static double resolveHitboxRadius(double spriteSize) {
    return spriteSize * _hitboxRadiusFactor;
  }

  static Vector2 resolveHitboxPosition(double spriteSize) {
    final double center = spriteSize / 2;
    return Vector2(center, center);
  }

  static double resolveCollisionSeparationDistance({
    required double collisionRadius,
    required double distanceToCollision,
  }) {
    return max(0.0, collisionRadius - distanceToCollision);
  }

  static int resolveMaxHealth(CharacterProfile profile) {
    final int? health = profile.traits.health;
    if (health == null) {
      return _defaultHealth;
    }
    return health.clamp(1, 9999);
  }

  static Vector2 normalizeMoveAxis(double axisX, double axisY) {
    final Vector2 velocity = Vector2(axisX, axisY);
    if (velocity.length2 > 1) {
      velocity.normalize();
    }
    return velocity;
  }

  double _movementDot(Vector2 normal) {
    double x = inputState.moveAxisX;
    double y = inputState.moveAxisY;
    final double length2 = (x * x) + (y * y);
    if (length2 == 0) {
      return 0;
    }
    if (length2 > 1) {
      final double invLength = 1 / sqrt(length2);
      x *= invLength;
      y *= invLength;
    }
    return (x * normal.x) + (y * normal.y);
  }

  static bool shouldRenderGlasses(double intelligence) {
    return intelligence >= 1.7;
  }

  static double nextThornInvincibilityRemaining({
    required double current,
    required double dt,
  }) {
    return (current - dt).clamp(0.0, PhysicsTuning.thornInvincibilitySeconds);
  }

  static bool shouldUseThornFlickerLowOpacity({
    required double thornInvincibilityRemaining,
    required double thornFlickerElapsed,
  }) {
    if (thornInvincibilityRemaining <= 0) {
      return false;
    }
    return (thornFlickerElapsed / PhysicsTuning.thornFlickerStepSeconds)
        .floor()
        .isEven;
  }

  static Vector2 resolveThornKnockbackDirection({
    required Vector2 playerCenter,
    required Vector2 collisionMidpoint,
    Vector2? thornCenter,
  }) {
    final Vector2 collisionNormal = playerCenter - collisionMidpoint;
    if (collisionNormal.length2 == 0 && thornCenter != null) {
      collisionNormal.setFrom(playerCenter - thornCenter);
    }
    if (collisionNormal.length2 == 0) {
      collisionNormal.setValues(0, -1);
    }
    collisionNormal.normalize();
    return collisionNormal;
  }

  static PlayerVerticalPosition resolveVerticalPosition({
    required PlayerVerticalPosition current,
    required bool isInWater,
    required bool jumpPressed,
    required bool divePressed,
    required bool canStayOnLand,
    required bool jumpActive,
  }) {
    if (jumpActive) {
      return PlayerVerticalPosition.land;
    }
    if (current == PlayerVerticalPosition.land) {
      if (isInWater && !canStayOnLand) {
        return PlayerVerticalPosition.waterLevel;
      }
      return PlayerVerticalPosition.land;
    }

    if (current == PlayerVerticalPosition.waterLevel) {
      if (!isInWater && canStayOnLand) {
        return PlayerVerticalPosition.land;
      }
      if (divePressed && isInWater) {
        return PlayerVerticalPosition.underwater;
      }
      return PlayerVerticalPosition.waterLevel;
    }

    if (!isInWater) {
      if (canStayOnLand) {
        return PlayerVerticalPosition.land;
      }
      return PlayerVerticalPosition.waterLevel;
    }

    if (jumpPressed) {
      return PlayerVerticalPosition.waterLevel;
    }
    return PlayerVerticalPosition.underwater;
  }

  void _startJump() {
    if (_jumpActive) {
      return;
    }
    _jumpActive = true;
    _jumpElapsed = 0;
    _jumpDirection = Vector2(sin(angle), -cos(angle));
    if (_jumpDirection.length2 == 0) {
      _jumpDirection = Vector2(0, -1);
    }
    _jumpDirection.normalize();
    inputState.playerVerticalPosition = PlayerVerticalPosition.land;
    _playRandomJumpSfx();
  }

  void _playRandomJumpSfx() {
    final String asset = game.random.nextBool()
        ? AssetPaths.jumpSfx1
        : AssetPaths.jumpSfx2;
    unawaited(game.playSfx(asset, volume: 0.65));
  }

  void _playWaterSplashSfx() {
    unawaited(game.playSfx(AssetPaths.waterSplashMidSfx, volume: 0.8));
  }

  void _maybePlayMovingCroak(double dt, {required bool isMoving}) {
    _movingCroakCooldownRemaining = (_movingCroakCooldownRemaining - dt).clamp(
      0.0,
      PhysicsTuning.movingCroakCooldownMaxSeconds,
    );
    if (!isMoving ||
        levelPosition == PlayerVerticalPosition.underwater ||
        _movingCroakCooldownRemaining > 0) {
      return;
    }

    final bool shouldCroak =
        game.random.nextDouble() <
        (PhysicsTuning.movingCroakChancePerSecond * dt);
    if (!shouldCroak) {
      return;
    }

    final double nextCooldown =
        PhysicsTuning.movingCroakCooldownMinSeconds +
        game.random.nextDouble() *
            (PhysicsTuning.movingCroakCooldownMaxSeconds -
                PhysicsTuning.movingCroakCooldownMinSeconds);
    _movingCroakCooldownRemaining = nextCooldown;
    unawaited(
      game.playSfx(
        AssetPaths.frogCroakSfx,
        volume: PhysicsTuning.movingCroakVolume,
      ),
    );
  }

  bool _shouldPlayWaterSplash({
    required PlayerVerticalPosition from,
    required PlayerVerticalPosition to,
  }) {
    return from == PlayerVerticalPosition.land &&
        to == PlayerVerticalPosition.waterLevel;
  }

  bool _canPlayMoveCycleSfxNow() {
    return game.phase.value == GamePhase.playing &&
        _isMoving &&
        !_jumpActive &&
        levelPosition != PlayerVerticalPosition.underwater;
  }

  void _handleMoveAnimationFrame(int frameIndex) {
    final SpriteAnimation? currentAnimation = animation;
    if (currentAnimation == null) {
      return;
    }

    final int frameCount = currentAnimation.frames.length;
    if (frameCount <= 1) {
      _lastMoveFrameIndex = frameIndex;
      return;
    }

    final int lastFrame = frameCount - 1;
    if (frameIndex == lastFrame) {
      _seenLastMoveFrameInCurrentRun = true;
    }

    final bool isLoopWrap =
        _lastMoveFrameIndex == lastFrame &&
        frameIndex == 0 &&
        _seenLastMoveFrameInCurrentRun;
    _lastMoveFrameIndex = frameIndex;

    if (!isLoopWrap || !_canPlayMoveCycleSfxNow()) {
      return;
    }
    _playRandomJumpSfx();
  }

  void _bindMoveCycleSfxTicker() {
    final ticker = animationTicker;
    if (ticker == null) {
      return;
    }
    ticker.onFrame = _handleMoveAnimationFrame;
  }

  void _onAnimationChanged() {
    final SpriteAnimation? currentAnimation = animation;
    if (identical(_boundAnimationForMoveSfx, currentAnimation)) {
      return;
    }

    _boundAnimationForMoveSfx = currentAnimation;
    _lastMoveFrameIndex = -1;
    _seenLastMoveFrameInCurrentRun = false;

    final ticker = animationTicker;
    if (ticker == null) {
      return;
    }
    ticker.onFrame = null;
    if (!_isMoving || currentAnimation == null) {
      return;
    }
    _bindMoveCycleSfxTicker();
  }

  void _syncMovementAnimation() {
    final PlayerVerticalPosition currentLevelPosition = levelPosition;
    if (_isMoving) {
      if (!_wasMoving || previousPosition != currentLevelPosition) {
        animation = moveAnimation(currentLevelPosition);
        _onAnimationChanged();
      }
    } else {
      if (_wasMoving || previousPosition != currentLevelPosition) {
        animation = idleAnimation(currentLevelPosition);
        _onAnimationChanged();
      }
    }
    previousPosition = currentLevelPosition;
  }

  void _resolveJump(double dt) {
    if (!_jumpActive) {
      return;
    }

    _jumpElapsed += dt;
    final double t = (_jumpElapsed / PhysicsTuning.jumpDurationSeconds).clamp(
      0,
      1,
    );
    final double forwardScale = (1 - (PhysicsTuning.jumpForwardScaleDecay * t))
        .clamp(PhysicsTuning.minJumpForwardScale, 1.0);
    position +=
        _jumpDirection * PhysicsTuning.jumpForwardSpeed * dt * forwardScale;

    if (_jumpElapsed >= PhysicsTuning.jumpDurationSeconds) {
      _jumpActive = false;
      _jumpElapsed = 0;
      inputState.playerVerticalPosition =
          (_isTouchingGround || _isTouchingLily || _isTouchingFrogHouse)
          ? PlayerVerticalPosition.land
          : PlayerVerticalPosition.waterLevel;
    }
  }

  void _syncMenuPointedVisual() {
    if (game.phase.value != GamePhase.menu) {
      _isHoveredInMenu = false;
      _isMenuSelected = false;
      scale = Vector2.all(1.0);
      paint.color = Colors.white.withValues(alpha: _spriteOpacity);
      return;
    }

    final state = game.characterGenerationState.value;
    final int index = game.playerCandidates.indexOf(this);
    final bool isSelected =
        state != null && index != -1 && index == state.selectedIndex;
    _isMenuSelected = isSelected;
    final bool isPointed = isSelected || _isHoveredInMenu;

    scale = Vector2.all(isPointed ? 1.08 : 1.0);
    paint.color = Colors.white.withValues(alpha: isPointed ? 1.0 : 0.9);
  }

  @override
  void render(Canvas canvas) {
    final Sprite? currentSprite = animationTicker?.getSprite();
    if (currentSprite == null) {
      super.render(canvas);
      return;
    }

    final bool shouldUseShader =
        game.phase.value == GamePhase.menu && _isMenuSelected;
    if (!shouldUseShader) {
      super.render(canvas);
      return;
    }

    final ui.FragmentShader? shader = _frogOutlineShader;
    if (shader == null) {
      super.render(canvas);
      return;
    }

    shader
      ..setFloat(0, size.x)
      ..setFloat(1, size.y)
      ..setFloat(2, 2.0)
      ..setFloat(3, 1.0)
      ..setFloat(4, 1.0)
      ..setFloat(5, 1.0)
      ..setFloat(6, 1.0)
      ..setFloat(7, _outlinePulseTime)
      ..setImageSampler(0, currentSprite.image);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..shader = shader,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _outlinePulseTime += dt;
    final bool wasInWater = isInWater;
    isInWater = game.level.isPositionInWater(absoluteCenter);
    if (isInWater && !wasInWater) {
      removeAll(children.whereType<SimpleTextComponent>());
    }
    final Vector2 movement = normalizeMoveAxis(
      inputState.moveAxisX,
      inputState.moveAxisY,
    );
    final bool isMoving = movement.length2 > 0;
    if (isInWater) {
      _underwaterSurfaceGraceRemaining =
          PhysicsTuning.underwaterSurfaceGraceSeconds;
    } else {
      _underwaterSurfaceGraceRemaining = (_underwaterSurfaceGraceRemaining - dt)
          .clamp(0.0, PhysicsTuning.underwaterSurfaceGraceSeconds);
    }
    _thornInvincibilityRemaining = nextThornInvincibilityRemaining(
      current: _thornInvincibilityRemaining,
      dt: dt,
    );
    _thornFlickerElapsed += dt;

    if (game.phase.value != GamePhase.playing) {
      _syncMenuPointedVisual();
      return;
    }

    scale = Vector2.all(1.0);

    _syncMovementAnimation();

    if (!isInWater && isMoving) {
      _hopTime += dt;
    } else {
      _hopTime = 0.0;
    }
    final double hopScale = isInWater ? 1.0 : sin(_hopTime * 8.0).abs();

    position +=
        movement *
        PhysicsTuning.playerMoveSpeed *
        _speedMultiplier *
        dt *
        (hopScale * 1.5);
    position += _thornKnockbackVelocity * dt;
    _thornKnockbackVelocity.scale(
      (1 - (PhysicsTuning.thornKnockbackDrag * dt)).clamp(0.0, 1.0),
    );
    if (_thornKnockbackVelocity.length2 <=
        PhysicsTuning.thornKnockbackMinSpeed *
            PhysicsTuning.thornKnockbackMinSpeed) {
      _thornKnockbackVelocity.setZero();
    }
    _wasMoving = isMoving;

    final double targetAngle = movement.screenAngle();
    if (movement.x != 0 || movement.y != 0) {
      final double angleDelta = _shortestAngleDelta(targetAngle, angle);
      if (angleDelta != 0) {
        final double maxStep =
            PhysicsTuning.playerRotationSpeed * _speedMultiplier * dt;
        final double step = angleDelta.clamp(-maxStep, maxStep).toDouble();
        angle = _normalizeAngle(angle + step);
      }
    }

    if (inputState.jumpPressed &&
        levelPosition != PlayerVerticalPosition.underwater) {
      _startJump();
    }
    if (inputState.attackPressed) {
      _tryUseTongue();
    }
    _maybePlayMovingCroak(dt, isMoving: isMoving);
    _resolveJump(dt);

    final double maxX = GameConfig.worldSize.x - size.x;
    final double maxY = GameConfig.worldSize.y - size.y;
    position.y = position.y.clamp(0, maxY);
    position.x = position.x.clamp(0, maxX);

    final PlayerVerticalPosition previousVerticalPosition = levelPosition;
    final bool canStayOnLand =
        (_isTouchingGround && !isInWater) ||
        _isTouchingLily ||
        _isTouchingFrogHouse;
    inputState.playerVerticalPosition = resolveVerticalPosition(
      current: levelPosition,
      isInWater:
          isInWater ||
          (levelPosition == PlayerVerticalPosition.underwater &&
              _underwaterSurfaceGraceRemaining > 0),
      jumpPressed: inputState.jumpPressed,
      divePressed: inputState.divePressed,
      canStayOnLand: canStayOnLand,
      jumpActive: _jumpActive,
    );
    final PlayerVerticalPosition nextVerticalPosition = levelPosition;
    if (_shouldPlayWaterSplash(
      from: previousVerticalPosition,
      to: nextVerticalPosition,
    )) {
      _playWaterSplashSfx();
    }

    switch (levelPosition) {
      case PlayerVerticalPosition.land:
        _spriteOpacity = PhysicsTuning.landOpacity;
        priority = 110;
        size = Vector2.all(
          PhysicsTuning.playerBaseSize * _sizeMultiplier * 1.1,
        );
        break;
      case PlayerVerticalPosition.waterLevel:
        _spriteOpacity = PhysicsTuning.waterOpacity;
        priority = 110;
        size = Vector2.all(PhysicsTuning.playerBaseSize * _sizeMultiplier);
        break;
      case PlayerVerticalPosition.underwater:
        _spriteOpacity = PhysicsTuning.underwaterOpacity;
        priority = 50;
        size = Vector2.all(
          PhysicsTuning.playerBaseSize * _sizeMultiplier * 0.9,
        );
        break;
    }
    final bool isFlickerLow = shouldUseThornFlickerLowOpacity(
      thornInvincibilityRemaining: _thornInvincibilityRemaining,
      thornFlickerElapsed: _thornFlickerElapsed,
    );
    final double targetOpacity = isFlickerLow
        ? PhysicsTuning.thornFlickerLowOpacity
        : _spriteOpacity;
    paint.color = Colors.white.withValues(alpha: targetOpacity);
    _syncHitbox();
  }

  void _tryUseTongue() {
    if ((_tongue?.tryLick() ?? false) == false) {
      return;
    }
    unawaited(
      game.playSfx(
        AssetPaths.tongueLickSfx,
        volume: GameplayTuning.tongueSfxVolume,
      ),
    );
  }

  void reset() {
    position.setFrom(_startPosition);
    _remainingHealth = _maxHealth;
    _thornKnockbackVelocity.setZero();
    _thornInvincibilityRemaining = 0;
    _thornFlickerElapsed = 0;
    _groundContacts = 0;
    _lilyContacts = 0;
    isInWater = false;
    _jumpActive = false;
    _jumpElapsed = 0;
    _underwaterSurfaceGraceRemaining = 0;
    _hopTime = 0;
    _boundAnimationForMoveSfx = null;
    _lastMoveFrameIndex = -1;
    _seenLastMoveFrameInCurrentRun = false;
    _movingCroakCooldownRemaining = 0;
    final ticker = animationTicker;
    if (ticker != null) {
      ticker.onFrame = null;
    }
    // Reset the vertical position to land, matching the spawn tile.
    inputState.playerVerticalPosition = PlayerVerticalPosition.land;
    previousPosition = PlayerVerticalPosition.land;
    removeWhere((child) => child is EggComponent);
    eggsCollected = 0;
    moistureLevel = GameplayTuning.initialMoistureLevel;
  }

  Future<void> onHitGround(GroundComponent ground) async {
    if (game.phase.value != GamePhase.playing) {
      return;
    }
    if (_isDrying) return;
    Future.delayed(_dryingDelay, () {
      _isDrying = false;
    });
    _isDrying = true;
    if (moistureLevel > 0) {
      moistureLevel--;
    } else {
      await applyDamageWithInvincibilityDelay(ground.damage, 0.5);
    }
  }

  Vector2 _resolveCollisionCenter() {
    final CircleHitbox? hitbox = _hitbox;
    if (hitbox == null) {
      return absoluteCenter.clone();
    }
    return hitbox.absoluteCenter;
  }

  double _resolveCollisionRadius() {
    final CircleHitbox? hitbox = _hitbox;
    if (hitbox == null) {
      return resolveHitboxRadius(size.x);
    }
    return hitbox.radius;
  }

  Vector2 _resolveCollisionMidpoint(
    Set<Vector2> intersectionPoints, {
    Vector2? fallback,
  }) {
    if (intersectionPoints.isEmpty) {
      return fallback?.clone() ?? _resolveCollisionCenter();
    }
    Vector2 sum = Vector2.zero();
    for (final Vector2 point in intersectionPoints) {
      sum += point;
    }
    return sum / intersectionPoints.length.toDouble();
  }

  void _separateFromCollision({
    required Set<Vector2> intersectionPoints,
    required bool onlyWhenMovingInto,
    Vector2? obstacleCenter,
  }) {
    final Vector2 collisionCenter = _resolveCollisionCenter();
    final Vector2 collisionMid = _resolveCollisionMidpoint(
      intersectionPoints,
      fallback: obstacleCenter,
    );
    final Vector2 collisionNormal = resolveThornKnockbackDirection(
      playerCenter: collisionCenter,
      collisionMidpoint: collisionMid,
      thornCenter: obstacleCenter,
    );
    final double separationDistance = resolveCollisionSeparationDistance(
      collisionRadius: _resolveCollisionRadius(),
      distanceToCollision: collisionCenter.distanceTo(collisionMid),
    );
    if (separationDistance <= 0) {
      return;
    }
    if (onlyWhenMovingInto) {
      final double moveDot = _movementDot(collisionNormal);
      if (moveDot >= 0 && separationDistance <= _forcedSeparationThreshold) {
        return;
      }
    }
    position += collisionNormal.scaled(separationDistance);
  }

  void _applyThornImpact(
    Set<Vector2> intersectionPoints,
    ThornComponent thorn,
  ) {
    final Vector2 collisionCenter = _resolveCollisionCenter();
    final Vector2 collisionMid = _resolveCollisionMidpoint(
      intersectionPoints,
      fallback: thorn.absoluteCenter,
    );
    final Vector2 collisionNormal = resolveThornKnockbackDirection(
      playerCenter: collisionCenter,
      collisionMidpoint: collisionMid,
      thornCenter: thorn.absoluteCenter,
    );
    _thornKnockbackVelocity.setFrom(
      collisionNormal.scaled(PhysicsTuning.thornKnockbackSpeed),
    );

    final double separationDistance = resolveCollisionSeparationDistance(
      collisionRadius: _resolveCollisionRadius(),
      distanceToCollision: collisionCenter.distanceTo(collisionMid),
    );
    if (separationDistance > 0) {
      position += collisionNormal.scaled(separationDistance);
    }
  }

  Future<void> runDamageFlashEffect() async {
    await add(
      SequenceEffect([
        OpacityEffect.to(
          PhysicsTuning.thornFlickerLowOpacity,
          EffectController(duration: PhysicsTuning.thornFlashStepSeconds),
        ),
        OpacityEffect.to(
          1,
          EffectController(duration: PhysicsTuning.thornFlashStepSeconds),
        ),
      ]),
    );
  }

  Future<void> _spawnThornParticles(Vector2 impactPoint) async {
    final Paint particlePaint = Paint()
      ..color = Colors.lightGreenAccent.withValues(
        alpha: PhysicsTuning.thornParticleAlpha,
      );
    await game.world.add(
      ParticleSystemComponent(
        position: impactPoint,
        priority: priority + 1,
        particle: Particle.generate(
          count: PhysicsTuning.thornParticleCount,
          lifespan: PhysicsTuning.thornParticleLifespanSeconds,
          generator: (int index) {
            final double direction = game.random.nextDouble() * pi * 2;
            final double speed =
                PhysicsTuning.thornParticleSpeedMin +
                game.random.nextDouble() *
                    (PhysicsTuning.thornParticleSpeedMax -
                        PhysicsTuning.thornParticleSpeedMin);
            return AcceleratedParticle(
              speed: Vector2(cos(direction), sin(direction)) * speed,
              child: CircleParticle(
                radius: PhysicsTuning.thornParticleRadius,
                paint: particlePaint,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onThornCollision(
    Set<Vector2> intersectionPoints,
    ThornComponent thorn,
  ) async {
    _applyThornImpact(intersectionPoints, thorn);
    if (_thornInvincibilityRemaining > 0) {
      return;
    }
    _thornInvincibilityRemaining = PhysicsTuning.thornInvincibilitySeconds;
    _thornFlickerElapsed = 0;
    unawaited(applyDamage(PhysicsTuning.thornDamageAmount));
    await runDamageFlashEffect();
    await _spawnThornParticles(
      _resolveCollisionMidpoint(
        intersectionPoints,
        fallback: thorn.absoluteCenter,
      ),
    );
  }

  @override
  Future<void> onCollision(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) async {
    if (game.phase.value != GamePhase.playing) {
      super.onCollision(intersectionPoints, other);
      return;
    }
    if (other is GroundComponent) {
      final bool centerInWater = game.level.isPositionInWater(absoluteCenter);
      if (!centerInWater) {
        await onHitGround(other);
      }
      if (!centerInWater &&
          levelPosition != PlayerVerticalPosition.land &&
          !_jumpActive) {
        _separateFromCollision(
          intersectionPoints: intersectionPoints,
          onlyWhenMovingInto: true,
          obstacleCenter: other.absoluteCenter,
        );
      }
    }
    if (other is ThornComponent) {
      await _onThornCollision(intersectionPoints, other);
    }
    if (other is WaterLilyComponent &&
        levelPosition == PlayerVerticalPosition.waterLevel) {
      _separateFromCollision(
        intersectionPoints: intersectionPoints,
        onlyWhenMovingInto: false,
        obstacleCenter: other.absoluteCenter,
      );
    }
    if (other is FrogHouseComponent) {
      if (levelPosition != PlayerVerticalPosition.land &&
          !_jumpActive &&
          levelPosition != PlayerVerticalPosition.underwater) {
        _separateFromCollision(
          intersectionPoints: intersectionPoints,
          onlyWhenMovingInto: true,
          obstacleCenter: other.absoluteCenter,
        );
      }
    }

    if (other is EggComponent) {
      if (eggsCollected < GameplayTuning.maxEggs &&
          !other.isInSafeHouse &&
          !other.isOnBack) {
        eggsCollected++;
        add(
          EggComponent(
            position: Vector2(
              size.x / 3 + game.random.nextDouble() * size.x / 3,
              size.y / 3 + game.random.nextDouble() * size.y / 3,
            ),
            size: Vector2.all(GameplayTuning.worldPickupSize / 1.5),
            isOnBack: true,
            isInSafeHouse: false,
          ),
        );

        await other.collect();
      }
    }
    super.onCollision(intersectionPoints, other);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    final bool centerInWater = game.level.isPositionInWater(absoluteCenter);
    if (other is WaterComponent && centerInWater) {
      _underwaterSurfaceGraceRemaining =
          PhysicsTuning.underwaterSurfaceGraceSeconds;
      removeAll(children.whereType<SimpleTextComponent>());
    }
    if (other is FrogHouseComponent) {
      _frogHouseContacts++;
      if (_jumpActive) {
        _jumpActive = false;
        _jumpElapsed = 0;
        inputState.playerVerticalPosition = PlayerVerticalPosition.land;
      }
      super.onCollisionStart(intersectionPoints, other);
      return;
    }
    if (other is GroundComponent) {
      _groundContacts++;
      if (_jumpActive && !centerInWater) {
        _jumpActive = false;
        _jumpElapsed = 0;
        inputState.playerVerticalPosition = PlayerVerticalPosition.land;
      }
      super.onCollisionStart(intersectionPoints, other);
      return;
    }
    if (other is WaterLilyComponent) {
      _lilyContacts++;
      if (_jumpActive) {
        _jumpActive = false;
        _jumpElapsed = 0;
        inputState.playerVerticalPosition = PlayerVerticalPosition.land;
      }
      super.onCollisionStart(intersectionPoints, other);
      return;
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    if (other is GroundComponent) {
      _groundContacts = (_groundContacts - 1).clamp(0, 999999);
      removeAll(children.whereType<SimpleTextComponent>());
    }
    if (other is WaterComponent) {
      moistureLevel = GameplayTuning.initialMoistureLevel;
    }
    if (other is WaterLilyComponent) {
      _lilyContacts = (_lilyContacts - 1).clamp(0, 999999);
    }
    if (other is FrogHouseComponent) {
      _frogHouseContacts = (_frogHouseContacts - 1).clamp(0, 999999);
    }

    super.onCollisionEnd(other);
  }

  Future<void> applyDamage(int damage) async {
    if (game.phase.value != GamePhase.playing) {
      return;
    }
    _remainingHealth = (_remainingHealth - damage).clamp(0, _maxHealth);
    if (_remainingHealth <= 0) {
      game.endGame();
    } else {
      final damageText = SimpleTextComponent(
        color: Colors.red,
        text: '- $damage',
        position: Vector2(size.x, -24),
        priority: 50,
      );
      await damageText.add(
        MoveEffect.by(
          Vector2(
            game.random.nextDouble() * size.x,
            game.random.nextDouble() * size.y,
          ),
          EffectController(duration: 1.0, curve: Curves.linear, repeatCount: 1),
        ),
      );
      await add(damageText);
      Future.delayed(_damageTextDuration, () {
        if (damageText.parent == null) return;
        damageText.removeFromParent();
      });
    }
  }

  void heal(int amount) {
    if (game.phase.value != GamePhase.playing || amount <= 0) {
      return;
    }
    final int before = _remainingHealth;
    _remainingHealth = (_remainingHealth + amount).clamp(0, _maxHealth);
    final int healed = _remainingHealth - before;
    if (healed > 0) {
      unawaited(_showHealingText(healed));
    }
  }

  Future<void> _showHealingText(int healed) async {
    final SimpleTextComponent healingText = SimpleTextComponent(
      color: Colors.lightGreenAccent,
      text: '+$healed HP',
      position:
          absoluteCenter +
          Vector2(
            GameplayTuning.healingTextOffsetX,
            GameplayTuning.healingTextOffsetY,
          ),
      priority: 130,
    );
    await game.world.add(healingText);
    await healingText.add(
      MoveEffect.by(
        Vector2(0, -GameplayTuning.healingTextRiseDistance),
        EffectController(
          duration: GameplayTuning.healingTextRiseDurationSeconds,
          curve: Curves.easeOut,
        ),
      ),
    );
    Future.delayed(
      const Duration(milliseconds: GameplayTuning.healingTextLifetimeMs),
      () {
        if (healingText.parent == null) {
          return;
        }
        healingText.removeFromParent();
      },
    );
  }

  void onFlyCaughtFromTongue(FlyComponent fly) {
    if (game.phase.value != GamePhase.playing || fly.parent == null) {
      return;
    }
    fly.removeFromParent();
    heal(GameplayTuning.flyHealAmount);
  }

  Future<void> applyDamageWithInvincibilityDelay(
    int damage,
    double delay,
  ) async {
    if (_thornInvincibilityRemaining > 0) {
      return;
    }
    _thornInvincibilityRemaining = delay;
    _thornFlickerElapsed = 0;
    await applyDamage(damage);
    await runDamageFlashEffect();
  }
}
