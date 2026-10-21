import 'package:nodalis_domain/nodalis_domain.dart';
import '../../nodalis_solver.dart';

/// Non-spoiling deductive hint generator for Hashiwokakero puzzles.
///
/// Evaluates logical heuristics (saturation, pigeonhole, isolation avoidance)
/// before falling back to full uniqueness constraint analysis.
class DeductiveEngine {
  final BacktrackingSolver _solver;

  const DeductiveEngine({
    BacktrackingSolver solver = const BacktrackingSolver(),
  }) : _solver = solver;

  /// Generates the next best deductive hint for the current board state.
  ///
  /// Returns `null` only if the board has no islands.
  DeductiveHint? evaluateHint({
    required Board board,
    Board? initialBoard,
  }) {
    if (board.islands.isEmpty) return null;

    if (board.isSolved) {
      return DeductiveHint.alreadySolved();
    }

    // 1. Detect user mistakes: Overloaded islands
    for (final island in board.islands.values) {
      final connected = board.getConnectedBridgeCount(island.id);
      if (connected > island.requiredBridges) {
        return DeductiveHint.overloadedIsland(
          islandId: island.id,
          requiredBridges: island.requiredBridges,
          currentBridges: connected,
        );
      }
    }

    // Precalculate available corridor capacity for each island
    final corridorRooms = <int, Map<int, int>>{};
    for (final island in board.islands.values) {
      corridorRooms[island.id] = {};
      final neighbors = board.getAvailableOrthogonalNeighbors(island.id);
      for (final neighbor in neighbors) {
        final room = _calculateCorridorRoom(board, island, neighbor);
        if (room > 0) {
          corridorRooms[island.id]![neighbor.id] = room;
        }
      }
    }

    // 2. Detect user mistakes: Stranded/blocked islands with unmet capacity
    for (final island in board.islands.values) {
      final remaining = board.getRemainingCapacity(island.id);
      if (remaining > 0) {
        final totalRoom = corridorRooms[island.id]!.values.fold<int>(0, (s, r) => s + r);
        if (totalRoom < remaining) {
          return DeductiveHint.strandedIsland(
            islandId: island.id,
            requiredBridges: island.requiredBridges,
            currentBridges: board.getConnectedBridgeCount(island.id),
          );
        }
      }
    }

    // 3. Heuristic: Saturation / Degree Deficit
    // If an island's remaining capacity equals the sum of maximum available capacity
    // across all open corridors, every corridor must be filled to its maximum capacity.
    for (final island in board.islands.values) {
      final remaining = board.getRemainingCapacity(island.id);
      if (remaining <= 0) continue;

      final openNeighbors = corridorRooms[island.id]!;
      if (openNeighbors.isEmpty) continue;

      final totalRoom = openNeighbors.values.fold<int>(0, (s, r) => s + r);
      if (totalRoom == remaining) {
        // Find the first neighbor with room
        final entry = openNeighbors.entries.first;
        final neighborId = entry.key;
        final room = entry.value;
        final currentBridge = board.bridges[makeBridgeKey(island.id, neighborId)];
        final currentCount = currentBridge?.isActive == true ? currentBridge!.count.value : 0;
        final targetCount = currentCount + room;

        if (openNeighbors.length == 1) {
          return DeductiveHint(
            primaryIslandId: island.id,
            secondaryIslandId: neighborId,
            targetBridgeCount: targetCount,
            category: HintCategory.saturation,
            nudge: 'Examine Island ${island.id}. How many accessible neighbors does it have?',
            insight: 'Island ${island.id} still needs $remaining bridge(s) and only has one neighbor with available capacity (Island $neighborId). All remaining bridges must connect here.',
            solutionStep: 'Connect $targetCount bridge(s) between Island ${island.id} and Island $neighborId.',
          );
        } else {
          return DeductiveHint(
            primaryIslandId: island.id,
            secondaryIslandId: neighborId,
            targetBridgeCount: targetCount,
            category: HintCategory.saturation,
            nudge: 'Look at Island ${island.id} and the available room of its open neighbors.',
            insight: 'Island ${island.id} needs $remaining bridge(s), which exactly matches the total capacity all its open corridors can absorb ($totalRoom). Every available path must be filled to maximum capacity.',
            solutionStep: 'Place bridge(s) between Island ${island.id} and Island $neighborId.',
          );
        }
      }
    }

    // 4. Heuristic: Pigeonhole Principle
    // If an island's remaining capacity exceeds the sum of capacities of all other corridors,
    // it MUST send at least (remaining - otherMax) bridges to this corridor.
    for (final island in board.islands.values) {
      final remaining = board.getRemainingCapacity(island.id);
      if (remaining <= 0) continue;

      final openNeighbors = corridorRooms[island.id]!;
      if (openNeighbors.length < 2) continue;

      for (final entry in openNeighbors.entries) {
        final neighborId = entry.key;

        // Sum of all other corridors
        final otherMax = openNeighbors.entries
            .where((e) => e.key != neighborId)
            .fold<int>(0, (s, e) => s + e.value);

        if (remaining > otherMax) {
          final minNeeded = remaining - otherMax;
          final currentBridge = board.bridges[makeBridgeKey(island.id, neighborId)];
          final currentCount = currentBridge?.isActive == true ? currentBridge!.count.value : 0;

          if (currentCount < minNeeded) {
            return DeductiveHint(
              primaryIslandId: island.id,
              secondaryIslandId: neighborId,
              targetBridgeCount: minNeeded,
              category: HintCategory.pigeonhole,
              nudge: 'Notice Island ${island.id} with requirement of ${island.requiredBridges} bridges.',
              insight: 'Island ${island.id} needs $remaining more bridge(s). Even if all other neighbors absorb their absolute maximum ($otherMax), Island ${island.id} still must send at least $minNeeded bridge(s) toward Island $neighborId.',
              solutionStep: 'Place at least $minNeeded bridge(s) between Island ${island.id} and Island $neighborId.',
            );
          }
        }
      }
    }

    // 5. Heuristic: Isolation Avoidance (Premature Subgraph Closure)
    // If connecting island A and island B would satisfy both completely, but leaves
    // other islands disconnected from them, that connection is forbidden.
    final totalIslands = board.islands.length;
    if (totalIslands > 2) {
      for (final island in board.islands.values) {
        final remainingA = board.getRemainingCapacity(island.id);
        if (remainingA <= 0) continue;

        final openNeighbors = corridorRooms[island.id]!;
        for (final entry in openNeighbors.entries) {
          final neighborId = entry.key;
          final remainingB = board.getRemainingCapacity(neighborId);

          // If remainingA == remainingB and connecting them with remainingA bridges would close both
          if (remainingA == remainingB && (remainingA == 1 || remainingA == 2)) {
            // Check component size if this were connected
            final targetBridgeCount = remainingA == 2 ? BridgeCount.double : BridgeCount.single;
            final testBoardResult = board.applyAction(
              SetBridgeAction(
                fromId: island.id,
                toId: neighborId,
                targetCount: targetBridgeCount,
              ),
            );

            if (testBoardResult.isOk) {
              final testBoard = testBoardResult.valueOrNull!;
              final components = RulesEngine.findConnectedComponents(
                islandIds: testBoard.islands.keys,
                bridges: testBoard.bridges,
              );

              // Find component containing island.id
              final comp = components.firstWhere(
                (c) => c.contains(island.id),
                orElse: () => {},
              );

              // If closed (all islands in comp have 0 remaining capacity) but doesn't cover all islands
              if (comp.length < totalIslands) {
                final compRemaining = comp.fold<int>(
                  0,
                  (s, id) => s + testBoard.getRemainingCapacity(id),
                );

                if (compRemaining == 0) {
                  // Connecting island and neighbor would isolate them!
                  // If island has other neighbors, it must connect to them instead.
                  final otherNeighbors = openNeighbors.keys.where((id) => id != neighborId).toList();
                  if (otherNeighbors.isNotEmpty) {
                    final targetId = otherNeighbors.first;
                    return DeductiveHint(
                      primaryIslandId: island.id,
                      secondaryIslandId: targetId,
                      category: HintCategory.isolationAvoidance,
                      nudge: 'Watch out: connecting Island ${island.id} to Island $neighborId would isolate them.',
                      insight: 'Connecting Island ${island.id} directly to Island $neighborId would seal them into a closed group with no way to connect the remaining ${totalIslands - comp.length} island(s). Island ${island.id} must connect elsewhere.',
                      solutionStep: 'Connect Island ${island.id} toward Island $targetId instead.',
                    );
                  }
                }
              }
            }
          }
        }
      }
    }

    // 6. Solver Fallback: Global Connectivity Search
    // Solve from initial board or current board to find the next confirmed bridge.
    final solveTarget = initialBoard ?? Board.initial(
      width: board.width,
      height: board.height,
      islands: board.islands.values,
    );

    final solverResult = _solver.solve(solveTarget, maxSolutions: 1);
    if (solverResult.solutions.isNotEmpty) {
      final solvedBoard = solverResult.solutions.first;
      for (final bridge in solvedBoard.bridges.values) {
        if (!bridge.isActive) continue;

        final currentBridge = board.bridges[bridge.key];
        final currentCount = currentBridge?.isActive == true ? currentBridge!.count.value : 0;

        if (currentCount < bridge.count.value) {
          final targetCount = bridge.count.value;
          return DeductiveHint(
            primaryIslandId: bridge.islandAId,
            secondaryIslandId: bridge.islandBId,
            targetBridgeCount: targetCount,
            category: HintCategory.globalConnectivity,
            nudge: 'Consider Island ${bridge.islandAId} and its surrounding network.',
            insight: 'Based on global network constraints, Island ${bridge.islandAId} must connect to Island ${bridge.islandBId} to maintain graph connectivity.',
            solutionStep: 'Place a bridge between Island ${bridge.islandAId} and Island ${bridge.islandBId}.',
          );
        }
      }
    }

    return null;
  }

  /// Calculates how many additional bridges can legally be placed between [islandA] and [islandB].
  int _calculateCorridorRoom(Board board, Island islandA, Island islandB) {
    final key = makeBridgeKey(islandA.id, islandB.id);
    final currentBridge = board.bridges[key];
    final currentCount = currentBridge?.isActive == true ? currentBridge!.count.value : 0;

    if (currentCount >= 2) return 0;

    // Remaining capacity of neighbor B
    final remB = board.getRemainingCapacity(islandB.id);
    if (remB <= 0) return 0;

    // Test adding 1 bridge
    final nextCount = currentCount == 1 ? BridgeCount.double : BridgeCount.single;
    final testResult = RulesEngine.validateBridgePlacement(
      from: islandA,
      to: islandB,
      newCount: nextCount,
      allIslands: board.islands.values,
      existingBridges: board.bridges,
      islandMap: board.islands,
    );

    if (testResult.isErr) return 0;

    // Max room is at most 2 - currentCount, and at most remB
    final potentialRoom = 2 - currentCount;
    return potentialRoom > remB ? remB : potentialRoom;
  }
}
