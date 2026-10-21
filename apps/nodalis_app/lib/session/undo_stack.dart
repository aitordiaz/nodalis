/// Generic bounded undo/redo history stack for immutable states.
final class UndoStack<T> {
  final List<T> _undoHistory = [];
  final List<T> _redoHistory = [];
  final int maxCapacity;

  UndoStack({this.maxCapacity = 100});

  bool get canUndo => _undoHistory.isNotEmpty;
  bool get canRedo => _redoHistory.isNotEmpty;
  int get undoCount => _undoHistory.length;
  int get redoCount => _redoHistory.length;

  /// Pushes a prior state snapshot before applying a mutation, clearing redo history.
  void push(T state) {
    if (_undoHistory.length >= maxCapacity) {
      _undoHistory.removeAt(0);
    }
    _undoHistory.add(state);
    _redoHistory.clear();
  }

  /// Undoes to the most recent state snapshot, moving [currentState] onto redo history.
  T? undo(T currentState) {
    if (_undoHistory.isEmpty) return null;
    _redoHistory.add(currentState);
    return _undoHistory.removeLast();
  }

  /// Redoes to the next state snapshot, moving [currentState] back onto undo history.
  T? redo(T currentState) {
    if (_redoHistory.isEmpty) return null;
    _undoHistory.add(currentState);
    return _redoHistory.removeLast();
  }

  /// Clears both history stacks.
  void clear() {
    _undoHistory.clear();
    _redoHistory.clear();
  }
}
