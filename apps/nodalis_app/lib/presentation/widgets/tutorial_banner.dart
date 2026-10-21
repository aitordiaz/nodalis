import 'package:flutter/material.dart';
import 'package:nodalis_domain/nodalis_domain.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';
import 'package:nodalis_ui/nodalis_ui.dart';

/// Contextual, non-intrusive tutorial guidance banner for early and active levels.
class TutorialBanner extends StatelessWidget {
  final LevelDefinition level;
  final Board board;

  const TutorialBanner({
    super.key,
    required this.level,
    required this.board,
  });

  @override
  Widget build(BuildContext context) {
    final theme = NodalisTheme.of(context);
    final palette = theme.palette;

    final hint = _getHintForState(level, board);
    if (hint == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(NodalisDimensions.radiusMedium),
          border: Border.all(
            color: palette.islandSelectedStroke.withOpacity(0.35),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hint.icon,
              size: 20.0,
              color: palette.islandSelectedStroke,
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                hint.message,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static ({IconData icon, String message})? _getHintForState(
    LevelDefinition level,
    Board board,
  ) {
    final activeBridges =
        board.bridges.values.where((b) => b.isActive).length;
    final totalIslands = board.islands.length;
    final satisfiedIslands = board.islands.values
        .where((i) => board.isIslandSatisfied(i.id))
        .length;

    if (level.indexInChapter == 1) {
      if (activeBridges == 0) {
        return (
          icon: Icons.touch_app_rounded,
          message:
              'Drag between the two islands or tap them to build a bridge.',
        );
      } else {
        return (
          icon: Icons.check_circle_outline_rounded,
          message: 'Both islands satisfied (1 bridge each)! Puzzle solved.',
        );
      }
    } else if (level.indexInChapter == 2) {
      if (satisfiedIslands == 0) {
        return (
          icon: Icons.lightbulb_outline_rounded,
          message:
              'The number in each circle is the bridge count needed. Connect island 2 to both 1s.',
        );
      } else if (satisfiedIslands < totalIslands) {
        return (
          icon: Icons.info_outline_rounded,
          message:
              'Track the dots under each number: $satisfiedIslands of $totalIslands islands satisfied.',
        );
      } else {
        return (
          icon: Icons.check_circle_outline_rounded,
          message: 'All numbers matched! Well done.',
        );
      }
    } else if (level.indexInChapter == 3) {
      return (
        icon: Icons.alt_route_rounded,
        message:
            'Bridges can travel only horizontally or vertically and cannot cross each other.',
      );
    } else if (level.indexInChapter == 4) {
      return (
        icon: Icons.hub_rounded,
        message:
            'Up to 2 bridges can connect two islands. All islands must form one network.',
      );
    }

    // Default status summary for later levels
    return (
      icon: Icons.hub_rounded,
      message:
          'Satisfied: $satisfiedIslands of $totalIslands islands • Tap a bridge to cycle or remove it.',
    );
  }
}
