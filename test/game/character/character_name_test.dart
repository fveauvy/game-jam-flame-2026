import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/game/character/model/character_name.dart';

void main() {
  test('display returns adjective and noun when title is null', () {
    const CharacterName name = CharacterName(adjective: 'Brave', noun: 'Frog');

    expect(name.display, 'Brave Frog');
  });

  test('display returns adjective and noun when title is empty', () {
    const CharacterName name = CharacterName(
      adjective: 'Brave',
      noun: 'Frog',
      title: '   ',
    );

    expect(name.display, 'Brave Frog');
  });

  test('display keeps space for prepositional title', () {
    const CharacterName name = CharacterName(
      adjective: 'Brave',
      noun: 'Frog',
      title: 'of the Pond',
    );

    expect(name.display, 'Brave Frog of the Pond');
  });

  test('display keeps space for from title', () {
    const CharacterName name = CharacterName(
      adjective: 'Officer',
      noun: 'Frog',
      title: 'from Accounting',
    );

    expect(name.display, 'Officer Frog from Accounting');
  });

  test('display keeps space for mixed-case no-comma title', () {
    const CharacterName name = CharacterName(
      adjective: 'Tiny',
      noun: 'Frog',
      title: '  Of the Bog  ',
    );

    expect(name.display, 'Tiny Frog Of the Bog');
  });

  test('display inserts comma for appositive title', () {
    const CharacterName name = CharacterName(
      adjective: 'Brave',
      noun: 'Frog',
      title: 'Legion',
    );

    expect(name.display, 'Brave Frog, Legion');
  });
}
