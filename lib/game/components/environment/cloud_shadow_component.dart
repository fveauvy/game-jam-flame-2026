import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/game/my_game.dart';

class CloudShadowComponent extends PositionComponent
    with HasGameReference<MyGame> {
  CloudShadowComponent({required this.seed})
    : super(
        position: Vector2.zero(),
        size: GameConfig.worldSize.clone(),
        priority: 5,
      );

  final int seed;

  static const int _directionSalt = 0x1A4B5C;
  static const int _densitySalt = 0x2B6C7D;
  static const int _speedSalt = 0x3C7D8E;
  static const int _shapeSalt = 0x4D8E9F;

  static const int _minCloudCount = 6;
  static const int _maxCloudCount = 12;
  static const double _minSpeed = 34;
  static const double _maxSpeed = 78;
  static const double _minOpacity = 0.05;
  static const double _maxOpacity = 0.11;

  late final Vector2 _windDirection;
  late final double _windSpeed;
  late final Random _shapeRandom;
  late final _ProjectedBounds _bounds;
  late final List<_CloudShadow> _clouds;

  static Vector2 windDirectionFromSeed(int seed) {
    final Random random = Random(seed ^ _directionSalt);
    final double angle = random.nextDouble() * pi * 2;
    return Vector2(cos(angle), sin(angle));
  }

  static int cloudCountFromSeed(int seed) {
    final Random random = Random(seed ^ _densitySalt);
    return _minCloudCount + random.nextInt(_maxCloudCount - _minCloudCount + 1);
  }

  static double windSpeedFromSeed(int seed) {
    final Random random = Random(seed ^ _speedSalt);
    return _minSpeed + random.nextDouble() * (_maxSpeed - _minSpeed);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _windDirection = windDirectionFromSeed(seed);
    _windSpeed = windSpeedFromSeed(seed);
    _shapeRandom = Random(seed ^ _shapeSalt);
    _bounds = _computeBounds(size: size, direction: _windDirection);

    final int count = cloudCountFromSeed(seed);
    _clouds = List<_CloudShadow>.generate(count, (int index) {
      return _spawnCloud(randomizeAlong: true);
    }, growable: false);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final double drift = _windSpeed * dt;
    for (int i = 0; i < _clouds.length; i++) {
      final _CloudShadow cloud = _clouds[i];
      cloud.along += drift;
      if (cloud.along - cloud.radius > _bounds.maxAlong) {
        _clouds[i] = _spawnCloud(randomizeAlong: false);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.x, size.y));
    for (final _CloudShadow cloud in _clouds) {
      final Vector2 center = _bounds.toWorld(
        along: cloud.along,
        across: cloud.across,
      );
      _drawCloud(canvas, cloud: cloud, center: center);
    }
    canvas.restore();
  }

  _CloudShadow _spawnCloud({required bool randomizeAlong}) {
    final double width = 420 + _shapeRandom.nextDouble() * 380;
    final double height = width * (0.38 + _shapeRandom.nextDouble() * 0.22);
    final double radius = max(width, height) * 0.7;
    final double opacity =
        _minOpacity + _shapeRandom.nextDouble() * (_maxOpacity - _minOpacity);

    final double along = randomizeAlong
        ? (_bounds.minAlong - radius) +
              _shapeRandom.nextDouble() *
                  ((_bounds.maxAlong + radius) - (_bounds.minAlong - radius))
        : _bounds.minAlong - radius;
    final double across =
        _bounds.minAcross +
        _shapeRandom.nextDouble() * (_bounds.maxAcross - _bounds.minAcross);

    final List<_CloudLobe> lobes = _buildCloudLobes(
      width: width,
      height: height,
    );
    return _CloudShadow(
      along: along,
      across: across,
      radius: radius,
      opacity: opacity,
      blurSigma: height * 0.06,
      width: width,
      height: height,
      lobes: lobes,
    );
  }

  List<_CloudLobe> _buildCloudLobes({
    required double width,
    required double height,
  }) {
    final int lobeCount = 4 + _shapeRandom.nextInt(3);
    final List<_CloudLobe> lobes = <_CloudLobe>[];

    for (int i = 0; i < lobeCount; i++) {
      final double t = lobeCount == 1 ? 0.5 : i / (lobeCount - 1);
      final double x = (t - 0.5) * width * 0.95;
      final double y =
          (-height * 0.14) + _shapeRandom.nextDouble() * height * 0.28;
      final double lobeWidth = width * (0.28 + _shapeRandom.nextDouble() * 0.2);
      final double lobeHeight =
          height * (0.55 + _shapeRandom.nextDouble() * 0.35);
      lobes.add(
        _CloudLobe(offset: Vector2(x, y), width: lobeWidth, height: lobeHeight),
      );
    }

    return lobes;
  }

  void _drawCloud(
    Canvas canvas, {
    required _CloudShadow cloud,
    required Vector2 center,
  }) {
    final Paint paint = Paint()
      ..color = const Color(0xFF6E6E6E).withValues(alpha: cloud.opacity)
      ..blendMode = BlendMode.multiply
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cloud.blurSigma);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.x, center.y),
        width: cloud.width,
        height: cloud.height,
      ),
      paint,
    );

    for (final _CloudLobe lobe in cloud.lobes) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.x + lobe.offset.x, center.y + lobe.offset.y),
          width: lobe.width,
          height: lobe.height,
        ),
        paint,
      );
    }
  }

  static _ProjectedBounds _computeBounds({
    required Vector2 size,
    required Vector2 direction,
  }) {
    final Vector2 normal = Vector2(-direction.y, direction.x);
    final Vector2 center = size / 2;
    final List<Vector2> corners = <Vector2>[
      Vector2(0, 0),
      Vector2(size.x, 0),
      Vector2(0, size.y),
      Vector2(size.x, size.y),
    ];

    double minAlong = double.infinity;
    double maxAlong = double.negativeInfinity;
    double minAcross = double.infinity;
    double maxAcross = double.negativeInfinity;

    for (final Vector2 corner in corners) {
      final Vector2 localCorner = corner - center;
      final double along = localCorner.dot(direction);
      final double across = localCorner.dot(normal);
      minAlong = min(minAlong, along);
      maxAlong = max(maxAlong, along);
      minAcross = min(minAcross, across);
      maxAcross = max(maxAcross, across);
    }

    return _ProjectedBounds(
      center: center,
      direction: direction,
      normal: normal,
      minAlong: minAlong,
      maxAlong: maxAlong,
      minAcross: minAcross,
      maxAcross: maxAcross,
    );
  }
}

class _ProjectedBounds {
  const _ProjectedBounds({
    required this.center,
    required this.direction,
    required this.normal,
    required this.minAlong,
    required this.maxAlong,
    required this.minAcross,
    required this.maxAcross,
  });

  final Vector2 center;
  final Vector2 direction;
  final Vector2 normal;
  final double minAlong;
  final double maxAlong;
  final double minAcross;
  final double maxAcross;

  Vector2 toWorld({required double along, required double across}) {
    return center + (direction * along) + (normal * across);
  }
}

class _CloudShadow {
  _CloudShadow({
    required this.along,
    required this.across,
    required this.radius,
    required this.opacity,
    required this.blurSigma,
    required this.width,
    required this.height,
    required this.lobes,
  });

  double along;
  final double across;
  final double radius;
  final double opacity;
  final double blurSigma;
  final double width;
  final double height;
  final List<_CloudLobe> lobes;
}

class _CloudLobe {
  const _CloudLobe({
    required this.offset,
    required this.width,
    required this.height,
  });

  final Vector2 offset;
  final double width;
  final double height;
}
