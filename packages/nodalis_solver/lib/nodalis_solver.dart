import 'package:meta/meta.dart';
import 'package:nodalis_domain/nodalis_domain.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';

export 'src/deduction/deductive_engine.dart';
export 'src/deduction/deductive_hint.dart';
export 'src/generator/puzzle_generator.dart';
export 'src/search/backtracking_solver.dart';
export 'src/validator/level_validator.dart';

/// Result produced by the solver during level verification or solving.
@immutable
final class SolverResult {
  final List<Board> solutions;
  final int statesExplored;
  final Duration duration;

  const SolverResult({
    required this.solutions,
    required this.statesExplored,
    required this.duration,
  });

  bool get isSolvable => solutions.isNotEmpty;
  bool get isUnique => solutions.length == 1;
}

/// Abstract contract for puzzle solvers and hint generators.
abstract interface class LevelSolver {
  /// Solves a board and returns all satisfying solutions up to [maxSolutions].
  SolverResult solve(Board board, {int maxSolutions = 2});

  /// Validates whether a [LevelDefinition] is valid and has a unique solution.
  bool validateUniqueness(LevelDefinition level);
}
