import 'dart:math';

abstract final class SeedCode {
  static const String _alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  static const int length = 5;
  static const int _base = 32;
  static const int maxValueExclusive = 33554432;

  static String normalize(String code) => code.trim().toUpperCase();

  static bool isValid(String code) {
    final String normalized = normalize(code);
    if (normalized.length != length) {
      return false;
    }
    for (int i = 0; i < normalized.length; i++) {
      if (!_alphabet.contains(normalized[i])) {
        return false;
      }
    }
    return true;
  }

  static int decode(String code) {
    final String normalized = normalize(code);
    if (!isValid(normalized)) {
      throw FormatException('Invalid seed code: $code');
    }

    int value = 0;
    for (int i = 0; i < normalized.length; i++) {
      value *= _base;
      value += _alphabet.indexOf(normalized[i]);
    }
    return value;
  }

  static String encode(int seed) {
    if (seed < 0 || seed >= maxValueExclusive) {
      throw RangeError.range(seed, 0, maxValueExclusive - 1, 'seed');
    }

    int value = seed;
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      final int idx = value % _base;
      buffer.write(_alphabet[idx]);
      value ~/= _base;
    }
    return buffer.toString().split('').reversed.join();
  }

  static String randomCode(Random random) {
    final int seed = random.nextInt(maxValueExclusive);
    return encode(seed);
  }
}
