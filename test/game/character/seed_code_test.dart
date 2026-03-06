import 'package:flutter_test/flutter_test.dart';
import 'package:game_jam/game/character/infra/seed_code.dart';

void main() {
  test('valid code decodes and round-trips', () {
    final int seed = SeedCode.decode('4SFE6');
    final String code = SeedCode.encode(seed);
    expect(code, '4SFE6');
  });

  test('normalization uppercases and trims', () {
    expect(SeedCode.normalize(' 4sfe6 '), '4SFE6');
  });

  test('invalid code throws', () {
    expect(() => SeedCode.decode('10OOO'), throwsFormatException);
    expect(() => SeedCode.decode('ABC'), throwsFormatException);
  });
}
