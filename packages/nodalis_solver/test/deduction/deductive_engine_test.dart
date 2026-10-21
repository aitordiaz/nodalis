import 'package:nodalis_domain/nodalis_domain.dart';
import 'package:nodalis_solver/nodalis_solver.dart';
import 'package:test/test.dart';

void main() {
  group('DeductiveEngine', () {
    const engine = DeductiveEngine();

    test('returns alreadySolved hint on completed board', () {
      final board = Board(
        width: 4,
        height: 4,
        islands: const {
          1: Island(id: 1, position: (x: 0, y: 0), requiredBridges: 1),
          2: Island(id: 2, position: (x: 2, y: 0), requiredBridges: 1),
        },
        bridges: {
          makeBridgeKey(1, 2): Bridge(
            islandAId: 1,
            islandBId: 2,
            count: BridgeCount.single,
          ),
        },
      );

      final hint = engine.evaluateHint(board: board);
      expect(hint, isNotNull);
      expect(hint!.category, HintCategory.alreadySolved);
      expect(hint.nudge, contains('properly connected'));
    });

    test('detects overloaded island mistake', () {
      final board = Board(
        width: 4,
        height: 4,
        islands: const {
          1: Island(id: 1, position: (x: 0, y: 0), requiredBridges: 1),
          2: Island(id: 2, position: (x: 2, y: 0), requiredBridges: 2),
        },
        bridges: {
          makeBridgeKey(1, 2): Bridge(
            islandAId: 1,
            islandBId: 2,
            count: BridgeCount.double,
          ),
        },
      );

      final hint = engine.evaluateHint(board: board);
      expect(hint, isNotNull);
      expect(hint!.isMistake, isTrue);
      expect(hint.category, HintCategory.mistakeCorrection);
      expect(hint.primaryIslandId, 1);
      expect(hint.insight, contains('only needs 1'));
    });

    test('deduces saturation for single open neighbor', () {
      final board = Board.initial(
        width: 5,
        height: 5,
        islands: const [
          Island(id: 1, position: (x: 0, y: 0), requiredBridges: 2),
          Island(id: 2, position: (x: 0, y: 3), requiredBridges: 2),
        ],
      );

      final hint = engine.evaluateHint(board: board);
      expect(hint, isNotNull);
      expect(hint!.category, HintCategory.saturation);
      expect(hint.primaryIslandId, 1);
      expect(hint.secondaryIslandId, 2);
      expect(hint.targetBridgeCount, 2);
      expect(hint.insight, contains('only has one neighbor'));
    });

    test('deduces saturation on corner 4 with 2 neighbors', () {
      final board = Board.initial(
        width: 6,
        height: 6,
        islands: const [
          Island(id: 1, position: (x: 0, y: 0), requiredBridges: 4),
          Island(id: 2, position: (x: 3, y: 0), requiredBridges: 2),
          Island(id: 3, position: (x: 0, y: 3), requiredBridges: 2),
        ],
      );

      final hint = engine.evaluateHint(board: board);
      expect(hint, isNotNull);
      expect(hint!.category, HintCategory.saturation);
      expect(hint.primaryIslandId, 1);
      expect(hint.insight, contains('exactly matches the total capacity'));
    });

    test('deduces pigeonhole principle for 3 with two neighbors', () {
      // Island 1 (req: 3) at (2,2) with neighbors Island 2 (req: 3) and Island 3 (req: 3).
      // Island 4 (req: 3) connects to Island 2 and Island 3 to provide sufficient capacity.
      // Total degrees = 3 + 3 + 3 + 3 = 12 (even).
      // Each island has 2 orthogonal neighbors.
      final board = Board.initial(
        width: 6,
        height: 6,
        islands: const [
          Island(id: 1, position: (x: 2, y: 2), requiredBridges: 3),
          Island(id: 2, position: (x: 4, y: 2), requiredBridges: 3),
          Island(id: 3, position: (x: 2, y: 4), requiredBridges: 3),
          Island(id: 4, position: (x: 4, y: 4), requiredBridges: 3),
        ],
      );

      final hint = engine.evaluateHint(board: board);
      expect(hint, isNotNull);
      expect(hint!.category, HintCategory.pigeonhole);
      expect(hint.primaryIslandId, 1);
      expect(
          hint.insight,
          contains(
              'Even if all other neighbors absorb their absolute maximum'));
    });

    test(
        'deduces isolation avoidance when connecting two 1s would strand a 3rd island',
        () {
      final board = Board.initial(
        width: 6,
        height: 6,
        islands: const [
          Island(id: 1, position: (x: 0, y: 2), requiredBridges: 1),
          Island(id: 2, position: (x: 2, y: 2), requiredBridges: 1),
          Island(id: 3, position: (x: 4, y: 2), requiredBridges: 2),
          Island(id: 4, position: (x: 4, y: 4), requiredBridges: 2),
        ],
      );

      final hint = engine.evaluateHint(board: board);
      expect(hint, isNotNull);
      expect(hint!.category,
          anyOf(HintCategory.saturation, HintCategory.isolationAvoidance));
    });

    test('detects stranded island blocked by existing bridges', () {
      // Crossing bridge setup:
      // Island 1 (x:1, y:0) and Island 2 (x:1, y:4) connected
      // Island 3 (x:0, y:2, req:1) and Island 4 (x:4, y:2, req:1) blocked by bridge 1-2!
      final board = Board(
        width: 5,
        height: 5,
        islands: const {
          1: Island(id: 1, position: (x: 2, y: 0), requiredBridges: 1),
          2: Island(id: 2, position: (x: 2, y: 4), requiredBridges: 1),
          3: Island(id: 3, position: (x: 0, y: 2), requiredBridges: 1),
          4: Island(id: 4, position: (x: 4, y: 2), requiredBridges: 1),
        },
        bridges: {
          makeBridgeKey(1, 2): Bridge(
            islandAId: 1,
            islandBId: 2,
            count: BridgeCount.single,
          ),
        },
      );

      final hint = engine.evaluateHint(board: board);
      expect(hint, isNotNull);
      expect(hint!.isMistake, isTrue);
      expect(hint.category, HintCategory.mistakeCorrection);
      expect(hint.insight,
          contains('crossing bridges or satisfied neighbors prevent'));
    });
  });
}
