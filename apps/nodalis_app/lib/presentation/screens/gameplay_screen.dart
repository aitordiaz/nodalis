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
import '../dialogs/settings_dialog.dart';
import '../widgets/tutorial_banner.dart';

/// Primary gameplay screen displaying the board, chapter metadata, and controls.
class GameplayScreen extends StatefulWidget {
  final GameSession session;
  final ProgressRepository? progressRepository;
  final LevelRepository? levelRepository;
  final VoidCallback onToggleTheme;
  final ValueChanged<NodalisThemeMode>? onSetTheme;
  final bool? isDark;
  final NodalisThemeMode? themeMode;

  const GameplayScreen({
    super.key,
    required this.session,
    this.progressRepository,
    this.levelRepository,
    required this.onToggleTheme,
    this.onSetTheme,
    this.isDark,
    this.themeMode,
  });

  NodalisThemeMode get activeThemeMode =>
      themeMode ??
      (isDark == true ? NodalisThemeMode.dark : NodalisThemeMode.light);

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.progressRepository?.setLastPlayed(widget.session.level.id);
    });
    _viewModel = BoardViewModel(board: widget.session.currentBoard);
    widget.session.addListener(_onSessionUpdated);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionUpdated);
    super.dispose();
  }

  void _triggerHaptic({bool medium = false}) {
    if (widget.progressRepository != null) {
      widget.progressRepository!.triggerHaptic(medium: medium);
    } else {
      if (medium) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
  }

  void _onSessionUpdated() {
    setState(() {
      _viewModel = _viewModel.copyWith(
        board: widget.session.currentBoard,
      );
    });

    if (widget.session.isSolved && !_hasShownSolvedDialog) {
      _hasShownSolvedDialog = true;
      _triggerHaptic(medium: true);
      widget.progressRepository?.clearActiveBoard(widget.session.level.id);
      widget.progressRepository?.recordCompletion(
        widget.session.level.id,
        widget.session.moveCount,
      );
      final delay = widget.progressRepository?.reduceMotion == true
          ? Duration.zero
          : const Duration(milliseconds: 500);
      Future.delayed(delay, () {
        if (!mounted) return;
        _showSolvedDialog();
      });
    } else if (!widget.session.isSolved) {
      widget.progressRepository?.saveActiveBoard(
        widget.session.level.id,
        widget.session.currentBoard.bridges.values.toList(),
        widget.session.moveCount,
      );
    }
  }

  void _handleConnect(int fromId, int toId) {
    final result = widget.session.dispatchAction(
      CycleBridgeAction(fromId: fromId, toId: toId),
    );

    if (result.isOk) {
      if (widget.progressRepository?.hapticsEnabled ?? true) {
        HapticFeedback.lightImpact();
      }
    } else {
      _triggerHaptic();
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

  void _navigateIsland(int dx, int dy) {
    final board = widget.session.currentBoard;
    if (board.islands.isEmpty) return;

    final currentId = _viewModel.selectedIslandId;
    if (currentId == null || !board.islands.containsKey(currentId)) {
      final sortedIslands = board.islands.values.toList()
        ..sort((a, b) {
          final cmpY = a.position.y.compareTo(b.position.y);
          return cmpY != 0 ? cmpY : a.position.x.compareTo(b.position.x);
        });
      setState(() {
        _viewModel = _viewModel.copyWith(
          selectedIslandId: () => sortedIslands.first.id,
        );
      });
      _triggerHaptic();
      return;
    }

    final current = board.islands[currentId]!;
    Island? bestOrthogonal;
    var minOrthogonalDist = 999999;

    Island? bestDirectional;
    var minDirectionalScore = 999999.0;

    for (final other in board.islands.values) {
      if (other.id == current.id) continue;
      final deltaX = other.position.x - current.position.x;
      final deltaY = other.position.y - current.position.y;

      // Strict orthogonal alignment
      if (dx != 0 && deltaY == 0 && (deltaX > 0) == (dx > 0)) {
        final dist = deltaX.abs();
        if (dist < minOrthogonalDist) {
          minOrthogonalDist = dist;
          bestOrthogonal = other;
        }
      } else if (dy != 0 && deltaX == 0 && (deltaY > 0) == (dy > 0)) {
        final dist = deltaY.abs();
        if (dist < minOrthogonalDist) {
          minOrthogonalDist = dist;
          bestOrthogonal = other;
        }
      }

      // Directional half-plane
      final isHeadingDirection = (dx > 0 && deltaX > 0) ||
          (dx < 0 && deltaX < 0) ||
          (dy > 0 && deltaY > 0) ||
          (dy < 0 && deltaY < 0);

      if (isHeadingDirection) {
        final primaryDist = (dx != 0 ? deltaX.abs() : deltaY.abs()).toDouble();
        final secondaryDist =
            (dx != 0 ? deltaY.abs() : deltaX.abs()).toDouble();
        final score = primaryDist + secondaryDist * 2.5;
        if (score < minDirectionalScore) {
          minDirectionalScore = score;
          bestDirectional = other;
        }
      }
    }

    final target = bestOrthogonal ?? bestDirectional;
    if (target != null) {
      setState(() {
        _viewModel = _viewModel.copyWith(
          selectedIslandId: () => target.id,
        );
      });
      _triggerHaptic();
    }
  }

  void _connectDirection(int dx, int dy) {
    final board = widget.session.currentBoard;
    var currentId = _viewModel.selectedIslandId;
    if (currentId == null || !board.islands.containsKey(currentId)) {
      _navigateIsland(dx, dy);
      currentId = _viewModel.selectedIslandId;
      if (currentId == null) return;
    }

    final current = board.islands[currentId]!;
    final neighbors = board.getAvailableOrthogonalNeighbors(currentId);
    Island? targetNeighbor;

    for (final neighbor in neighbors) {
      final deltaX = neighbor.position.x - current.position.x;
      final deltaY = neighbor.position.y - current.position.y;

      if (dx != 0 && deltaY == 0 && (deltaX > 0) == (dx > 0)) {
        targetNeighbor = neighbor;
        break;
      }
      if (dy != 0 && deltaX == 0 && (deltaY > 0) == (dy > 0)) {
        targetNeighbor = neighbor;
        break;
      }
    }

    if (targetNeighbor != null) {
      _handleConnect(current.id, targetNeighbor.id);
    } else {
      _triggerHaptic();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No orthogonal island reachable in that direction.'),
          duration: Duration(milliseconds: 1000),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearSelectedIsland() {
    final currentId = _viewModel.selectedIslandId;
    if (currentId == null) return;
    _triggerHaptic();
    widget.session.dispatchAction(
      ClearIslandBridgesAction(islandId: currentId),
    );
  }

  void _openSettingsDialog() {
    if (widget.progressRepository == null) return;
    _triggerHaptic();
    SettingsDialog.show(
      context,
      progressRepository: widget.progressRepository!,
      onThemeChanged: (mode) {
        if (widget.onSetTheme != null) {
          widget.onSetTheme!(mode);
        } else {
          widget.onToggleTheme();
        }
      },
      currentThemeMode: widget.activeThemeMode,
    );
  }

  String _formatFriendlyError(DomainFailure? failure) {
    return switch (failure) {
      CapacityExceededFailure(:final capacity) =>
        'Island capacity reached (max $capacity bridges).',
      CrossingBridgeFailure() => 'Bridges cannot cross each other.',
      NonOrthogonalConnectionFailure() =>
        'Bridges must be strictly horizontal or vertical.',
      InterveningIslandFailure() =>
        'Cannot bridge across an intermediate island.',
      SelfConnectionFailure() => 'An island cannot connect to itself.',
      _ => 'Invalid bridge placement.',
    };
  }

  void _showHintDialog() {
    _triggerHaptic();
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
              _triggerHaptic();
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
                widget.progressRepository
                    ?.clearActiveBoard(widget.session.level.id);
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
                  widget.progressRepository?.setLastPlayed(nextLevel.id);
                  final active =
                      widget.progressRepository?.getActiveBoard(nextLevel.id);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (context) {
                        return GameplayScreen(
                          session: GameSession(
                            level: nextLevel,
                            initialBridges: active?.bridges,
                            initialMoveCount: active?.moveCount ?? 0,
                          ),
                          progressRepository: widget.progressRepository,
                          levelRepository: widget.levelRepository,
                          onToggleTheme: widget.onToggleTheme,
                          onSetTheme: widget.onSetTheme,
                          themeMode: widget.activeThemeMode,
                        );
                      },
                    ),
                  );
                },
                child: const Text('Next Level'),
              )
            else if (widget.session.level.id.startsWith('gen_'))
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.islandSelectedStroke,
                  foregroundColor: palette.background,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  final nextGen = const PuzzleGenerator().generate(
                    width: widget.session.level.gridWidth,
                    height: widget.session.level.gridHeight,
                    islandCount: widget.session.level.islands.length,
                    difficulty: widget.session.level.metadata.difficultyTier,
                  );
                  if (nextGen != null) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (context) {
                          return GameplayScreen(
                            session: GameSession(level: nextGen),
                            progressRepository: widget.progressRepository,
                            levelRepository: widget.levelRepository,
                            onToggleTheme: widget.onToggleTheme,
                            onSetTheme: widget.onSetTheme,
                            themeMode: widget.activeThemeMode,
                          );
                        },
                      ),
                    );
                  }
                },
                child: const Text('Next Puzzle'),
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
            _triggerHaptic();
            widget.session.undo();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () {
          if (widget.session.canUndo) {
            _triggerHaptic();
            widget.session.undo();
          }
        },
        // Redo
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): () {
          if (widget.session.canRedo) {
            _triggerHaptic();
            widget.session.redo();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyY, meta: true): () {
          if (widget.session.canRedo) {
            _triggerHaptic();
            widget.session.redo();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyZ,
            control: true, shift: true): () {
          if (widget.session.canRedo) {
            _triggerHaptic();
            widget.session.redo();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
            () {
          if (widget.session.canRedo) {
            _triggerHaptic();
            widget.session.redo();
          }
        },
        // Reset
        const SingleActivator(LogicalKeyboardKey.keyR): () {
          _triggerHaptic();
          widget.session.reset();
          _hasShownSolvedDialog = false;
        },
        // Hint
        const SingleActivator(LogicalKeyboardKey.keyH): _showHintDialog,
        // Settings
        const SingleActivator(LogicalKeyboardKey.keyO): _openSettingsDialog,
        const SingleActivator(LogicalKeyboardKey.comma, control: true):
            _openSettingsDialog,
        // Deselect
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_viewModel.selectedIslandId != null) {
            setState(() {
              _viewModel = _viewModel.copyWith(selectedIslandId: () => null);
            });
          }
        },
        // Grid Island Navigation (Arrows / WASD)
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _navigateIsland(0, -1),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _navigateIsland(0, 1),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _navigateIsland(-1, 0),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _navigateIsland(1, 0),
        const SingleActivator(LogicalKeyboardKey.keyW): () =>
            _navigateIsland(0, -1),
        const SingleActivator(LogicalKeyboardKey.keyS): () =>
            _navigateIsland(0, 1),
        const SingleActivator(LogicalKeyboardKey.keyA): () =>
            _navigateIsland(-1, 0),
        const SingleActivator(LogicalKeyboardKey.keyD): () =>
            _navigateIsland(1, 0),
        // Directional Bridge Construction (Shift + Arrows / Shift + WASD)
        const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): () =>
            _connectDirection(0, -1),
        const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): () =>
            _connectDirection(0, 1),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): () =>
            _connectDirection(-1, 0),
        const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): () =>
            _connectDirection(1, 0),
        const SingleActivator(LogicalKeyboardKey.keyW, shift: true): () =>
            _connectDirection(0, -1),
        const SingleActivator(LogicalKeyboardKey.keyS, shift: true): () =>
            _connectDirection(0, 1),
        const SingleActivator(LogicalKeyboardKey.keyA, shift: true): () =>
            _connectDirection(-1, 0),
        const SingleActivator(LogicalKeyboardKey.keyD, shift: true): () =>
            _connectDirection(1, 0),
        // Bridge Clearing
        const SingleActivator(LogicalKeyboardKey.delete): _clearSelectedIsland,
        const SingleActivator(LogicalKeyboardKey.backspace):
            _clearSelectedIsland,
        const SingleActivator(LogicalKeyboardKey.keyX): _clearSelectedIsland,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (canPop)
                              IconButton(
                                icon: Icon(Icons.arrow_back_rounded,
                                    color: palette.textPrimary),
                                tooltip: 'Back to Levels',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.session.level.chapterId == 0
                                        ? widget.session.level.metadata.titleKey
                                        : 'Chapter ${widget.session.level.chapterId}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: palette.textSecondary,
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    widget.session.level.chapterId == 0
                                        ? widget.session.level.metadata
                                            .difficultyTier.value
                                            .toUpperCase()
                                        : 'Level ${widget.session.level.indexInChapter}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: palette.textPrimary,
                                      fontSize: 19.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Moves: ${widget.session.moveCount}',
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 2.0),
                          IconButton(
                            icon: Icon(
                              Icons.lightbulb_outline_rounded,
                              color: palette.islandSelectedStroke,
                            ),
                            tooltip: 'Hint (H)',
                            visualDensity: VisualDensity.compact,
                            onPressed: _showHintDialog,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.help_outline_rounded,
                              color: palette.textPrimary,
                            ),
                            tooltip: 'How to Play',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => HowToPlayDialog.show(context),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.settings_outlined,
                              color: palette.textPrimary,
                            ),
                            tooltip: 'Settings (O)',
                            visualDensity: VisualDensity.compact,
                            onPressed: _openSettingsDialog,
                          ),
                          IconButton(
                            icon: Icon(
                              _themeIcon(widget.activeThemeMode),
                              color: palette.textPrimary,
                            ),
                            tooltip:
                                'Theme: ${widget.activeThemeMode.label} (tap to cycle)',
                            visualDensity: VisualDensity.compact,
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
                      accessibilityShapes:
                          widget.progressRepository?.accessibilityShapes ??
                              true,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 14.0),
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
                                  _triggerHaptic();
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
                                  _triggerHaptic();
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
                            _triggerHaptic();
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

  IconData _themeIcon(NodalisThemeMode mode) {
    switch (mode) {
      case NodalisThemeMode.light:
        return Icons.light_mode_outlined;
      case NodalisThemeMode.dark:
        return Icons.dark_mode_outlined;
      case NodalisThemeMode.oled:
        return Icons.battery_saver_rounded;
      case NodalisThemeMode.highContrast:
        return Icons.contrast_rounded;
    }
  }
}
