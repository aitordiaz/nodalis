/// Generic bounded undo/redo history stack for immutable states.
final class UndoStack<T> {
  final List<T> _history = [];
  final int maxCapacity;

  UndoStack({this.maxCapacity = 100});

  bool get canUndo => _history.isNotEmpty;
  int get count => _history.length;

  /// Pushes a prior state snapshot before applying a mutation.
  void push(T state) {
    if (_history.length >= maxCapacity) {
      _history.removeAt(0);
    }
    _history.add(state);
  }

  /// Pops the most recent state snapshot.
  T? pop() {
    if (_history.isEmpty) return null;
    return _history.removeLast();
  }

  /// Clears the history stack.
  void clear() {
    _history.clear();
  }
}
