import 'package:collection/collection.dart';

typedef MinMax = ({double min, double max});

enum BiomeType {
  // désert
  desert(
    humidity: (min: 0, max: 0.2),
    temperature: (min: 0.8, max: 1),
    vegetation: (min: 0, max: 0.2),
  ),
  // boue
  mud(
    humidity: (min: 0.2, max: 0.5),
    temperature: (min: 0, max: 0.5),
    vegetation: (min: 0, max: 0.3),
  ),
  // flac
  flac(
    humidity: (min: 0.6, max: 0.7),
    temperature: (min: 0, max: 0.3),
    vegetation: (min: 0, max: 0.2),
  ),
  // étang
  pond(
    humidity: (min: 0.6, max: 0.8),
    temperature: (min: 0, max: 1),
    vegetation: (min: 0, max: 0.7),
  ),
  // rivière
  river(
    humidity: (min: 0.6, max: 1),
    temperature: (min: 0, max: 1),
    vegetation: (min: 0, max: 1),
  );

  final MinMax humidity;
  final MinMax temperature;
  final MinMax vegetation;

  const BiomeType({
    required this.humidity,
    required this.temperature,
    required this.vegetation,
  });

  static BiomeType from({
    required double humidityPercent,
    required double temperature,
    required double vegetation,
  }) {
    return BiomeType.values.firstWhereOrNull(
          (biome) =>
              biome.humidity.min <= humidityPercent &&
              biome.humidity.max >= humidityPercent &&
              biome.temperature.min <= temperature &&
              biome.temperature.max >= temperature &&
              biome.vegetation.min <= vegetation &&
              biome.vegetation.max >= vegetation,
        ) ??
        BiomeType.river;
  }
}
