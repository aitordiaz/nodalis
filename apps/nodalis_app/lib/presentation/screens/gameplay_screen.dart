import 'package:flutter/material.dart';
import 'package:nodalis_domain/nodalis_domain.dart';
import 'package:nodalis_ui/nodalis_ui.dart';
import '../../session/game_session.dart';

/// Primary gameplay screen displaying the board, chapter metadata, and controls.
class GameplayScreen extends StatefulWidget {
  final GameSession session;
  final VoidCallback onToggleTheme;
  final bool isDark;

  const GameplayScreen({
    super.key,
    required this.session,
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSolvedDialog();
      });
    }
  }

  void _handleConnect(int fromId, int toId) {
    final result = widget.session.dispatchAction(
      CycleBridgeAction(fromId: fromId, toId: toId),
    );

    if (result.isErr) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorOrNull?.message ?? 'Invalid move'),
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSolvedDialog() {
    final theme = NodalisTheme.of(context);
    final palette = theme.palette;

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

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chapter ${widget.session.level.chapterId}',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        'Level ${widget.session.level.indexInChapter}',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
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
                      const SizedBox(width: 14.0),
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
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.textPrimary,
                      side: BorderSide(color: palette.surfaceSubtle),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18.0, vertical: 12.0),
                    ),
                    onPressed: widget.session.canUndo
                        ? () {
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
                          horizontal: 18.0, vertical: 12.0),
                    ),
                    onPressed: () {
                      widget.session.reset();
                      _hasShownSolvedDialog = false;
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 20.0),
                    label: const Text('Reset'),
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
