import 'package:nodalis_level_format/nodalis_level_format.dart';
import '../../nodalis_solver.dart';

/// Validation report produced by [LevelValidator].
final class LevelValidationReport {
  final String levelId;
  final bool isValid;
  final bool isSolvable;
  final bool isUnique;
  final int solutionCount;
  final String? computedSolutionHash;
  final List<String> errors;

  const LevelValidationReport({
    required this.levelId,
    required this.isValid,
    required this.isSolvable,
    required this.isUnique,
    required this.solutionCount,
    this.computedSolutionHash,
    required this.errors,
  });

  bool get passed => isValid && isSolvable && isUnique && errors.isEmpty;
}

/// Headless validator ensuring level definitions are structurally sound and uniquely solvable.
final class LevelValidator {
  final LevelSolver _solver;

  const LevelValidator({LevelSolver solver = const BacktrackingSolver()})
      : _solver = solver;

  LevelValidationReport validate(LevelDefinition level) {
    final errors = <String>[];

    if (level.islands.length < 2) {
      errors.add('Level has fewer than 2 islands.');
    }

    // Coordinate & ID uniqueness checks
    final seenCoords = <String>{};
    final seenIds = <int>{};
    var totalCapacity = 0;

    for (final island in level.islands) {
      final coord = '${island.position.x},${island.position.y}';
      if (!seenCoords.add(coord)) {
        errors.add('Duplicate island position ($coord).');
      }
      if (!seenIds.add(island.id)) {
        errors.add('Duplicate island ID (${island.id}).');
      }
      if (island.position.x < 0 || island.position.x >= level.gridWidth) {
        errors
            .add('Island ${island.id} X (${island.position.x}) out of bounds.');
      }
      if (island.position.y < 0 || island.position.y >= level.gridHeight) {
        errors
            .add('Island ${island.id} Y (${island.position.y}) out of bounds.');
      }
      if (island.requiredBridges < 1 || island.requiredBridges > 8) {
        errors.add(
            'Island ${island.id} capacity (${island.requiredBridges}) out of valid range 1..8.');
      }
      totalCapacity += island.requiredBridges;
    }

    if (totalCapacity % 2 != 0) {
      errors.add(
          'Total capacity ($totalCapacity) is odd; puzzle violates the Handshaking Lemma.');
    }

    if (errors.isNotEmpty) {
      return LevelValidationReport(
        levelId: level.id,
        isValid: false,
        isSolvable: false,
        isUnique: false,
        solutionCount: 0,
        errors: errors,
      );
    }

    // Solve and check uniqueness
    final initialBoard = level.toInitialBoard();
    final solveResult = _solver.solve(initialBoard, maxSolutions: 2);
    final count = solveResult.solutions.length;

    String? computedHash;
    if (count > 0) {
      computedHash =
          BacktrackingSolver.calculateSolutionHash(solveResult.solutions.first);
    }

    if (count == 0) {
      errors.add(
          'Level is unsolvable; no legal configuration satisfies all rules.');
    } else if (count > 1) {
      errors.add(
          'Level has multiple solutions; violates uniqueness requirement ($count found).');
    }

    if (level.verification?.solutionHash != null &&
        level.verification!.solutionHash.isNotEmpty &&
        computedHash != null) {
      if (level.verification!.solutionHash != computedHash) {
        errors.add(
            'Solution hash mismatch. Expected ${level.verification!.solutionHash}, got $computedHash.');
      }
    }

    return LevelValidationReport(
      levelId: level.id,
      isValid: errors.isEmpty,
      isSolvable: count > 0,
      isUnique: count == 1,
      solutionCount: count,
      computedSolutionHash: computedHash,
      errors: errors,
    );
  }
}
