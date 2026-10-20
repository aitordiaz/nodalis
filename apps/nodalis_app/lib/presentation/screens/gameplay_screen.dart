import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nodalis_domain/nodalis_domain.dart';
import 'package:nodalis_ui/nodalis_ui.dart';
import '../../content/level_repository.dart';
import '../../session/game_session.dart';
import '../../session/progress_repository.dart';
import '../dialogs/how_to_play_dialog.dart';
import '../widgets/tutorial_banner.dart';

/// Primary gameplay screen displaying the board, chapter metadata, and controls.
class GameplayScreen extends StatefulWidget {
  final GameSession session;
  final ProgressRepository? progressRepository;
  final LevelRepository? levelRepository;
  final VoidCallback onToggleTheme;
  final bool isDark;

  const GameplayScreen({
    super.key,
    required this.session,
    this.progressRepository,
    this.levelRepository,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late BoardViewModel _viewModel;
  bool _hasShownSolvedDialog = false;

  @override
  void initState() {
    super.initState();
    _viewModel = BoardViewModel(board: widget.session.currentBoard);
    widget.session.addListener(_onSessionUpdated);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionUpdated);
    super.dispose();
  }

  void _onSessionUpdated() {
    setState(() {
      _viewModel = _viewModel.copyWith(
        board: widget.session.currentBoard,
        selectedIslandId: () => null,
      );
    });

    if (widget.session.isSolved && !_hasShownSolvedDialog) {
      _hasShownSolvedDialog = true;
      HapticFeedback.mediumImpact();
      widget.progressRepository?.recordCompletion(
        widget.session.level.id,
        widget.session.moveCount,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSolvedDialog();
      });
    }
  }

  void _handleConnect(int fromId, int toId) {
    final result = widget.session.dispatchAction(
      CycleBridgeAction(fromId: fromId, toId: toId),
    );

    if (result.isOk) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_formatFriendlyError(result.errorOrNull)),
          duration: const Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatFriendlyError(DomainFailure? failure) {
    return switch (failure) {
      CapacityExceededFailure(:final capacity) =>
        'Island capacity reached (max $capacity bridges).',
      CrossingBridgeFailure() =>
        'Bridges cannot cross each other.',
      NonOrthogonalConnectionFailure() =>
        'Bridges must be strictly horizontal or vertical.',
      InterveningIslandFailure() =>
        'Cannot bridge across an intermediate island.',
      SelfConnectionFailure() =>
        'An island cannot connect to itself.',
      _ => 'Invalid bridge placement.',
    };
  }

  void _showSolvedDialog() {
    final theme = NodalisTheme.of(context);
    final palette = theme.palette;
    final nextLevel =
        widget.levelRepository?.getNextLevel(widget.session.level);

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: palette.surface,
          title: Text(
            'Level Solved',
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Completed in ${widget.session.moveCount} moves.',
            style: TextStyle(color: palette.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.session.reset();
                _hasShownSolvedDialog = false;
              },
              child: Text(
                'Replay',
                style: TextStyle(color: palette.islandSelectedStroke),
              ),
            ),
            if (nextLevel != null)
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.islandSelectedStroke,
                  foregroundColor: palette.background,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (context) {
                        return GameplayScreen(
                          session: GameSession(level: nextLevel),
                          progressRepository: widget.progressRepository,
                          levelRepository: widget.levelRepository,
                          onToggleTheme: widget.onToggleTheme,
                          isDark: widget.isDark,
                        );
                      },
                    ),
                  );
                },
                child: const Text('Next Level'),
              )
            else
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.islandSelectedStroke,
                  foregroundColor: palette.background,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Done'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = NodalisTheme.of(context);
    final palette = theme.palette;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (canPop)
                        IconButton(
                          icon: Icon(Icons.arrow_back_rounded,
                              color: palette.textPrimary),
                          tooltip: 'Back to Levels',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chapter ${widget.session.level.chapterId}',
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            'Level ${widget.session.level.indexInChapter}',
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 19.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Moves: ${widget.session.moveCount}',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6.0),
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
                ],
              ),
            ),

            // Tutorial guidance banner
            TutorialBanner(
              level: widget.session.level,
              board: widget.session.currentBoard,
              onOpenHelp: () => HowToPlayDialog.show(context),
            ),

            // Puzzle Board Viewport
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: BoardWidget(
                  viewModel: _viewModel,
                  onViewModelChanged: (newVm) {
                    setState(() {
                      _viewModel = newVm;
                    });
                  },
                  onConnect: _handleConnect,
                  onIslandCleared: (islandId) {
                    widget.session.dispatchAction(
                      ClearIslandBridgesAction(islandId: islandId),
                    );
                  },
                ),
              ),
            ),

            // Bottom Action Bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.textPrimary,
                      side: BorderSide(color: palette.surfaceSubtle),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14.0, vertical: 12.0),
                    ),
                    onPressed: widget.session.canUndo
                        ? () {
                            HapticFeedback.selectionClick();
                            widget.session.undo();
                          }
                        : null,
                    icon: const Icon(Icons.undo_rounded, size: 20.0),
                    label: const Text('Undo'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.textPrimary,
                      side: BorderSide(color: palette.surfaceSubtle),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14.0, vertical: 12.0),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      widget.session.reset();
                      _hasShownSolvedDialog = false;
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 20.0),
                    label: const Text('Reset'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.textPrimary,
                      side: BorderSide(color: palette.surfaceSubtle),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14.0, vertical: 12.0),
                    ),
                    onPressed: () => HowToPlayDialog.show(context),
                    icon: const Icon(Icons.menu_book_rounded, size: 20.0),
                    label: const Text('Rules'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
