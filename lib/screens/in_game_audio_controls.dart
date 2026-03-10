import 'package:flutter/material.dart';

class InGameAudioControls extends StatelessWidget {
  const InGameAudioControls({
    super.key,
    required this.muted,
    required this.onToggleMute,
  });

  final bool muted;
  final VoidCallback onToggleMute;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.topRight,
        child: Material(
          color: Colors.black.withValues(alpha: 0.35),
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: onToggleMute,
            icon: Icon(muted ? Icons.volume_off : Icons.volume_up),
            color: Colors.white,
            tooltip: muted ? 'Unmute' : 'Mute',
          ),
        ),
      ),
    );
  }
}
