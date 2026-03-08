import 'package:flutter/material.dart';
import 'package:game_jam/core/constants/asset_paths.dart';
import 'package:game_jam/game/character/model/character_profile.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.seedCode,
    required this.characterProfile,
    required this.currentHealth,
    required this.maxHealth,
  });

  final VoidCallback onResume;
  final String seedCode;
  final CharacterProfile? characterProfile;
  final int? currentHealth;
  final int? maxHealth;

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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 28, 40, 28),
                    child: Column(
                      children: [
                        const Text(
                          'Paused',
                          style: TextStyle(
                            color: panelTextColor,
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Seed: $seedCode',
                          style: const TextStyle(
                            color: panelLabelColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 28),
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
                        const Spacer(),
                        FilledButton(
                          onPressed: onResume,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF1B765),
                            foregroundColor: panelTextColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 46,
                              vertical: 14,
                            ),
                          ),
                          child: const Text(
                            'Resume',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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
