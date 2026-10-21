import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nodalis_domain/nodalis_domain.dart';
import 'package:nodalis_solver/nodalis_solver.dart';
import 'package:nodalis_ui/nodalis_ui.dart';
import '../../content/level_repository.dart';
import '../../session/game_session.dart';
import '../../session/progress_repository.dart';
import '../dialogs/deductive_hint_dialog.dart';
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
  final _deductiveEngine = const DeductiveEngine();

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
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
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

  void _showHintDialog() {
    HapticFeedback.selectionClick();
    final hint = _deductiveEngine.evaluateHint(
      board: widget.session.currentBoard,
      initialBoard: widget.session.level.toInitialBoard(),
    );

    if (hint == null) return;

    if (hint.primaryIslandId > 0) {
      setState(() {
        _viewModel = _viewModel.copyWith(
          selectedIslandId: () => hint.primaryIslandId,
        );
      });
    }

    DeductiveHintDialog.show(
      context: context,
      hint: hint,
      onUndo: widget.session.canUndo
          ? () {
              HapticFeedback.selectionClick();
              widget.session.undo();
            }
          : null,
      onApplyStep: (fromId, toId) {
        _handleConnect(fromId, toId);
      },
    );
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

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        // Undo
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          if (widget.session.canUndo) {
            HapticFeedback.selectionClick();
            widget.session.undo();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () {
          if (widget.session.canUndo) {
            HapticFeedback.selectionClick();
            widget.session.undo();
          }
        },
        // Redo
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): () {
          if (widget.session.canRedo) {
            HapticFeedback.selectionClick();
            widget.session.redo();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyY, meta: true): () {
          if (widget.session.canRedo) {
            HapticFeedback.selectionClick();
            widget.session.redo();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): () {
          if (widget.session.canRedo) {
            HapticFeedback.selectionClick();
            widget.session.redo();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true): () {
          if (widget.session.canRedo) {
            HapticFeedback.selectionClick();
            widget.session.redo();
          }
        },
        // Reset
        const SingleActivator(LogicalKeyboardKey.keyR): () {
          HapticFeedback.selectionClick();
          widget.session.reset();
          _hasShownSolvedDialog = false;
        },
        // Hint
        const SingleActivator(LogicalKeyboardKey.keyH): _showHintDialog,
        // Deselect
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_viewModel.selectedIslandId != null) {
            setState(() {
              _viewModel = _viewModel.copyWith(selectedIslandId: () => null);
            });
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
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
                          const SizedBox(width: 4.0),
                          IconButton(
                            icon: Icon(
                              Icons.lightbulb_outline_rounded,
                              color: palette.islandSelectedStroke,
                            ),
                            tooltip: 'Hint (H)',
                            onPressed: _showHintDialog,
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
                    ],
                  ),
                ),

                // Tutorial guidance banner
                TutorialBanner(
                  level: widget.session.level,
                  board: widget.session.currentBoard,
                ),

                // Puzzle Board Viewport
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: BoardWidget(
                      viewModel: _viewModel.copyWith(
                        board: widget.session.currentBoard,
                      ),
                      onViewModelChanged: (newVm) {
                        setState(() {
                          _viewModel = newVm.copyWith(
                            board: widget.session.currentBoard,
                          );
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
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.textPrimary,
                            side: BorderSide(color: palette.surfaceSubtle),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 14.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  NodalisDimensions.radiusMedium),
                            ),
                          ),
                          onPressed: widget.session.canUndo
                              ? () {
                                  HapticFeedback.selectionClick();
                                  widget.session.undo();
                                }
                              : null,
                          icon: const Icon(Icons.undo_rounded, size: 18.0),
                          label: const Text(
                            'Undo',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.textPrimary,
                            side: BorderSide(color: palette.surfaceSubtle),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 14.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  NodalisDimensions.radiusMedium),
                            ),
                          ),
                          onPressed: widget.session.canRedo
                              ? () {
                                  HapticFeedback.selectionClick();
                                  widget.session.redo();
                                }
                              : null,
                          icon: const Icon(Icons.redo_rounded, size: 18.0),
                          label: const Text(
                            'Redo',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.textPrimary,
                            side: BorderSide(color: palette.surfaceSubtle),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 14.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  NodalisDimensions.radiusMedium),
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            widget.session.reset();
                            _hasShownSolvedDialog = false;
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 18.0),
                          label: const Text(
                            'Reset',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
