import 'package:game_jam/game/character/model/character_profile.dart';

class CharacterGenerationState {
  const CharacterGenerationState({
    required this.seedCode,
    required this.seedInt,
    required this.candidateSeedCodes,
    required this.candidateProfiles,
    this.selectedIndex = 0,
  }) : assert(candidateSeedCodes.length == candidateProfiles.length),
       assert(candidateSeedCodes.length > 0),
       assert(selectedIndex >= 0),
       assert(selectedIndex < candidateProfiles.length);

  final String seedCode;
  final int seedInt;
  final List<String> candidateSeedCodes;
  final List<CharacterProfile> candidateProfiles;
  final int selectedIndex;

  CharacterProfile get profile => candidateProfiles[selectedIndex];
  String get selectedSeedCode => candidateSeedCodes[selectedIndex];

  CharacterGenerationState copyWith({int? selectedIndex}) {
    return CharacterGenerationState(
      seedCode: seedCode,
      seedInt: seedInt,
      candidateSeedCodes: candidateSeedCodes,
      candidateProfiles: candidateProfiles,
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }
}
