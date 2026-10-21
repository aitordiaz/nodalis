import 'package:flutter/material.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';
import 'package:nodalis_solver/nodalis_solver.dart';
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
  final bool? isDark;
  final NodalisThemeMode? themeMode;

  const LevelSelectScreen({
    super.key,
    required this.levelRepository,
    required this.progressRepository,
    required this.onToggleTheme,
    this.isDark,
    this.themeMode,
  });

  NodalisThemeMode get activeThemeMode =>
      themeMode ??
      (isDark == true ? NodalisThemeMode.dark : NodalisThemeMode.light);

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
                          _selectedChapter == 0
                              ? 'DAILY & INFINITE'
                              : 'NODALIS',
                          style: TextStyle(
                            color: palette.islandSelectedStroke,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          _selectedChapter == 0
                              ? 'Procedural Puzzles'
                              : 'Chapter $_selectedChapter: ${widget.levelRepository.getChapterTitle(_selectedChapter)}',
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
                      _themeIcon(widget.activeThemeMode),
                      color: palette.textPrimary,
                    ),
                    tooltip:
                        'Theme: ${widget.activeThemeMode.label} (tap to cycle)',
                    onPressed: widget.onToggleTheme,
                  ),
                ],
              ),
            ),

            // Chapter Selector Pills
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...widget.levelRepository.chapterIds.map((chId) {
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
                    }),
                    // Daily & Infinite pill
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedChapter = 0);
                        },
                        borderRadius: BorderRadius.circular(
                            NodalisDimensions.radiusMedium),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: _selectedChapter == 0
                                ? palette.islandSelectedStroke
                                    .withOpacity(0.12)
                                : palette.surface,
                            borderRadius: BorderRadius.circular(
                                NodalisDimensions.radiusMedium),
                            border: Border.all(
                              color: _selectedChapter == 0
                                  ? palette.islandSelectedStroke
                                  : palette.surfaceSubtle,
                              width: _selectedChapter == 0 ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.all_inclusive_rounded,
                                size: 14.0,
                                color: _selectedChapter == 0
                                    ? palette.islandSelectedStroke
                                    : palette.textPrimary,
                              ),
                              const SizedBox(width: 6.0),
                              Text(
                                'Daily & Infinite',
                                style: TextStyle(
                                  color: _selectedChapter == 0
                                      ? palette.islandSelectedStroke
                                      : palette.textPrimary,
                                  fontSize: 13.0,
                                  fontWeight: _selectedChapter == 0
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content Area (Infinite View or Chapter Cards Grid)
            Expanded(
              child: _selectedChapter == 0
                  ? _buildInfinitePlayView(palette)
                  : AnimatedBuilder(
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
            themeMode: widget.activeThemeMode,
          );
        },
      ),
    );
  }

  Widget _buildInfinitePlayView(NodalisPalette palette) {
    final now = DateTime.now();
    final dailySeed = now.year * 10000 + now.month * 100 + now.day;
    final dailyLevelId = 'daily_$dailySeed';
    final isDailyCompleted =
        widget.progressRepository.isLevelCompleted(dailyLevelId);
    final dailyBestMoves = widget.progressRepository.getBestMoves(dailyLevelId);

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      children: [
        // Daily Challenge Card
        Container(
          padding: const EdgeInsets.all(18.0),
          decoration: BoxDecoration(
            color: isDailyCompleted
                ? palette.islandSatisfiedFill
                : palette.surface,
            borderRadius: BorderRadius.circular(NodalisDimensions.radiusMedium),
            border: Border.all(
              color: isDailyCompleted
                  ? palette.islandSatisfiedStroke
                  : palette.islandSelectedStroke.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 18.0,
                        color: palette.islandSelectedStroke,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        'DAILY CHALLENGE',
                        style: TextStyle(
                          color: palette.islandSelectedStroke,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  if (isDailyCompleted)
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18.0,
                          color: palette.islandSatisfiedStroke,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          dailyBestMoves != null
                              ? 'Solved ($dailyBestMoves moves)'
                              : 'Solved',
                          style: TextStyle(
                            color: palette.islandSatisfiedStroke,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                dateStr,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Unique 7x7 board curated daily for all Nodalis players worldwide.',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 13.0,
                ),
              ),
              const SizedBox(height: 16.0),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.islandSelectedStroke,
                    foregroundColor: palette.background,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(NodalisDimensions.radiusSmall),
                    ),
                  ),
                  icon: Icon(isDailyCompleted
                      ? Icons.replay_rounded
                      : Icons.play_arrow_rounded),
                  label: Text(
                    isDailyCompleted
                        ? 'Replay Daily Challenge'
                        : 'Play Daily Challenge',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => _launchDailyPuzzle(dailySeed, dailyLevelId),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24.0),

        // Infinite Generator Section Header
        Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 18.0,
              color: palette.textSecondary,
            ),
            const SizedBox(width: 8.0),
            Text(
              'PROCEDURAL PUZZLES',
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        Text(
          'On-demand generation with guaranteed unique mathematical solvability.',
          style: TextStyle(
            color: palette.textMuted,
            fontSize: 12.0,
          ),
        ),
        const SizedBox(height: 14.0),

        // Difficulty Cards
        _buildDifficultyCard(
          palette: palette,
          title: 'Gentle',
          gridSize: '6x6 Grid • 6 Islands',
          description:
              'Quick logic warmup with immediate orthogonal deductions.',
          difficulty: DifficultyTier.easy,
          width: 6,
          height: 6,
          islandCount: 6,
        ),
        const SizedBox(height: 12.0),
        _buildDifficultyCard(
          palette: palette,
          title: 'Balanced',
          gridSize: '7x7 Grid • 8 Islands',
          description:
              'Rich deduction branching with double bridges and isolation traps.',
          difficulty: DifficultyTier.medium,
          width: 7,
          height: 7,
          islandCount: 8,
        ),
        const SizedBox(height: 12.0),
        _buildDifficultyCard(
          palette: palette,
          title: 'Master',
          gridSize: '8x8 Grid • 8 Islands',
          description: 'Expansive board requiring deep forward deduction.',
          difficulty: DifficultyTier.hard,
          width: 8,
          height: 8,
          islandCount: 8,
        ),
      ],
    );
  }

  void _launchDailyPuzzle(int seed, String levelId) {
    const generator = PuzzleGenerator();
    final level = generator.generate(
      width: 7,
      height: 7,
      islandCount: 8,
      seed: seed,
      difficulty: DifficultyTier.medium,
    );
    if (level == null) return;
    final dailyLevel = LevelDefinition(
      id: levelId,
      version: level.version,
      chapterId: 0,
      indexInChapter: 0,
      metadata: const LevelMetadata(
        titleKey: 'Daily Challenge',
        author: 'Nodalis Daily',
        difficultyTier: DifficultyTier.medium,
        estimatedSolveTimeSeconds: 150,
        parMoves: 10,
        mechanics: ['daily_challenge', 'double_bridge'],
      ),
      gridWidth: level.gridWidth,
      gridHeight: level.gridHeight,
      islands: level.islands,
      tutorial:
          const LevelTutorial(hasInteractiveTutorial: false, hintTriggers: []),
      verification: level.verification,
    );
    _openLevel(context, dailyLevel);
  }

  Widget _buildDifficultyCard({
    required NodalisPalette palette,
    required String title,
    required String gridSize,
    required String description,
    required DifficultyTier difficulty,
    required int width,
    required int height,
    required int islandCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(NodalisDimensions.radiusMedium),
        border: Border.all(
          color: palette.surfaceSubtle,
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: palette.surfaceSubtle,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        gridSize,
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 10.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  description,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12.0),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: palette.islandSelectedStroke,
              foregroundColor: palette.background,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(NodalisDimensions.radiusSmall),
              ),
            ),
            onPressed: () {
              final level = const PuzzleGenerator().generate(
                width: width,
                height: height,
                islandCount: islandCount,
                difficulty: difficulty,
              );
              if (level != null) {
                _openLevel(context, level);
              }
            },
            child: const Text('Play'),
          ),
        ],
      ),
    );
  }

  IconData _themeIcon(NodalisThemeMode mode) {
    switch (mode) {
      case NodalisThemeMode.light:
        return Icons.light_mode_outlined;
      case NodalisThemeMode.dark:
        return Icons.dark_mode_outlined;
      case NodalisThemeMode.oled:
        return Icons.battery_saver_rounded;
    }
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
