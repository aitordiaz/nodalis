import 'package:flutter/material.dart';
import 'package:nodalis_solver/nodalis_solver.dart';
import 'package:nodalis_ui/nodalis_ui.dart';

/// Modal dialog providing graded, non-spoiling hints with progressive disclosure.
class DeductiveHintDialog extends StatefulWidget {
  final DeductiveHint hint;
  final VoidCallback? onUndo;
  final void Function(int fromId, int toId)? onApplyStep;

  const DeductiveHintDialog({
    super.key,
    required this.hint,
    this.onUndo,
    this.onApplyStep,
  });

  static Future<void> show({
    required BuildContext context,
    required DeductiveHint hint,
    VoidCallback? onUndo,
    void Function(int fromId, int toId)? onApplyStep,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => DeductiveHintDialog(
        hint: hint,
        onUndo: onUndo,
        onApplyStep: onApplyStep,
      ),
    );
  }

  @override
  State<DeductiveHintDialog> createState() => _DeductiveHintDialogState();
}

class _DeductiveHintDialogState extends State<DeductiveHintDialog> {
  bool _revealedInsight = false;
  bool _revealedSolution = false;

  @override
  Widget build(BuildContext context) {
    final theme = NodalisTheme.of(context);
    final palette = theme.palette;
    final hint = widget.hint;

    return Dialog(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NodalisDimensions.radiusLarge),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460.0, maxHeight: 600.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
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
                          color: hint.isMistake
                              ? Colors.amber.withOpacity(0.15)
                              : palette.islandSelectedStroke.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hint.isMistake
                              ? Icons.warning_amber_rounded
                              : Icons.lightbulb_rounded,
                          color: hint.isMistake
                              ? Colors.amber.shade700
                              : palette.islandSelectedStroke,
                          size: 24.0,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Text(
                        hint.isMistake ? 'Board Review' : 'Logical Hint',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon:
                        Icon(Icons.close_rounded, color: palette.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Content List
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Stage 1: Nudge
                    _HintStageCard(
                      badge: 'Nudge',
                      badgeColor: palette.islandSelectedStroke,
                      icon: Icons.search_rounded,
                      content: hint.nudge,
                      palette: palette,
                    ),

                    // Stage 2: Logical Insight
                    if (!hint.isMistake &&
                        hint.category != HintCategory.alreadySolved) ...[
                      const SizedBox(height: 12.0),
                      if (!_revealedInsight)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.textPrimary,
                            side: BorderSide(color: palette.surfaceSubtle),
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  NodalisDimensions.radiusMedium),
                            ),
                          ),
                          onPressed: () {
                            setState(() => _revealedInsight = true);
                          },
                          icon:
                              const Icon(Icons.psychology_outlined, size: 18.0),
                          label: const Text('Explain the Logic (Insight)'),
                        )
                      else
                        _HintStageCard(
                          badge: 'Insight',
                          badgeColor: Colors.deepPurpleAccent,
                          icon: Icons.psychology_rounded,
                          content: hint.insight,
                          palette: palette,
                        ),
                    ],

                    // Stage 3: Solution Step
                    if (!hint.isMistake &&
                        hint.category != HintCategory.alreadySolved) ...[
                      const SizedBox(height: 12.0),
                      if (!_revealedSolution)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.textPrimary,
                            side: BorderSide(color: palette.surfaceSubtle),
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  NodalisDimensions.radiusMedium),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _revealedInsight = true;
                              _revealedSolution = true;
                            });
                          },
                          icon:
                              const Icon(Icons.touch_app_outlined, size: 18.0),
                          label: const Text('Show Exact Move'),
                        )
                      else
                        _HintStageCard(
                          badge: 'Action',
                          badgeColor: Colors.teal,
                          icon: Icons.touch_app_rounded,
                          content: hint.solutionStep,
                          palette: palette,
                        ),
                    ],

                    // Mistake Explanation
                    if (hint.isMistake) ...[
                      const SizedBox(height: 12.0),
                      _HintStageCard(
                        badge: 'Analysis',
                        badgeColor: Colors.amber.shade800,
                        icon: Icons.info_outline_rounded,
                        content: hint.insight,
                        palette: palette,
                      ),
                      const SizedBox(height: 12.0),
                      _HintStageCard(
                        badge: 'Correction',
                        badgeColor: Colors.amber.shade800,
                        icon: Icons.build_circle_outlined,
                        content: hint.solutionStep,
                        palette: palette,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18.0),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hint.isMistake && widget.onUndo != null)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onUndo?.call();
                      },
                      icon: const Icon(Icons.undo_rounded, size: 18.0),
                      label: const Text('Undo Last Move'),
                    )
                  else if (_revealedSolution &&
                      hint.secondaryIslandId != null &&
                      widget.onApplyStep != null)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.islandSelectedStroke,
                        foregroundColor: palette.background,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onApplyStep?.call(
                          hint.primaryIslandId,
                          hint.secondaryIslandId!,
                        );
                      },
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 18.0),
                      label: const Text('Apply Step'),
                    )
                  else
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.islandSelectedStroke,
                        foregroundColor: palette.background,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Got it'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintStageCard extends StatelessWidget {
  final String badge;
  final Color badgeColor;
  final IconData icon;
  final String content;
  final NodalisPalette palette;

  const _HintStageCard({
    required this.badge,
    required this.badgeColor,
    required this.icon,
    required this.content,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(NodalisDimensions.radiusMedium),
        border: Border.all(color: palette.surfaceSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.0, color: badgeColor),
              const SizedBox(width: 6.0),
              Text(
                badge.toUpperCase(),
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            content,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 14.0,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
