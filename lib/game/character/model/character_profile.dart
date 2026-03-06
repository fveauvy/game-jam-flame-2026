import 'package:game_jam/game/character/model/character_name.dart';
import 'package:game_jam/game/character/model/character_traits.dart';

class CharacterProfile {
  const CharacterProfile({
    required this.name,
    required this.colorId,
    required this.colorHex,
    this.traits = CharacterTraits.empty,
  });

  final CharacterName name;
  final String colorId;
  final String colorHex;
  final CharacterTraits traits;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CharacterProfile &&
        other.name == name &&
        other.colorId == colorId &&
        other.colorHex == colorHex &&
        other.traits == traits;
  }

  @override
  int get hashCode => Object.hash(name, colorId, colorHex, traits);
}
