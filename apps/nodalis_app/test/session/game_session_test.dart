import 'package:flutter_test/flutter_test.dart';
import 'package:nodalis_app/session/game_session.dart';
import 'package:nodalis_domain/nodalis_domain.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';

void main() {
  group('GameSession', () {
    late LevelDefinition simpleLevel;

    setUp(() {
      simpleLevel = const LevelDefinition(
        id: 'test_1',
        version: 1,
        chapterId: 1,
        indexInChapter: 1,
        gridWidth: 4,
        gridHeight: 4,
        metadata: LevelMetadata(
          titleKey: 'test_1',
          author: 'Test',
          difficultyTier: DifficultyTier.introductory,
          estimatedSolveTimeSeconds: 30,
          parMoves: 1,
          mechanics: ['single_bridge'],
        ),
        islands: [
          Island(id: 1, position: (x: 1, y: 1), requiredBridges: 1),
          Island(id: 2, position: (x: 3, y: 1), requiredBridges: 1),
        ],
        tutorial: LevelTutorial(
          hasInteractiveTutorial: false,
          hintTriggers: [],
        ),
      );
    });

    test('initializes with level board and zero moves', () {
      final session = GameSession(level: simpleLevel);
      expect(session.level, simpleLevel);
      expect(session.moveCount, 0);
      expect(session.canUndo, isFalse);
      expect(session.canRedo, isFalse);
      expect(session.isSolved, isFalse);
    });

    test('dispatchAction updates state, enables undo, and solves', () {
      final session = GameSession(level: simpleLevel);
      bool notified = false;
      session.addListener(() => notified = true);

      final result = session.dispatchAction(
        const CycleBridgeAction(fromId: 1, toId: 2),
      );

      expect(result.isOk, isTrue);
      expect(notified, isTrue);
      expect(session.moveCount, 1);
      expect(session.canUndo, isTrue);
      expect(session.canRedo, isFalse);
      expect(session.isSolved, isTrue);
      expect(session.currentBoard.bridges.length, 1);
    });

    test('undo and redo cycle properly restores board state', () {
      final session = GameSession(level: simpleLevel);
      session.dispatchAction(const CycleBridgeAction(fromId: 1, toId: 2));
      expect(session.isSolved, isTrue);

      final undoSuccess = session.undo();
      expect(undoSuccess, isTrue);
      expect(session.currentBoard.bridges, isEmpty);
      expect(session.isSolved, isFalse);
      expect(session.canUndo, isFalse);
      expect(session.canRedo, isTrue);

      final redoSuccess = session.redo();
      expect(redoSuccess, isTrue);
      expect(session.currentBoard.bridges.length, 1);
      expect(session.isSolved, isTrue);
      expect(session.canUndo, isTrue);
      expect(session.canRedo, isFalse);
    });

    test('reset clears bridges and allows undo', () {
      final session = GameSession(level: simpleLevel);
      session.dispatchAction(const CycleBridgeAction(fromId: 1, toId: 2));

      session.reset();
      expect(session.currentBoard.bridges, isEmpty);
      expect(session.isSolved, isFalse);
      expect(session.canUndo, isTrue);

      // Undoing reset brings back the solved board
      session.undo();
      expect(session.currentBoard.bridges.length, 1);
      expect(session.isSolved, isTrue);
    });
  });
}
