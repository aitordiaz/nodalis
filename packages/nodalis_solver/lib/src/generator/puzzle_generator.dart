import 'dart:math';
import 'package:nodalis_domain/nodalis_domain.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';
import '../../nodalis_solver.dart';

/// Fast, deterministic procedural puzzle generator for Hashiwokakero.
/// Generates guaranteed uniquely solvable puzzles across difficulty tiers.
class PuzzleGenerator {
  final BacktrackingSolver _solver;

  const PuzzleGenerator({
    BacktrackingSolver solver = const BacktrackingSolver(),
  }) : _solver = solver;

  /// Generates a uniquely solvable [LevelDefinition].
  ///
  /// If [seed] is provided, generation is 100% deterministic (ideal for Daily Puzzles).
  LevelDefinition? generate({
    int width = 7,
    int height = 7,
    int islandCount = 7,
    DifficultyTier difficulty = DifficultyTier.medium,
    int? seed,
    int maxAttempts = 300,
  }) {
    final rng = Random(seed);

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final positions = _generateIslandPositions(width, height, islandCount, rng);
      if (positions == null) continue;

      final candidateEdges = _findOrthogonalCorridors(positions);
      if (candidateEdges.isEmpty) continue;

      final crossingPairs = _findCrossingEdgePairs(positions, candidateEdges);

      // Attempt to build a random connected graph of bridges
      final edgeCounts = _buildRandomConnectedGraph(
        positions: positions,
        candidateEdges: candidateEdges,
        crossingPairs: crossingPairs,
        rng: rng,
      );
      if (edgeCounts == null) continue;

      // Compute island capacities from incident bridge counts
      final capacities = {for (final p in positions) p.$1: 0};
      for (var i = 0; i < candidateEdges.length; i++) {
        final count = edgeCounts[i];
        if (count > 0) {
          final edge = candidateEdges[i];
          capacities[edge.$1] = capacities[edge.$1]! + count;
          capacities[edge.$2] = capacities[edge.$2]! + count;
        }
      }

      // Skip if any island has 0 capacity or exceeds max Hashi degree of 8
      if (capacities.values.any((c) => c <= 0 || c > 8)) continue;

      final islands = positions
          .map((p) => Island(
                id: p.$1,
                position: (x: p.$2, y: p.$3),
                requiredBridges: capacities[p.$1]!,
              ))
          .toList();

      final board = Board.initial(
        width: width,
        height: height,
        islands: islands,
      );

      // Solve and verify strict uniqueness
      final result = _solver.solve(board, maxSolutions: 2);
      if (result.isUnique) {
        final solvedBoard = result.solutions.first;
        final hash = BacktrackingSolver.calculateSolutionHash(solvedBoard);

        final levelId = seed != null
            ? 'gen_seed_${seed}_${width}x$height'
            : 'gen_${DateTime.now().millisecondsSinceEpoch}';

        return LevelDefinition(
          id: levelId,
          version: 1,
          chapterId: 0, // 0 denotes generated / free play
          indexInChapter: 0,
          metadata: LevelMetadata(
            titleKey: 'Procedural Puzzle',
            author: 'Nodalis Generator',
            difficultyTier: difficulty,
            estimatedSolveTimeSeconds: islandCount * 18,
            parMoves: islandCount + 2,
            mechanics: ['procedural_generation', 'double_bridge'],
          ),
          gridWidth: width,
          gridHeight: height,
          islands: islands,
          tutorial: const LevelTutorial(
            hasInteractiveTutorial: false,
            hintTriggers: [],
          ),
          verification: LevelVerification(
            solutionHash: hash,
            uniquenessVerified: true,
            deductionDepth: 2,
          ),
        );
      }
    }

    return null;
  }

  List<(int, int, int)>? _generateIslandPositions(
    int width,
    int height,
    int count,
    Random rng,
  ) {
    final positions = <(int, int, int)>[];
    final occupied = <String>{};

    var safety = 0;
    while (positions.length < count && safety < 500) {
      safety++;
      final x = rng.nextInt(width);
      final y = rng.nextInt(height);
      final key = '$x,$y';

      if (occupied.contains(key)) continue;

      // Don't place directly adjacent (Manhattan distance 1) to leave room for visible bridges
      var tooClose = false;
      for (final p in positions) {
        final dx = (p.$2 - x).abs();
        final dy = (p.$3 - y).abs();
        if (dx + dy <= 1) {
          tooClose = true;
          break;
        }
      }
      if (tooClose) continue;

      occupied.add(key);
      positions.add((positions.length + 1, x, y));
    }

    return positions.length == count ? positions : null;
  }

  List<(int, int)> _findOrthogonalCorridors(List<(int, int, int)> positions) {
    final corridors = <(int, int)>[];

    for (var i = 0; i < positions.length; i++) {
      for (var j = i + 1; j < positions.length; j++) {
        final p1 = positions[i];
        final p2 = positions[j];

        // Must be strictly orthogonal
        if (p1.$2 != p2.$2 && p1.$3 != p2.$3) continue;

        // Check if any other island is directly between them
        var blocked = false;
        for (final other in positions) {
          if (other.$1 == p1.$1 || other.$1 == p2.$1) continue;

          if (p1.$2 == p2.$2 && other.$2 == p1.$2) {
            final minY = min(p1.$3, p2.$3);
            final maxY = max(p1.$3, p2.$3);
            if (other.$3 > minY && other.$3 < maxY) {
              blocked = true;
              break;
            }
          } else if (p1.$3 == p2.$3 && other.$3 == p1.$3) {
            final minX = min(p1.$2, p2.$2);
            final maxX = max(p1.$2, p2.$2);
            if (other.$2 > minX && other.$2 < maxX) {
              blocked = true;
              break;
            }
          }
        }

        if (!blocked) {
          corridors.add((p1.$1, p2.$1));
        }
      }
    }

    return corridors;
  }

  Set<(int, int)> _findCrossingEdgePairs(
    List<(int, int, int)> positions,
    List<(int, int)> edges,
  ) {
    final crossings = <(int, int)>{};

    for (var i = 0; i < edges.length; i++) {
      for (var j = i + 1; j < edges.length; j++) {
        final e1 = edges[i];
        final e2 = edges[j];
        if (e1.$1 == e2.$1 || e1.$1 == e2.$2 || e1.$2 == e2.$1 || e1.$2 == e2.$2) {
          continue;
        }

        final a1 = positions.firstWhere((p) => p.$1 == e1.$1);
        final a2 = positions.firstWhere((p) => p.$1 == e1.$2);
        final b1 = positions.firstWhere((p) => p.$1 == e2.$1);
        final b2 = positions.firstWhere((p) => p.$1 == e2.$2);

        if (RulesEngine.doSegmentsCross(
          a1: (x: a1.$2, y: a1.$3),
          a2: (x: a2.$2, y: a2.$3),
          b1: (x: b1.$2, y: b1.$3),
          b2: (x: b2.$2, y: b2.$3),
        )) {
          crossings.add((i, j));
        }
      }
    }

    return crossings;
  }

  List<int>? _buildRandomConnectedGraph({
    required List<(int, int, int)> positions,
    required List<(int, int)> candidateEdges,
    required Set<(int, int)> crossingPairs,
    required Random rng,
  }) {
    final edgeCounts = List<int>.filled(candidateEdges.length, 0);
    final shuffled = List.generate(candidateEdges.length, (i) => i)..shuffle(rng);
    final activeIndices = <int>[];

    final parent = <int, int>{for (final p in positions) p.$1: p.$1};
    int find(int i) {
      if (parent[i] == i) return i;
      return parent[i] = find(parent[i]!);
    }

    bool union(int i, int j) {
      final rootI = find(i);
      final rootJ = find(j);
      if (rootI != rootJ) {
        parent[rootI] = rootJ;
        return true;
      }
      return false;
    }

    bool crossesAnyActive(int candidateIdx) {
      for (final activeIdx in activeIndices) {
        final pair = (min(candidateIdx, activeIdx), max(candidateIdx, activeIdx));
        if (crossingPairs.contains(pair)) {
          return true;
        }
      }
      return false;
    }

    // Phase 1: Build spanning tree to guarantee connectivity without crossings
    var componentsRemaining = positions.length;
    final unusedIndices = <int>[];

    for (final idx in shuffled) {
      final edge = candidateEdges[idx];
      if (find(edge.$1) != find(edge.$2)) {
        if (!crossesAnyActive(idx)) {
          union(edge.$1, edge.$2);
          componentsRemaining--;
          activeIndices.add(idx);
          final count = rng.nextDouble() < 0.35 ? 2 : 1;
          edgeCounts[idx] = count;
        } else {
          unusedIndices.add(idx);
        }
      } else {
        unusedIndices.add(idx);
      }
    }

    // If spanning tree could not connect all islands, skip attempt
    if (componentsRemaining > 1) {
      return null;
    }

    // Phase 2: Add sparse chords to create interesting deductive cycles
    for (final idx in unusedIndices) {
      if (rng.nextDouble() < 0.22) {
        if (!crossesAnyActive(idx)) {
          activeIndices.add(idx);
          final count = rng.nextDouble() < 0.30 ? 2 : 1;
          edgeCounts[idx] = count;
        }
      }
    }

    return edgeCounts;
  }
}
