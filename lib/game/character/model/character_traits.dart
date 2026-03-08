class CharacterTraits {
  const CharacterTraits({
    this.speed,
    this.size,
    this.intelligence,
    this.health,
    this.sanity,
    this.range,
    this.arms,
    this.legs,
    this.tongue,
    this.tongueRange,
  });

  final double? speed;
  final double? size;
  final double? intelligence;
  final int? health;
  final double? sanity;
  final double? range;
  final int? arms;
  final int? legs;
  final bool? tongue;
  final double? tongueRange;

  static const CharacterTraits empty = CharacterTraits();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CharacterTraits &&
        other.speed == speed &&
        other.size == size &&
        other.intelligence == intelligence &&
        other.health == health &&
        other.sanity == sanity &&
        other.range == range &&
        other.arms == arms &&
        other.legs == legs &&
        other.tongue == tongue &&
        other.tongueRange == tongueRange;
  }

  @override
  int get hashCode => Object.hash(
    speed,
    size,
    intelligence,
    health,
    sanity,
    range,
    arms,
    legs,
    tongue,
    tongueRange,
  );
}
