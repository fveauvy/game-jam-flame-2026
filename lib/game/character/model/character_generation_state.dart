import 'package:game_jam/game/character/model/character_profile.dart';

class CharacterGenerationState {
  const CharacterGenerationState({
    required this.seedCode,
    required this.seedInt,
    required this.profile,
  });

  final String seedCode;
  final int seedInt;
  final CharacterProfile profile;
}
