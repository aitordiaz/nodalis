import 'package:flutter/material.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';
import 'package:nodalis_ui/nodalis_ui.dart';
import '../../content/level_repository.dart';
import '../../session/game_session.dart';
import '../../session/progress_repository.dart';
import '../dialogs/how_to_play_dialog.dart';
import 'gameplay_screen.dart';

/// Chapter level browser displaying progression cards, unlock states, and completion marks.
class LevelSelectScreen extends StatefulWidget {
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
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  int _selectedChapter = 1;

  @override
  void initState() {
    super.initState();
    final lastPlayed = widget.progressRepository.lastPlayedLevelId;
    if (lastPlayed != null && lastPlayed.startsWith('ch02_')) {
      _selectedChapter = 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = NodalisTheme.of(context);
    final palette = theme.palette;
    final currentChapterLevels =
        widget.levelRepository.getChapterLevels(_selectedChapter);
    final prevChapterLevels = _selectedChapter > 1
        ? widget.levelRepository.getChapterLevels(_selectedChapter - 1)
        : null;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
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
                          'Chapter $_selectedChapter: ${widget.levelRepository.getChapterTitle(_selectedChapter)}',
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
                      Icons.help_outline_rounded,
                      color: palette.textPrimary,
                    ),
                    tooltip: 'How to Play',
                    onPressed: () => HowToPlayDialog.show(context),
                  ),
                  IconButton(
                    icon: Icon(
                      widget.isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: palette.textPrimary,
                    ),
                    tooltip: 'Toggle Theme',
                    onPressed: widget.onToggleTheme,
                  ),
                ],
              ),
            ),

            // Chapter Selector Pills
            if (widget.levelRepository.chapterIds.length > 1)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: widget.levelRepository.chapterIds.map((chId) {
                      final isSelected = chId == _selectedChapter;
                      final chLevels =
                          widget.levelRepository.getChapterLevels(chId);
                      final completedCount = chLevels
                          .where((l) =>
                              widget.progressRepository.isLevelCompleted(l.id))
                          .length;

                      return Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedChapter = chId);
                          },
                          borderRadius: BorderRadius.circular(
                              NodalisDimensions.radiusMedium),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14.0, vertical: 8.0),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? palette.islandSelectedStroke
                                      .withOpacity(0.12)
                                  : palette.surface,
                              borderRadius: BorderRadius.circular(
                                  NodalisDimensions.radiusMedium),
                              border: Border.all(
                                color: isSelected
                                    ? palette.islandSelectedStroke
                                    : palette.surfaceSubtle,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Chapter $chId',
                                  style: TextStyle(
                                    color: isSelected
                                        ? palette.islandSelectedStroke
                                        : palette.textPrimary,
                                    fontSize: 13.0,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6.0),
                                Text(
                                  '$completedCount/${chLevels.length}',
                                  style: TextStyle(
                                    color: isSelected
                                        ? palette.islandSelectedStroke
                                        : palette.textMuted,
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // Level Cards Grid
            Expanded(
              child: AnimatedBuilder(
                animation: widget.progressRepository,
                builder: (context, _) {
                  final nextLevel = widget.progressRepository
                      .getNextRecommendedLevel(currentChapterLevels);
                  final hasProgress =
                      widget.progressRepository.completedLevelIds.isNotEmpty;

                  return Column(
                    children: [
                      if (hasProgress && nextLevel != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 6.0),
                          child: InkWell(
                            onTap: () => _openLevel(context, nextLevel),
                            borderRadius: BorderRadius.circular(
                                NodalisDimensions.radiusMedium),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 12.0),
                              decoration: BoxDecoration(
                                color: palette.islandSelectedStroke
                                    .withOpacity(0.08),
                                borderRadius: BorderRadius.circular(
                                    NodalisDimensions.radiusMedium),
                                border: Border.all(
                                  color: palette.islandSelectedStroke
                                      .withOpacity(0.35),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: palette.islandSelectedStroke,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.play_arrow_rounded,
                                      color: palette.background,
                                      size: 20.0,
                                    ),
                                  ),
                                  const SizedBox(width: 12.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'CONTINUE PUZZLE',
                                          style: TextStyle(
                                            color: palette.islandSelectedStroke,
                                            fontSize: 10.0,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2.0),
                                        Text(
                                          'Level ${nextLevel.indexInChapter} • ${nextLevel.metadata.difficultyTier.value.toUpperCase()}',
                                          style: TextStyle(
                                            color: palette.textPrimary,
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: palette.islandSelectedStroke,
                                    size: 20.0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 12.0),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 180.0,
                            mainAxisSpacing: 16.0,
                            crossAxisSpacing: 16.0,
                            childAspectRatio: 1.15,
                          ),
                          itemCount: currentChapterLevels.length,
                          itemBuilder: (context, index) {
                            final level = currentChapterLevels[index];
                            final isUnlocked = widget.progressRepository
                                .isLevelUnlocked(level, currentChapterLevels,
                                    previousChapterLevels: prevChapterLevels);
                            final isCompleted = widget.progressRepository
                                .isLevelCompleted(level.id);
                            final bestMoves = widget.progressRepository
                                .getBestMoves(level.id);

                            return _buildLevelCard(
                              context: context,
                              level: level,
                              isUnlocked: isUnlocked,
                              isCompleted: isCompleted,
                              bestMoves: bestMoves,
                              palette: palette,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLevel(BuildContext context, LevelDefinition level) {
    widget.progressRepository.setLastPlayed(level.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          final session = GameSession(level: level);
          return GameplayScreen(
            session: session,
            progressRepository: widget.progressRepository,
            levelRepository: widget.levelRepository,
            onToggleTheme: widget.onToggleTheme,
            isDark: widget.isDark,
          );
        },
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
        : (isUnlocked ? palette.surface : palette.surfaceSubtle.withAlpha(128));

    final borderColor = isCompleted
        ? palette.islandSatisfiedStroke
        : (isUnlocked ? palette.surfaceSubtle : Colors.transparent);

    return InkWell(
      onTap: isUnlocked ? () => _openLevel(context, level) : null,
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
