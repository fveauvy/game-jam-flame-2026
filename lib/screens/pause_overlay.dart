import 'package:flutter/material.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/game/character/model/character_profile.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onToggleMute,
    required this.onMasterVolumeChanged,
    required this.onMusicVolumeChanged,
    required this.onSfxVolumeChanged,
    required this.seedCode,
    required this.characterProfile,
    required this.currentHealth,
    required this.maxHealth,
    required this.muted,
    required this.masterVolume,
    required this.musicVolume,
    required this.sfxVolume,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onToggleMute;
  final ValueChanged<double> onMasterVolumeChanged;
  final ValueChanged<double> onMusicVolumeChanged;
  final ValueChanged<double> onSfxVolumeChanged;
  final String seedCode;
  final CharacterProfile? characterProfile;
  final int? currentHealth;
  final int? maxHealth;
  final bool muted;
  final double masterVolume;
  final double musicVolume;
  final double sfxVolume;

  @override
  Widget build(BuildContext context) {
    final String name = characterProfile?.name.display ?? '-';
    final String intelligence =
        characterProfile?.traits.intelligence?.toStringAsFixed(2) ?? '-';
    final String speed =
        characterProfile?.traits.speed?.toStringAsFixed(2) ?? '-';
    final String size =
        characterProfile?.traits.size?.toStringAsFixed(2) ?? '-';
    final String health = currentHealth == null || maxHealth == null
        ? '-'
        : '$currentHealth/$maxHealth';
    const Color panelTextColor = Color(0xFF2F2118);
    const Color panelLabelColor = Color(0xFF5A4132);

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 773 / 801,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    AssetPaths.uiTooltip,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const ColoredBox(color: Color(0xFFD9B89C));
                    },
                  ),
                  DefaultTabController(
                    length: 2,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(40, 28, 40, 28),
                      child: Column(
                        children: [
                          const Text(
                            'Paused',
                            style: TextStyle(
                              color: panelTextColor,
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Seed: $seedCode',
                            style: const TextStyle(
                              color: panelLabelColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const TabBar(
                            labelColor: panelTextColor,
                            unselectedLabelColor: panelLabelColor,
                            indicatorColor: panelTextColor,
                            tabs: [
                              Tab(text: 'Stats'),
                              Tab(text: 'Audio'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _StatsSection(
                                  name: name,
                                  intelligence: intelligence,
                                  health: health,
                                  size: size,
                                  speed: speed,
                                  panelLabelColor: panelLabelColor,
                                  panelTextColor: panelTextColor,
                                ),
                                _VolumeSection(
                                  muted: muted,
                                  masterVolume: masterVolume,
                                  musicVolume: musicVolume,
                                  sfxVolume: sfxVolume,
                                  onToggleMute: onToggleMute,
                                  onMasterVolumeChanged: onMasterVolumeChanged,
                                  onMusicVolumeChanged: onMusicVolumeChanged,
                                  onSfxVolumeChanged: onSfxVolumeChanged,
                                  panelLabelColor: panelLabelColor,
                                  panelTextColor: panelTextColor,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: onResume,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFF1B765),
                                    foregroundColor: panelTextColor,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  child: const Text(
                                    'Resume',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: onRestart,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFCE8A53),
                                    foregroundColor: panelTextColor,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  child: const Text(
                                    'Restart',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 24)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _IconStatRow extends StatelessWidget {
  const _IconStatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  final Widget icon;
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 34, height: 34, child: icon),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: labelColor, fontSize: 24)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SizePlaceholderIcon extends StatelessWidget {
  const _SizePlaceholderIcon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x885A4132), width: 2),
      ),
      child: const Center(
        child: Text(
          '?',
          style: TextStyle(
            color: Color(0xFF5A4132),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.name,
    required this.intelligence,
    required this.health,
    required this.size,
    required this.speed,
    required this.panelLabelColor,
    required this.panelTextColor,
  });

  final String name;
  final String intelligence;
  final String health;
  final String size;
  final String speed;
  final Color panelLabelColor;
  final Color panelTextColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatRow(
          label: 'Name',
          value: name,
          labelColor: panelLabelColor,
          valueColor: panelTextColor,
        ),
        const SizedBox(height: 8),
        _IconStatRow(
          icon: Image.asset(
            AssetPaths.uiIntelligenceLogo,
            width: 34,
            height: 34,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(width: 34, height: 34);
            },
          ),
          label: 'Intelligence',
          value: intelligence,
          labelColor: panelLabelColor,
          valueColor: panelTextColor,
        ),
        const SizedBox(height: 8),
        _IconStatRow(
          icon: Image.asset(
            AssetPaths.uiHeartLogo,
            width: 34,
            height: 34,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(width: 34, height: 34);
            },
          ),
          label: 'Health',
          value: health,
          labelColor: panelLabelColor,
          valueColor: panelTextColor,
        ),
        const SizedBox(height: 8),
        _IconStatRow(
          icon: const _SizePlaceholderIcon(),
          label: 'Size',
          value: size,
          labelColor: panelLabelColor,
          valueColor: panelTextColor,
        ),
        const SizedBox(height: 8),
        _IconStatRow(
          icon: Image.asset(
            AssetPaths.uiSpeedLogo,
            width: 34,
            height: 34,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(width: 34, height: 34);
            },
          ),
          label: 'Speed',
          value: speed,
          labelColor: panelLabelColor,
          valueColor: panelTextColor,
        ),
      ],
    );
  }
}

class _VolumeSection extends StatelessWidget {
  const _VolumeSection({
    required this.muted,
    required this.masterVolume,
    required this.musicVolume,
    required this.sfxVolume,
    required this.onToggleMute,
    required this.onMasterVolumeChanged,
    required this.onMusicVolumeChanged,
    required this.onSfxVolumeChanged,
    required this.panelLabelColor,
    required this.panelTextColor,
  });

  final bool muted;
  final double masterVolume;
  final double musicVolume;
  final double sfxVolume;
  final VoidCallback onToggleMute;
  final ValueChanged<double> onMasterVolumeChanged;
  final ValueChanged<double> onMusicVolumeChanged;
  final ValueChanged<double> onSfxVolumeChanged;
  final Color panelLabelColor;
  final Color panelTextColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Audio',
              style: TextStyle(
                color: panelTextColor,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            FilledButton.tonal(
              onPressed: onToggleMute,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFECC68B),
                foregroundColor: panelTextColor,
              ),
              child: Text(muted ? 'Unmute' : 'Mute'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _VolumeSliderRow(
          label: 'Master',
          value: masterVolume,
          onChanged: onMasterVolumeChanged,
          labelColor: panelLabelColor,
          valueColor: panelTextColor,
        ),
        _VolumeSliderRow(
          label: 'Music',
          value: musicVolume,
          onChanged: onMusicVolumeChanged,
          labelColor: panelLabelColor,
          valueColor: panelTextColor,
        ),
        _VolumeSliderRow(
          label: 'SFX',
          value: sfxVolume,
          onChanged: onSfxVolumeChanged,
          labelColor: panelLabelColor,
          valueColor: panelTextColor,
        ),
      ],
    );
  }
}

class _VolumeSliderRow extends StatelessWidget {
  const _VolumeSliderRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.labelColor,
    required this.valueColor,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final int percent = (value * 100).round();
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: TextStyle(color: labelColor, fontSize: 20)),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(0.0, 1.0),
            min: 0,
            max: 1,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 46,
          child: Text(
            '$percent%',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
