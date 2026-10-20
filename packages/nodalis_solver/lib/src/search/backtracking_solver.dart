import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:nodalis_domain/nodalis_domain.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';
import '../../nodalis_solver.dart';

/// Candidate undirected edge between two orthogonally adjacent islands.
final class CandidateEdge {
  final int islandAId;
  final int islandBId;
  final GridPoint posA;
  final GridPoint posB;

  const CandidateEdge({
    required this.islandAId,
    required this.islandBId,
    required this.posA,
    required this.posB,
  });

  BridgeKey get key => makeBridgeKey(islandAId, islandBId);
}

/// High-performance backtracking constraint solver for Hashi logic puzzles.
/// Used for formal level validation, uniqueness proofs, and solution hashing.
class BacktrackingSolver implements LevelSolver {
  const BacktrackingSolver();

  @override
  SolverResult solve(Board board, {int maxSolutions = 2}) {
    final stopwatch = Stopwatch()..start();
    final islands = board.islands;

    // Fast check: Handshaking Lemma (sum of degrees must be even)
    final totalCapacity =
        islands.values.fold<int>(0, (sum, i) => sum + i.requiredBridges);
    if (totalCapacity % 2 != 0) {
      stopwatch.stop();
      return SolverResult(
        solutions: const [],
        statesExplored: 0,
        duration: stopwatch.elapsed,
      );
    }

    // 1. Identify all candidate orthogonal edges (no intervening islands)
    final candidateEdges = _findCandidateEdges(board);

    // 2. Precompute crossing edge conflicts (for fast bitwise / boolean checks)
    final crossingMap = <int, List<int>>{};
    for (var i = 0; i < candidateEdges.length; i++) {
      crossingMap[i] = [];
      for (var j = 0; j < candidateEdges.length; j++) {
        if (i == j) continue;
        final edgeA = candidateEdges[i];
        final edgeB = candidateEdges[j];

        // If they share an island, they cannot cross
        if (edgeA.islandAId == edgeB.islandAId ||
            edgeA.islandAId == edgeB.islandBId ||
            edgeA.islandBId == edgeB.islandAId ||
            edgeA.islandBId == edgeB.islandBId) {
          continue;
        }

        if (RulesEngine.doSegmentsCross(
          a1: edgeA.posA,
          a2: edgeA.posB,
          b1: edgeB.posA,
          b2: edgeB.posB,
        )) {
          crossingMap[i]!.add(j);
        }
      }
    }

    // Edge assignment array: -1 = unassigned, 0 = none, 1 = single, 2 = double
    final assignments = List<int>.filled(candidateEdges.length, -1);
    final solutions = <Board>[];
    var statesExplored = 0;

    void backtrack(int edgeIndex) {
      if (solutions.length >= maxSolutions) return;
      statesExplored++;

      if (edgeIndex == candidateEdges.length) {
        // Leaf reached: verify all island capacities and single connected component
        final leafBoard =
            _buildBoardFromAssignments(board, candidateEdges, assignments);
        if (leafBoard.isSolved) {
          solutions.add(leafBoard);
        }
        return;
      }

      // Values to try: [0, 1, 2]
      for (var count = 0; count <= 2; count++) {
        // If count > 0, verify it doesn't cross any already-assigned active edge
        if (count > 0) {
          var crosses = false;
          for (final conflictingIndex in crossingMap[edgeIndex]!) {
            if (conflictingIndex < edgeIndex &&
                assignments[conflictingIndex] > 0) {
              crosses = true;
              break;
            }
          }
          if (crosses) continue;
        }

        // Verify capacity is not exceeded for either endpoint
        assignments[edgeIndex] = count;
        if (_isCapacityFeasible(
            islands, candidateEdges, assignments, edgeIndex)) {
          backtrack(edgeIndex + 1);
        }
        assignments[edgeIndex] = -1;

        if (solutions.length >= maxSolutions) return;
      }
    }

    backtrack(0);
    stopwatch.stop();

    return SolverResult(
      solutions: solutions,
      statesExplored: statesExplored,
      duration: stopwatch.elapsed,
    );
  }

  @override
  bool validateUniqueness(LevelDefinition level) {
    final board = level.toInitialBoard();
    final result = solve(board, maxSolutions: 2);
    return result.isUnique;
  }

  /// Calculates deterministic SHA-256 hash of a solved board's active bridges.
  static String calculateSolutionHash(Board solvedBoard) {
    final activeBridges =
        solvedBoard.bridges.values.where((b) => b.isActive).toList()
          ..sort((a, b) {
            if (a.islandAId != b.islandAId) {
              return a.islandAId.compareTo(b.islandAId);
            }
            return a.islandBId.compareTo(b.islandBId);
          });

    final serialized = activeBridges
        .map((b) => '${b.islandAId}-${b.islandBId}:${b.count.value}')
        .join(';');
    return sha256.convert(utf8.encode(serialized)).toString();
  }

  List<CandidateEdge> _findCandidateEdges(Board board) {
    final edges = <CandidateEdge>[];
    final islands = board.islands;

    for (final islandA in islands.values) {
      final neighbors = board.getAvailableOrthogonalNeighbors(islandA.id);
      for (final islandB in neighbors) {
        if (islandA.id < islandB.id) {
          edges.add(CandidateEdge(
            islandAId: islandA.id,
            islandBId: islandB.id,
            posA: islandA.position,
            posB: islandB.position,
          ));
        }
      }
    }
    return edges;
  }

  bool _isCapacityFeasible(
    Map<int, Island> islands,
    List<CandidateEdge> edges,
    List<int> assignments,
    int currentEdgeIndex,
  ) {
    final currentEdge = edges[currentEdgeIndex];
    final endpointIds = [currentEdge.islandAId, currentEdge.islandBId];

    for (final islandId in endpointIds) {
      final island = islands[islandId]!;
      var assignedSum = 0;
      var maxPossibleRemaining = 0;

      for (var i = 0; i < edges.length; i++) {
        final e = edges[i];
        if (e.islandAId == islandId || e.islandBId == islandId) {
          if (assignments[i] >= 0) {
            assignedSum += assignments[i];
          } else {
            maxPossibleRemaining += 2; // Maximum double bridge
          }
        }
      }

      // 1. Capacity overflow
      if (assignedSum > island.requiredBridges) {
        return false;
      }

      // 2. Capacity deficit (even with double bridges on all remaining edges, cannot reach capacity)
      if (assignedSum + maxPossibleRemaining < island.requiredBridges) {
        return false;
      }
    }

    return true;
  }

  Board _buildBoardFromAssignments(
    Board initialBoard,
    List<CandidateEdge> edges,
    List<int> assignments,
  ) {
    final bridges = <BridgeKey, Bridge>{};

    for (var i = 0; i < edges.length; i++) {
      final countValue = assignments[i];
      if (countValue > 0) {
        final edge = edges[i];
        final count = countValue == 1 ? BridgeCount.single : BridgeCount.double;
        bridges[edge.key] = Bridge(
          islandAId: edge.islandAId,
          islandBId: edge.islandBId,
          count: count,
        );
      }
    }

    return Board(
      width: initialBoard.width,
      height: initialBoard.height,
      islands: initialBoard.islands,
      bridges: Map.unmodifiable(bridges),
    );
  }
}
