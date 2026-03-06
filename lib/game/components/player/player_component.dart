import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:game_jam/core/config/game_config.dart';
import 'package:game_jam/game/character/model/character_profile.dart';
import 'package:game_jam/game/input/input_state.dart';
import 'package:game_jam/game/my_game.dart';

class PlayerComponent extends CircleComponent with HasGameReference<MyGame> {
  PlayerComponent({
    required this.inputState,
    required CharacterProfile profile,
    required Vector2 startPosition,
  }) : _startPosition = startPosition.clone(),
       _profile = profile,
       super(
         position: startPosition.clone(),
         radius: 48,
         anchor: Anchor.topLeft,
         priority: 10,
         paint: Paint()..color = _parseColor(profile.colorHex),
       );

  final InputState inputState;
  CharacterProfile _profile;
  final Vector2 _startPosition;

  CharacterProfile get profile => _profile;

  static const double _moveSpeed = 340;

  static Color _parseColor(String hex) {
    final String normalized = hex.replaceFirst('#', '').trim();
    if (normalized.length != 6) {
      return const Color(0xFF2A9D8F);
    }
    final int? rgb = int.tryParse(normalized, radix: 16);
    if (rgb == null) {
      return const Color(0xFF2A9D8F);
    }
    return Color(0xFF000000 | rgb);
  }

  void applyProfile(CharacterProfile profile) {
    _profile = profile;
    paint.color = _parseColor(profile.colorHex);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.phase.value != GamePhase.playing) {
      return;
    }

    final Vector2 velocity = Vector2(
      inputState.moveAxisX,
      inputState.moveAxisY,
    );
    position += velocity * _moveSpeed * dt;

    final double maxX = GameConfig.worldSize.x - size.x;
    position.x = position.x.clamp(0, maxX);
  }

  void reset() {
    position.setFrom(_startPosition);
  }
}
