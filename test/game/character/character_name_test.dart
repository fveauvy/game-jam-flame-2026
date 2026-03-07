import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/game/character/model/character_name.dart';

void main() {
  test('display returns adjective and noun when batch is null', () {
    const CharacterName name = CharacterName(adjective: 'Brave', noun: 'Frog');

    expect(name.display, 'Brave Frog');
  });

  test('display returns adjective and noun when batch is empty', () {
    const CharacterName name = CharacterName(
      adjective: 'Brave',
      noun: 'Frog',
      batch: '   ',
    );

    expect(name.display, 'Brave Frog');
  });

  test('display keeps space for prepositional batch', () {
    const CharacterName name = CharacterName(
      adjective: 'Brave',
      noun: 'Frog',
      batch: 'of the Pond',
    );

    expect(name.display, 'Brave Frog of the Pond');
  });

  test('display keeps space for from batch', () {
    const CharacterName name = CharacterName(
      adjective: 'Officer',
      noun: 'Frog',
      batch: 'from Accounting',
    );

    expect(name.display, 'Officer Frog from Accounting');
  });

  test('display keeps space for mixed-case no-comma batch', () {
    const CharacterName name = CharacterName(
      adjective: 'Tiny',
      noun: 'Frog',
      batch: '  Of the Bog  ',
    );

    expect(name.display, 'Tiny Frog Of the Bog');
  });

  test('display inserts comma for appositive batch', () {
    const CharacterName name = CharacterName(
      adjective: 'Brave',
      noun: 'Frog',
      batch: 'Legion',
    );

    expect(name.display, 'Brave Frog, Legion');
  });
}
