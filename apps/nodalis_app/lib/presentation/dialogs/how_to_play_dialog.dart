import 'package:flutter/material.dart';
import 'package:nodalis_ui/nodalis_ui.dart';

/// Modal dialog providing visual, step-by-step instructions on puzzle rules and gestures.
class HowToPlayDialog extends StatelessWidget {
  const HowToPlayDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const HowToPlayDialog(),
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
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480.0, maxHeight: 620.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: palette.islandSelectedStroke.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.help_outline_rounded,
                          color: palette.islandSelectedStroke,
                          size: 24.0,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Text(
                        'How to Play',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: palette.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Scrollable Rules List
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _RuleCard(
                      icon: Icons.hub_rounded,
                      title: '1. The Objective',
                      description:
                          'Connect all islands with bridges into a single connected network.',
                      palette: palette,
                    ),
                    const SizedBox(height: 12.0),
                    _RuleCard(
                      icon: Icons.filter_1_rounded,
                      title: '2. Island Numbers',
                      description:
                          'The number inside each circle is the exact number of bridges that must connect to it. The dots below each number track your progress.',
                      palette: palette,
                    ),
                    const SizedBox(height: 12.0),
                    _RuleCard(
                      icon: Icons.navigation_rounded,
                      title: '3. Horizontal & Vertical Only',
                      description:
                          'Bridges travel straight along the grid lines. No diagonal bridges are allowed.',
                      palette: palette,
                    ),
                    const SizedBox(height: 12.0),
                    _RuleCard(
                      icon: Icons.alt_route_rounded,
                      title: '4. Up to 2 Bridges',
                      description:
                          'You can build 1 or 2 parallel bridges between any pair of aligned islands.',
                      palette: palette,
                    ),
                    const SizedBox(height: 12.0),
                    _RuleCard(
                      icon: Icons.block_rounded,
                      title: '5. No Crossing',
                      description:
                          'Bridges can never cross other bridges or intermediate islands.',
                      palette: palette,
                    ),
                    const SizedBox(height: 16.0),
                    Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: palette.surfaceSubtle,
                        borderRadius:
                            BorderRadius.circular(NodalisDimensions.radiusMedium),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Controls & Gestures',
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            '• Drag between two islands to connect.\n'
                            '• Or tap an island, then tap an aligned neighbor.\n'
                            '• Tap an existing bridge to cycle or remove it.',
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 13.0,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16.0),

              // Got It Button
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.islandSelectedStroke,
                  foregroundColor: palette.background,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(NodalisDimensions.radiusMedium),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Got it, let\'s play',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final NodalisPalette palette;

  const _RuleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: palette.surfaceSubtle.withOpacity(0.5),
        borderRadius: BorderRadius.circular(NodalisDimensions.radiusMedium),
        border: Border.all(color: palette.surfaceSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.islandSelectedStroke, size: 22.0),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  description,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
