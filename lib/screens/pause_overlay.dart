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
      child: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxHeight < 600;
              final double titleSize = compact ? 28 : 44;
              final double seedSize = compact ? 14 : 18;
              final double buttonFontSize = compact ? 16 : 22;
              final EdgeInsets innerPad = compact
                  ? const EdgeInsets.fromLTRB(20, 16, 20, 16)
                  : const EdgeInsets.fromLTRB(40, 28, 40, 28);

              final Widget panelBody = DefaultTabController(
                length: 2,
                child: Padding(
                  padding: innerPad,
                  child: Column(
                    mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
                    children: [
                      Text(
                        'Paused',
                        style: TextStyle(
                          color: panelTextColor,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seed: $seedCode',
                        style: TextStyle(
                          color: panelLabelColor,
                          fontSize: seedSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 12),
                      const TabBar(
                        labelColor: panelTextColor,
                        unselectedLabelColor: panelLabelColor,
                        indicatorColor: panelTextColor,
                        tabs: [
                          Tab(text: 'Stats'),
                          Tab(text: 'Audio'),
                        ],
                      ),
                      SizedBox(height: compact ? 8 : 12),
                      if (compact)
                        SizedBox(
                          height: 180,
                          child: TabBarView(
                            children: [
                              SingleChildScrollView(
                                child: _StatsSection(
                                  name: name,
                                  intelligence: intelligence,
                                  health: health,
                                  size: size,
                                  speed: speed,
                                  panelLabelColor: panelLabelColor,
                                  panelTextColor: panelTextColor,
                                  compact: true,
                                ),
                              ),
                              SingleChildScrollView(
                                child: _VolumeSection(
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
                              ),
                            ],
                          ),
                        )
                      else
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
                      SizedBox(height: compact ? 8 : 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: onResume,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFF1B765),
                                foregroundColor: panelTextColor,
                                padding: EdgeInsets.symmetric(
                                  vertical: compact ? 6 : 10,
                                ),
                              ),
                              child: Text(
                                'Resume',
                                style: TextStyle(
                                  fontSize: buttonFontSize,
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
                                padding: EdgeInsets.symmetric(
                                  vertical: compact ? 6 : 10,
                                ),
                              ),
                              child: Text(
                                'Restart',
                                style: TextStyle(
                                  fontSize: buttonFontSize,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 8 : 20),
                    ],
                  ),
                ),
              );

              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          AssetPaths.uiTooltip,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const ColoredBox(color: Color(0xFFD9B89C));
                          },
                        ),
                      ),
                      if (compact)
                        panelBody
                      else
                        AspectRatio(aspectRatio: 773 / 801, child: panelBody),
                    ],
                  ),
                ),
              );
            },
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
    this.fontSize = 24,
  });

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(color: labelColor, fontSize: fontSize),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: fontSize,
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
    this.fontSize = 24,
    this.iconSize = 34,
  });

  final Widget icon;
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  final double fontSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: iconSize, height: iconSize, child: icon),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: labelColor, fontSize: fontSize),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: fontSize,
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
    this.compact = false,
  });

  final String name;
  final String intelligence;
  final String health;
  final String size;
  final String speed;
  final Color panelLabelColor;
  final Color panelTextColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double fontSize = compact ? 18 : 24;
    final double iconSize = compact ? 26 : 34;
    final double gap = compact ? 4 : 8;

    return Column(
      children: [
        _StatRow(
          label: 'Name',
          value: name,
          labelColor: panelLabelColor,
          valueColor: panelTextColor,
          fontSize: fontSize,
        ),
        SizedBox(height: gap),
        _IconStatRow(
          icon: Image.asset(
            AssetPaths.uiIntelligenceLogo,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return SizedBox(width: iconSize, height: iconSize);
            },
          ),
          label: 'Intelligence',
          value: intelligence,
          labelColor: panelLabelColor,
          valueColor: panelTextColor,
          fontSize: fontSize,
          iconSize: iconSize,
        ),
        SizedBox(height: gap),
        _IconStatRow(
          icon: Image.asset(
            AssetPaths.uiHeartLogo,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return SizedBox(width: iconSize, height: iconSize);
            },
          ),
          label: 'Health',
          value: health,
          labelColor: panelLabelColor,
          valueColor: panelTextColor,
          fontSize: fontSize,
          iconSize: iconSize,
        ),
        SizedBox(height: gap),
        _IconStatRow(
          icon: const _SizePlaceholderIcon(),
          label: 'Size',
          value: size,
          labelColor: panelLabelColor,
          valueColor: panelTextColor,
          fontSize: fontSize,
          iconSize: iconSize,
        ),
        SizedBox(height: gap),
        _IconStatRow(
          icon: Image.asset(
            AssetPaths.uiSpeedLogo,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return SizedBox(width: iconSize, height: iconSize);
            },
          ),
          label: 'Speed',
          value: speed,
          labelColor: panelLabelColor,
          valueColor: panelTextColor,
          fontSize: fontSize,
          iconSize: iconSize,
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
