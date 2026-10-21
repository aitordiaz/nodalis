import 'package:flutter/foundation.dart';
import 'package:nodalis_domain/nodalis_domain.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';
import 'undo_stack.dart';

/// Application session controller coordinating active level, move history, and win state.
class GameSession extends ChangeNotifier {
  final LevelDefinition level;
  late Board _currentBoard;
  final UndoStack<Board> _undoStack = UndoStack();
  int _moveCount = 0;

  GameSession({
    required this.level,
    List<Bridge>? initialBridges,
    int initialMoveCount = 0,
  }) {
    if (initialBridges != null &&
        initialBridges.where((b) => b.isActive).isNotEmpty) {
      final initial = level.toInitialBoard();
      final map = {
        for (final b in initialBridges)
          if (b.isActive) b.key: b,
      };
      _currentBoard = Board(
        width: initial.width,
        height: initial.height,
        islands: initial.islands,
        bridges: map,
      );
      _moveCount = initialMoveCount;
    } else {
      _currentBoard = level.toInitialBoard();
      _moveCount = 0;
    }
  }

  Board get currentBoard => _currentBoard;
  int get moveCount => _moveCount;
  bool get canUndo => _undoStack.canUndo;
  bool get canRedo => _undoStack.canRedo;
  bool get isSolved => _currentBoard.isSolved;

  /// Dispatches an action to the domain engine, tracking undo history on success.
  Result<void, DomainFailure> dispatchAction(BoardAction action) {
    final priorBoard = _currentBoard;
    final result = _currentBoard.applyAction(action);

    return switch (result) {
      Ok(:final value) => _onActionApplied(priorBoard, value),
      Err(:final error) => Result.err(error),
    };
  }

  Result<void, DomainFailure> _onActionApplied(
      Board priorBoard, Board newBoard) {
    if (priorBoard != newBoard) {
      _undoStack.push(priorBoard);
      _currentBoard = newBoard;
      _moveCount++;
      notifyListeners();
    }
    return const Result.ok(null);
  }

  /// Restores the immediately preceding board state.
  bool undo() {
    final previous = _undoStack.undo(_currentBoard);
    if (previous == null) return false;

    _currentBoard = previous;
    _moveCount++;
    notifyListeners();
    return true;
  }

  /// Redoes the immediately following board state.
  bool redo() {
    final next = _undoStack.redo(_currentBoard);
    if (next == null) return false;

    _currentBoard = next;
    _moveCount++;
    notifyListeners();
    return true;
  }

  /// Resets the board back to its initial state.
  void reset() {
    _undoStack.push(_currentBoard);
    _currentBoard = level.toInitialBoard();
    _moveCount++;
    notifyListeners();
  }
}
