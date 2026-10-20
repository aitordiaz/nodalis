import 'package:nodalis_domain/nodalis_domain.dart';
import 'package:test/test.dart';

void main() {
  group('RulesEngine', () {
    test('doSegmentsCross detects strict orthogonal crossing', () {
      // Horizontal segment from (1, 3) to (5, 3)
      // Vertical segment from (3, 1) to (3, 5)
      // Intersection at (3, 3) -> STRICT CROSSING
      expect(
        RulesEngine.doSegmentsCross(
          a1: (x: 1, y: 3),
          a2: (x: 5, y: 3),
          b1: (x: 3, y: 1),
          b2: (x: 3, y: 5),
        ),
        isTrue,
      );

      // Segments sharing an endpoint do NOT cross
      expect(
        RulesEngine.doSegmentsCross(
          a1: (x: 1, y: 3),
          a2: (x: 3, y: 3),
          b1: (x: 3, y: 3),
          b2: (x: 3, y: 5),
        ),
        isFalse,
      );

      // Parallel segments do not cross
      expect(
        RulesEngine.doSegmentsCross(
          a1: (x: 1, y: 1),
          a2: (x: 5, y: 1),
          b1: (x: 1, y: 3),
          b2: (x: 5, y: 3),
        ),
        isFalse,
      );
    });

    test('findInterveningIslandId identifies blocking islands', () {
      const islands = [
        Island(id: 1, position: (x: 1, y: 1), requiredBridges: 2),
        Island(id: 2, position: (x: 3, y: 1), requiredBridges: 2),
        Island(id: 3, position: (x: 5, y: 1), requiredBridges: 2),
      ];

      final blocker = RulesEngine.findInterveningIslandId(
        from: (x: 1, y: 1),
        to: (x: 5, y: 1),
        allIslands: islands,
      );

      expect(blocker, equals(2));
    });

    test('findConnectedComponents correctly partitions graphs', () {
      final islands = [1, 2, 3, 4];
      final bridges = {
        makeBridgeKey(1, 2):
            Bridge(islandAId: 1, islandBId: 2, count: BridgeCount.single),
        makeBridgeKey(3, 4):
            Bridge(islandAId: 3, islandBId: 4, count: BridgeCount.single),
      };

      final components = RulesEngine.findConnectedComponents(
        islandIds: islands,
        bridges: bridges,
      );

      expect(components.length, equals(2));
      expect(components.any((c) => c.containsAll([1, 2])), isTrue);
      expect(components.any((c) => c.containsAll([3, 4])), isTrue);
    });
  });

  group('Board Gameplay & Invariants', () {
    test('simple 2-island level solves properly', () {
      final board = Board.initial(
        width: 5,
        height: 5,
        islands: [
          const Island(id: 1, position: (x: 1, y: 2), requiredBridges: 1),
          const Island(id: 2, position: (x: 3, y: 2), requiredBridges: 1),
        ],
      );

      expect(board.isSolved, isFalse);

      final result =
          board.applyAction(const CycleBridgeAction(fromId: 1, toId: 2));
      expect(result.isOk, isTrue);

      final nextBoard = result.valueOrNull!;
      expect(nextBoard.isSolved, isTrue);
      expect(nextBoard.getConnectedBridgeCount(1), equals(1));
      expect(nextBoard.isIslandSatisfied(1), isTrue);
      expect(nextBoard.isIslandSatisfied(2), isTrue);
    });

    test('rejects crossing bridges', () {
      // Create a cross:
      // Island 1 (1, 3) <-> Island 2 (5, 3) [horizontal]
      // Island 3 (3, 1) <-> Island 4 (3, 5) [vertical]
      var board = Board.initial(
        width: 7,
        height: 7,
        islands: [
          const Island(id: 1, position: (x: 1, y: 3), requiredBridges: 1),
          const Island(id: 2, position: (x: 5, y: 3), requiredBridges: 1),
          const Island(id: 3, position: (x: 3, y: 1), requiredBridges: 1),
          const Island(id: 4, position: (x: 3, y: 5), requiredBridges: 1),
        ],
      );

      // Connect 1 <-> 2
      final res1 =
          board.applyAction(const CycleBridgeAction(fromId: 1, toId: 2));
      expect(res1.isOk, isTrue);
      board = res1.valueOrNull!;

      // Attempt to connect 3 <-> 4 (crosses 1-2)
      final res2 =
          board.applyAction(const CycleBridgeAction(fromId: 3, toId: 4));
      expect(res2.isErr, isTrue);
      expect(res2.errorOrNull, isA<CrossingBridgeFailure>());
    });

    test('rejects exceeding island capacity', () {
      final board = Board.initial(
        width: 5,
        height: 5,
        islands: [
          const Island(id: 1, position: (x: 1, y: 1), requiredBridges: 1),
          const Island(id: 2, position: (x: 3, y: 1), requiredBridges: 1),
        ],
      );

      // Attempting to set double bridge when capacity is 1
      final res = board.applyAction(const SetBridgeAction(
        fromId: 1,
        toId: 2,
        targetCount: BridgeCount.double,
      ));

      expect(res.isErr, isTrue);
      expect(res.errorOrNull, isA<CapacityExceededFailure>());
    });
  });
}
