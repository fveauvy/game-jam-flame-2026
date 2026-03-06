import 'package:game_jam/game/character/model/character_profile.dart';

abstract interface class CharacterGenerator {
  Future<CharacterProfile> generate({required int seed});
}
