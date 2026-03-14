import 'package:flutter/material.dart';

class CreditsOverlay extends StatelessWidget {
  const CreditsOverlay({super.key, required this.onClose});

  final VoidCallback onClose;

  static const List<_CreditEntry> _credits = <_CreditEntry>[
    _CreditEntry('Alice Abadia', <String>['Art']),
    _CreditEntry('Bastien Génin', <String>['Dev', 'Art', 'Music']),
    _CreditEntry('Thomas Deléron', <String>['Art', 'Music']),
    _CreditEntry('Jason Fachan', <String>['Dev']),
    _CreditEntry('Elliot Cunningham', <String>['Dev']),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.95),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Credits',
                    style: TextStyle(
                      color: Color(0xFFF8E5B9),
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 32),
                  for (final _CreditEntry entry in _credits) ...[
                    Text(
                      entry.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.roles.join(' · '),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFB7D9D2),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Tap anywhere to close',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
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

class _CreditEntry {
  const _CreditEntry(this.name, this.roles);

  final String name;
  final List<String> roles;
}
