import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/core/config/ui_config.dart';
import 'package:game_jam/game/character/model/character_generation_state.dart';
import 'package:game_jam/game/character/model/character_profile.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({
    super.key,
    required this.onStart,
    required this.onReroll,
    required this.onPointCandidate,
    required this.generationState,
  });

  final VoidCallback onStart;
  final VoidCallback onReroll;
  final ValueChanged<int> onPointCandidate;
  final CharacterGenerationState? generationState;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final TextEditingController _seedController;

  @override
  void initState() {
    super.initState();
    _seedController = TextEditingController(text: _seedValue(widget));
  }

  @override
  void didUpdateWidget(covariant MenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String previousSeed = _seedValue(oldWidget);
    final String nextSeed = _seedValue(widget);
    if (previousSeed != nextSeed && _seedController.text != nextSeed) {
      _seedController.value = TextEditingValue(
        text: nextSeed,
        selection: TextSelection.collapsed(offset: nextSeed.length),
      );
    }
  }

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  String _seedValue(MenuScreen screen) =>
      screen.generationState?.seedCode ?? '-';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: MenuUi.panelMaxWidth),
        child: SizedBox(
          child: Padding(
            padding: const EdgeInsets.all(MenuUi.panelPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  MenuUi.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MenuUi.titleFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                // Seed input
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: MenuUi.seedInputWidth,
                      height: MenuUi.seedInputHeight,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(AssetPaths.plank),
                          fit: BoxFit
                              .fill, // Ensures the plank stretches to fill the container
                        ),
                      ),
                      child: TextField(
                        maxLength: MenuUi.seedCodeLength,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9]'),
                          ),
                          UpperCaseTextFormatter(),
                        ],
                        buildCounter:
                            (
                              ctx, {
                              required int currentLength,
                              required bool isFocused,
                              maxLength,
                            }) => null,
                        controller: _seedController,
                        onChanged: (value) => {
                          if (value.length == MenuUi.seedCodeLength)
                            {
                              debugPrint(
                                'Seed submitted: ${_seedController.text}',
                              ),
                            },
                        },
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          letterSpacing: MenuUi.seedLetterSpacing,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder
                              .none, // Remove default TextField border
                          isDense: true, // Reduce height of the TextField
                          contentPadding:
                              EdgeInsets.zero, // Remove default padding
                          hintStyle: TextStyle(
                            letterSpacing: MenuUi.seedHintLetterSpacing,
                          ),
                        ),
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      iconSize: MenuUi.refreshIconSize,
                      splashColor: Colors.transparent, // Keeps it clean looking
                      highlightColor: Colors.transparent,
                      onPressed: () {
                        _seedController
                            .clear(); // Clears the text field visually
                        debugPrint('Seed reset');
                        widget.onReroll();
                        // If you need to trigger a game event, do it here!
                      },
                    ),
                  ],
                ),

                const SizedBox(height: MenuUi.pickerTopSpacing),
                _CharacterPicker(
                  generationState: widget.generationState,
                  onPointCandidate: widget.onPointCandidate,
                  onStart: widget.onStart,
                ),
                const SizedBox(height: MenuUi.pickerBottomSpacing),
                _CharacterDetailsPanel(generationState: widget.generationState),
                const SizedBox(height: MenuUi.sectionSpacing),

                const SizedBox(height: MenuUi.sectionSpacing),
                const Text(
                  MenuUi.controlsHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterDetailsPanel extends StatelessWidget {
  const _CharacterDetailsPanel({required this.generationState});

  final CharacterGenerationState? generationState;

  @override
  Widget build(BuildContext context) {
    final CharacterGenerationState? state = generationState;
    final String name = state?.profile.name.display ?? '-';
    final String sprite = state?.profile.spriteId ?? '-';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: MenuUi.detailsBackgroundAlpha),
        borderRadius: BorderRadius.circular(MenuUi.detailsRadius),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MenuUi.detailsPadding),
        child: Column(
          spacing: MenuUi.detailsRowSpacing,
          children: [
            _DetailRow(label: 'Name', value: name),
            _DetailRow(label: 'Sprite', value: sprite),
          ],
        ),
      ),
    );
  }
}

class _CharacterPicker extends StatelessWidget {
  const _CharacterPicker({
    required this.generationState,
    required this.onPointCandidate,
    required this.onStart,
  });

  final CharacterGenerationState? generationState;
  final ValueChanged<int> onPointCandidate;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final CharacterGenerationState? state = generationState;
    if (state == null) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: MenuUi.frogGridSpacing,
      runSpacing: MenuUi.frogGridSpacing,
      alignment: WrapAlignment.center,
      children: List<Widget>.generate(
        state.candidateProfiles.length,
        (int index) => _CandidateFrogCard(
          profile: state.candidateProfiles[index],
          isPointed: index == state.selectedIndex,
          onPointed: () => onPointCandidate(index),
          onSelected: () {
            onPointCandidate(index);
            onStart();
          },
        ),
      ),
    );
  }
}

class _CandidateFrogCard extends StatefulWidget {
  const _CandidateFrogCard({
    required this.profile,
    required this.isPointed,
    required this.onPointed,
    required this.onSelected,
  });

  final CharacterProfile profile;
  final bool isPointed;
  final VoidCallback onPointed;
  final VoidCallback onSelected;

  @override
  State<_CandidateFrogCard> createState() => _CandidateFrogCardState();
}

class _CandidateFrogCardState extends State<_CandidateFrogCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool highlighted = widget.isPointed || _hovered;
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
        widget.onPointed();
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      child: GestureDetector(
        onTapDown: (_) => widget.onPointed(),
        onTap: widget.onSelected,
        child: AnimatedScale(
          scale: highlighted
              ? MenuUi.frogScaleHighlighted
              : MenuUi.frogScaleIdle,
          duration: UiTiming.frogAnimationDuration,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: UiTiming.frogAnimationDuration,
            width: MenuUi.frogCardSize,
            height: MenuUi.frogCardSize,
            padding: const EdgeInsets.all(MenuUi.frogCardPadding),
            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: highlighted
                    ? MenuUi.frogBackgroundAlphaHighlighted
                    : MenuUi.frogBackgroundAlphaIdle,
              ),
              borderRadius: BorderRadius.circular(MenuUi.detailsRadius),
              border: Border.all(
                color: highlighted ? Colors.amberAccent : Colors.white24,
              ),
            ),
            child: Image.asset(
              widget.profile.spriteAssetPath,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: MenuUi.detailsLabelWidth,
          child: Text(label, style: const TextStyle(color: Colors.white60)),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection, // Keeps the cursor in the correct position
    );
  }
}
