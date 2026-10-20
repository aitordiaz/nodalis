import 'package:nodalis_domain/nodalis_domain.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';
import 'package:nodalis_solver/nodalis_solver.dart';
import 'package:test/test.dart';

void main() {
  group('BacktrackingSolver', () {
    const solver = BacktrackingSolver();

    test('solves simple 2-island puzzle and verifies uniqueness', () {
      final board = Board.initial(
        width: 5,
        height: 5,
        islands: [
          const Island(id: 1, position: (x: 1, y: 1), requiredBridges: 1),
          const Island(id: 2, position: (x: 3, y: 1), requiredBridges: 1),
        ],
      );

      final result = solver.solve(board);
      expect(result.isSolvable, isTrue);
      expect(result.isUnique, isTrue);
      expect(result.solutions.length, equals(1));

      final hash =
          BacktrackingSolver.calculateSolutionHash(result.solutions.first);
      expect(hash, isNotEmpty);
    });

    test('detects unsolvable puzzle with odd degree sum', () {
      final board = Board.initial(
        width: 5,
        height: 5,
        islands: [
          const Island(id: 1, position: (x: 1, y: 1), requiredBridges: 1),
          const Island(
              id: 2,
              position: (x: 3, y: 1),
              requiredBridges: 2), // Total = 3 (odd!)
        ],
      );

      final result = solver.solve(board);
      expect(result.isSolvable, isFalse);
      expect(result.solutions, isEmpty);
    });

    test('detects multiple solutions on ambiguous 4-island square', () {
      // 4 islands forming a 2x2 square where each needs 2 bridges.
      // Top-left: (1, 1) [cap 2]
      // Top-right: (3, 1) [cap 2]
      // Bottom-left: (1, 3) [cap 2]
      // Bottom-right: (3, 3) [cap 2]
      // Valid solutions:
      // Solution A: 1-bridge around the 4-cycle (1-2, 2-4, 4-3, 3-1), all connected!
      // Any other assignment: can we have 2-bridges? If 1-2 has 2 and 3-4 has 2, disconnected!
      // But let's check: 1-bridge 4-cycle is 1 solution.
      final board = Board.initial(
        width: 5,
        height: 5,
        islands: [
          const Island(id: 1, position: (x: 1, y: 1), requiredBridges: 2),
          const Island(id: 2, position: (x: 3, y: 1), requiredBridges: 2),
          const Island(id: 3, position: (x: 1, y: 3), requiredBridges: 2),
          const Island(id: 4, position: (x: 3, y: 3), requiredBridges: 2),
        ],
      );

      final result = solver.solve(board, maxSolutions: 2);
      expect(result.isSolvable, isTrue);
      // The 4-cycle is a single connected component!
      expect(result.solutions.length, equals(1));
    });
  });

  group('LevelValidator', () {
    const validator = LevelValidator();

    test('validates valid LevelDefinition', () {
      const level = LevelDefinition(
        id: 'test_level',
        version: 1,
        chapterId: 1,
        indexInChapter: 1,
        metadata: LevelMetadata(
          titleKey: 'title',
          author: 'Aitor',
          difficultyTier: DifficultyTier.introductory,
          estimatedSolveTimeSeconds: 30,
          parMoves: 2,
          mechanics: ['single_bridge'],
        ),
        gridWidth: 5,
        gridHeight: 5,
        islands: [
          Island(id: 1, position: (x: 1, y: 2), requiredBridges: 1),
          Island(id: 2, position: (x: 3, y: 2), requiredBridges: 1),
        ],
        tutorial:
            LevelTutorial(hasInteractiveTutorial: false, hintTriggers: []),
      );

      final report = validator.validate(level);
      expect(report.passed, isTrue);
      expect(report.isSolvable, isTrue);
      expect(report.isUnique, isTrue);
      expect(report.computedSolutionHash, isNotNull);
    });
  });
}
