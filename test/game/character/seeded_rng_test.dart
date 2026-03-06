import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/game/character/infra/seeded_rng.dart';

void main() {
  test('same seed gives same picks', () {
    final SeededRng a = SeededRng(1337);
    final SeededRng b = SeededRng(1337);

    final List<int> seqA = List<int>.generate(5, (_) => a.nextInt(1000));
    final List<int> seqB = List<int>.generate(5, (_) => b.nextInt(1000));

    expect(seqA, seqB);
  });

  test('pick throws on empty values', () {
    final SeededRng rng = SeededRng(1);
    expect(() => rng.pick(<int>[]), throwsStateError);
  });
}
