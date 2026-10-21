import 'package:flutter/material.dart';
import 'package:nodalis_ui/nodalis_ui.dart';
import '../../session/progress_repository.dart';

/// Modal dialog providing user preferences, accessibility options, and data controls.
class SettingsDialog extends StatelessWidget {
  final ProgressRepository progressRepository;
  final ValueChanged<NodalisThemeMode> onThemeChanged;
  final NodalisThemeMode currentThemeMode;

  const SettingsDialog({
    super.key,
    required this.progressRepository,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  static Future<void> show(
    BuildContext context, {
    required ProgressRepository progressRepository,
    required ValueChanged<NodalisThemeMode> onThemeChanged,
    required NodalisThemeMode currentThemeMode,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => SettingsDialog(
        progressRepository: progressRepository,
        onThemeChanged: onThemeChanged,
        currentThemeMode: currentThemeMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = NodalisTheme.of(context);
    final palette = theme.palette;

    return Dialog(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NodalisDimensions.radiusLarge),
        side: BorderSide(color: palette.surfaceSubtle, width: 1.0),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: AnimatedBuilder(
            animation: progressRepository,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.settings_outlined,
                            size: 22.0,
                            color: palette.islandSelectedStroke,
                          ),
                          const SizedBox(width: 10.0),
                          Text(
                            'Settings',
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: palette.textSecondary),
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Section 1: Display Theme
                  Text(
                    'APPEARANCE',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: NodalisThemeMode.values.map((mode) {
                      final isSelected = currentThemeMode == mode;
                      return ChoiceChip(
                        label: Text(mode.label),
                        selected: isSelected,
                        selectedColor:
                            palette.islandSelectedStroke.withAlpha(40),
                        backgroundColor: palette.surfaceSubtle,
                        side: BorderSide(
                          color: isSelected
                              ? palette.islandSelectedStroke
                              : Colors.transparent,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? palette.islandSelectedStroke
                              : palette.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12.0,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            progressRepository.triggerHaptic();
                            onThemeChanged(mode);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20.0),

                  // Section 2: Accessibility & Ergonomics
                  Text(
                    'ACCESSIBILITY & CONTROLS',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4.0),

                  // Haptics switch
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Haptic Feedback',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Tactile pulses on connection and completion',
                      style:
                          TextStyle(color: palette.textMuted, fontSize: 11.0),
                    ),
                    value: progressRepository.hapticsEnabled,
                    activeColor: palette.islandSelectedStroke,
                    onChanged: (val) {
                      progressRepository.updateSettings(hapticsEnabled: val);
                      if (val) progressRepository.triggerHaptic();
                    },
                  ),

                  // Multi-Channel Shapes
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Multi-Channel Status Shapes',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Concentric rings and pip markers for color-blind clarity',
                      style:
                          TextStyle(color: palette.textMuted, fontSize: 11.0),
                    ),
                    value: progressRepository.accessibilityShapes,
                    activeColor: palette.islandSelectedStroke,
                    onChanged: (val) {
                      progressRepository.triggerHaptic();
                      progressRepository.updateSettings(
                          accessibilityShapes: val);
                    },
                  ),

                  // Reduced motion
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Reduce Motion',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Instant transitions without kinetic motion',
                      style:
                          TextStyle(color: palette.textMuted, fontSize: 11.0),
                    ),
                    value: progressRepository.reduceMotion,
                    activeColor: palette.islandSelectedStroke,
                    onChanged: (val) {
                      progressRepository.triggerHaptic();
                      progressRepository.updateSettings(reduceMotion: val);
                    },
                  ),

                  const SizedBox(height: 12.0),

                  // Section 3: Reset Progress Action
                  Divider(color: palette.surfaceSubtle),
                  const SizedBox(height: 4.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: palette.islandExceededStroke,
                        ),
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 18.0),
                        label: const Text('Reset Progression'),
                        onPressed: () =>
                            _confirmResetProgress(context, palette),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.islandSelectedStroke,
                          foregroundColor: palette.background,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                NodalisDimensions.radiusSmall),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _confirmResetProgress(BuildContext context, NodalisPalette palette) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: palette.surface,
          title: Text(
            'Reset Progress?',
            style: TextStyle(
                color: palette.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'This will clear all completed levels and move records across all chapters. This action cannot be undone.',
            style: TextStyle(color: palette.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child:
                  Text('Cancel', style: TextStyle(color: palette.textPrimary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.islandExceededStroke,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                progressRepository.resetProgress();
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Reset All Progress'),
            ),
          ],
        );
      },
    );
  }
}
