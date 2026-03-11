import 'package:game_jam/audio/audio_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioSettingsStore {
  static const String _mutedKey = 'audio.muted';
  static const String _masterVolumeKey = 'audio.masterVolume';
  static const String _musicVolumeKey = 'audio.musicVolume';
  static const String _sfxVolumeKey = 'audio.sfxVolume';

  Future<AudioSettings> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return AudioSettings(
      muted: prefs.getBool(_mutedKey) ?? AudioSettings.defaults.muted,
      masterVolume:
          prefs.getDouble(_masterVolumeKey) ??
          AudioSettings.defaults.masterVolume,
      musicVolume:
          prefs.getDouble(_musicVolumeKey) ??
          AudioSettings.defaults.musicVolume,
      sfxVolume:
          prefs.getDouble(_sfxVolumeKey) ?? AudioSettings.defaults.sfxVolume,
    );
  }

  Future<void> save(AudioSettings settings) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mutedKey, settings.muted);
    await prefs.setDouble(_masterVolumeKey, settings.masterVolume);
    await prefs.setDouble(_musicVolumeKey, settings.musicVolume);
    await prefs.setDouble(_sfxVolumeKey, settings.sfxVolume);
  }
}
