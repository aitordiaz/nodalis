import 'package:meta/meta.dart';

/// The category of logical deduction used to derive the hint.
enum HintCategory {
  /// User placed an invalid bridge or blocked an island from being completed.
  mistakeCorrection,

  /// An island's remaining required bridges exactly equal the available room of its open neighbors.
  saturation,

  /// An island's remaining demand exceeds the capacity of all other corridors combined (Pigeonhole principle).
  pigeonhole,

  /// Connecting would prematurely isolate a closed sub-component from the rest of the graph.
  isolationAvoidance,

  /// Global network connectivity deduction derived from solution analysis.
  globalConnectivity,

  /// Puzzle is already fully solved.
  alreadySolved,
}

/// Graded hint providing progressive disclosure from a gentle nudge to full solution.
@immutable
final class DeductiveHint {
  /// Primary island that the user should focus on.
  final int primaryIslandId;

  /// Secondary island to connect to, if applicable.
  final int? secondaryIslandId;

  /// Target bridge count between [primaryIslandId] and [secondaryIslandId] if applicable.
  final int? targetBridgeCount;

  /// Underlying category of the deduction.
  final HintCategory category;

  /// Level 1 (Nudge): Subtle attention direction without spoiling the logic or answer.
  final String nudge;

  /// Level 2 (Insight): The logical reasoning and principle behind the deduction.
  final String insight;

  /// Level 3 (Solution Step): Explicit concrete instruction on what action to perform.
  final String solutionStep;

  /// Whether this hint points out a user mistake that should be undone.
  final bool isMistake;

  const DeductiveHint({
    required this.primaryIslandId,
    this.secondaryIslandId,
    this.targetBridgeCount,
    required this.category,
    required this.nudge,
    required this.insight,
    required this.solutionStep,
    this.isMistake = false,
  });

  /// Factory for already solved state.
  factory DeductiveHint.alreadySolved() {
    return const DeductiveHint(
      primaryIslandId: 0,
      category: HintCategory.alreadySolved,
      nudge: 'All islands are properly connected!',
      insight:
          'The puzzle has met all bridge counts and forms a single connected network.',
      solutionStep: 'Puzzle is complete.',
    );
  }

  /// Factory for an overloaded island mistake.
  factory DeductiveHint.overloadedIsland({
    required int islandId,
    required int requiredBridges,
    required int currentBridges,
  }) {
    return DeductiveHint(
      primaryIslandId: islandId,
      category: HintCategory.mistakeCorrection,
      isMistake: true,
      nudge: 'Take a close look at Island $islandId.',
      insight:
          'Island $islandId has $currentBridges bridges connected, but only needs $requiredBridges.',
      solutionStep: 'Remove the excess bridges connected to Island $islandId.',
    );
  }

  /// Factory for a stranded/blocked island mistake.
  factory DeductiveHint.strandedIsland({
    required int islandId,
    required int requiredBridges,
    required int currentBridges,
  }) {
    final remaining = requiredBridges - currentBridges;
    return DeductiveHint(
      primaryIslandId: islandId,
      category: HintCategory.mistakeCorrection,
      isMistake: true,
      nudge: 'Island $islandId is blocked and cannot be completed.',
      insight:
          'Island $islandId still needs $remaining bridge(s), but crossing bridges or satisfied neighbors prevent any further connections.',
      solutionStep:
          'Undo recent moves to unblock corridors for Island $islandId.',
    );
  }
}
