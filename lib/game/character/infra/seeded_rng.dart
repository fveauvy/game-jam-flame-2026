import 'dart:math';

class SeededRng {
  SeededRng(int seed) : _random = Random(seed);

  final Random _random;

  int nextInt(int max) => _random.nextInt(max);

  T pick<T>(List<T> values) {
    if (values.isEmpty) {
      throw StateError('Cannot pick from empty list');
    }
    return values[nextInt(values.length)];
  }
}
