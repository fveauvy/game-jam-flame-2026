class AudioSettings {
  const AudioSettings({
    required this.muted,
    required this.masterVolume,
    required this.musicVolume,
    required this.sfxVolume,
  });

  static const AudioSettings defaults = AudioSettings(
    muted: false,
    masterVolume: 1.0,
    musicVolume: 0.25,
    sfxVolume: 1.0,
  );

  final bool muted;
  final double masterVolume;
  final double musicVolume;
  final double sfxVolume;

  double get effectiveMusicVolume =>
      muted ? 0 : _clamp(masterVolume) * _clamp(musicVolume);

  double get effectiveSfxVolume =>
      muted ? 0 : _clamp(masterVolume) * _clamp(sfxVolume);

  AudioSettings copyWith({
    bool? muted,
    double? masterVolume,
    double? musicVolume,
    double? sfxVolume,
  }) {
    return AudioSettings(
      muted: muted ?? this.muted,
      masterVolume: _clamp(masterVolume ?? this.masterVolume),
      musicVolume: _clamp(musicVolume ?? this.musicVolume),
      sfxVolume: _clamp(sfxVolume ?? this.sfxVolume),
    );
  }

  static double _clamp(double value) => value.clamp(0.0, 1.0);
}
