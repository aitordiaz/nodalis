import 'package:flutter/material.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';
import 'package:nodalis_ui/nodalis_ui.dart';
import '../../content/level_repository.dart';
import '../../session/game_session.dart';
import '../../session/progress_repository.dart';
import 'gameplay_screen.dart';

/// Chapter level browser displaying progression cards, unlock states, and completion marks.
class LevelSelectScreen extends StatelessWidget {
  final LevelRepository levelRepository;
  final ProgressRepository progressRepository;
  final VoidCallback onToggleTheme;
  final bool isDark;

  const LevelSelectScreen({
    super.key,
    required this.levelRepository,
    required this.progressRepository,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = NodalisTheme.of(context);
    final palette = theme.palette;
    final chapter1Levels = levelRepository.getChapterLevels(1);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NODALIS',
                          style: TextStyle(
                            color: palette.islandSelectedStroke,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'Chapter 1: First Connections',
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: palette.textPrimary,
                    ),
                    tooltip: 'Toggle Theme',
                    onPressed: onToggleTheme,
                  ),
                ],
              ),
            ),

            // Level Cards Grid
            Expanded(
              child: AnimatedBuilder(
                animation: progressRepository,
                builder: (context, _) {
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 12.0),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180.0,
                      mainAxisSpacing: 16.0,
                      crossAxisSpacing: 16.0,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: chapter1Levels.length,
                    itemBuilder: (context, index) {
                      final level = chapter1Levels[index];
                      final isUnlocked = progressRepository.isLevelUnlocked(
                          level, chapter1Levels);
                      final isCompleted =
                          progressRepository.isLevelCompleted(level.id);
                      final bestMoves =
                          progressRepository.getBestMoves(level.id);

                      return _buildLevelCard(
                        context: context,
                        level: level,
                        isUnlocked: isUnlocked,
                        isCompleted: isCompleted,
                        bestMoves: bestMoves,
                        palette: palette,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard({
    required BuildContext context,
    required LevelDefinition level,
    required bool isUnlocked,
    required bool isCompleted,
    required int? bestMoves,
    required NodalisPalette palette,
  }) {
    final cardColor = isCompleted
        ? palette.islandSatisfiedFill
        : (isUnlocked
            ? palette.surface
            : palette.surfaceSubtle.withAlpha(128));

    final borderColor = isCompleted
        ? palette.islandSatisfiedStroke
        : (isUnlocked ? palette.surfaceSubtle : Colors.transparent);

    return InkWell(
      onTap: isUnlocked
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) {
                    final session = GameSession(level: level);
                    return GameplayScreen(
                      session: session,
                      progressRepository: progressRepository,
                      levelRepository: levelRepository,
                      onToggleTheme: onToggleTheme,
                      isDark: isDark,
                    );
                  },
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(NodalisDimensions.radiusMedium),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(NodalisDimensions.radiusMedium),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${level.indexInChapter}',
                  style: TextStyle(
                    color: isUnlocked ? palette.textPrimary : palette.textMuted,
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isUnlocked)
                  Icon(Icons.lock_outline_rounded,
                      size: 18.0, color: palette.textMuted)
                else if (isCompleted)
                  Icon(Icons.check_circle_rounded,
                      size: 20.0, color: palette.islandSatisfiedStroke),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level.metadata.difficultyTier.value.toUpperCase(),
                  style: TextStyle(
                    color:
                        isUnlocked ? palette.textSecondary : palette.textMuted,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  isCompleted && bestMoves != null
                      ? 'Best: $bestMoves'
                      : '${level.islands.length} islands',
                  style: TextStyle(
                    color: isUnlocked
                        ? palette.textMuted
                        : palette.textMuted.withAlpha(153),
                    fontSize: 11.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
