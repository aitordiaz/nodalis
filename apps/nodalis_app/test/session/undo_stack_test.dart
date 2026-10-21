import 'package:flutter_test/flutter_test.dart';
import 'package:nodalis_app/session/undo_stack.dart';

void main() {
  group('UndoStack', () {
    test('starts empty with canUndo and canRedo false', () {
      final stack = UndoStack<int>();
      expect(stack.canUndo, isFalse);
      expect(stack.canRedo, isFalse);
      expect(stack.undoCount, 0);
      expect(stack.redoCount, 0);
      expect(stack.undo(0), isNull);
      expect(stack.redo(0), isNull);
    });

    test('push enables undo and clears redo', () {
      final stack = UndoStack<int>();
      stack.push(1);
      expect(stack.canUndo, isTrue);
      expect(stack.canRedo, isFalse);
      expect(stack.undoCount, 1);

      // Undo state from current=2 back to 1
      final previous = stack.undo(2);
      expect(previous, 1);
      expect(stack.canUndo, isFalse);
      expect(stack.canRedo, isTrue);
      expect(stack.redoCount, 1);

      // Redo back from current=1 to 2
      final next = stack.redo(1);
      expect(next, 2);
      expect(stack.canUndo, isTrue);
      expect(stack.canRedo, isFalse);

      // A new push invalidates redo history
      stack.push(3);
      expect(stack.canRedo, isFalse);
    });

    test('enforces maxCapacity bound', () {
      final stack = UndoStack<int>(maxCapacity: 3);
      stack.push(1);
      stack.push(2);
      stack.push(3);
      stack.push(4);

      expect(stack.undoCount, 3);
      // oldest (1) should have been dropped
      expect(stack.undo(5), 4);
      expect(stack.undo(4), 3);
      expect(stack.undo(3), 2);
      expect(stack.canUndo, isFalse);
    });

    test('clear resets both undo and redo stacks', () {
      final stack = UndoStack<int>();
      stack.push(1);
      stack.undo(2);
      expect(stack.canRedo, isTrue);

      stack.clear();
      expect(stack.canUndo, isFalse);
      expect(stack.canRedo, isFalse);
      expect(stack.undoCount, 0);
      expect(stack.redoCount, 0);
    });
  });
}
