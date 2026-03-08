import 'package:game_jam/game/character/model/character_name.dart';
import 'package:game_jam/game/character/model/character_traits.dart';

class CharacterProfile {
  const CharacterProfile({
    required this.name,
    required this.spriteId,
    required this.spriteAssetPath,
    this.traits = CharacterTraits.empty,
  });

  final CharacterName name;
  final String spriteId;
  final String spriteAssetPath;
  final CharacterTraits traits;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CharacterProfile &&
        other.name == name &&
        other.spriteId == spriteId &&
        other.spriteAssetPath == spriteAssetPath &&
        other.traits == traits;
  }

  @override
  int get hashCode => Object.hash(name, spriteId, spriteAssetPath, traits);
}
