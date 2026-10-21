import 'package:nodalis_level_format/nodalis_level_format.dart';
import 'package:nodalis_solver/nodalis_solver.dart';
import 'package:test/test.dart';

void main() {
  group('PuzzleGenerator', () {
    const generator = PuzzleGenerator();
    const validator = LevelValidator();

    test('generates valid, uniquely solvable puzzle', () {
      final level = generator.generate(
        width: 6,
        height: 6,
        islandCount: 6,
        seed: 12345,
      );

      expect(level, isNotNull);
      expect(level!.islands.length, 6);
      expect(level.gridWidth, 6);
      expect(level.gridHeight, 6);

      // Verify with formal LevelValidator
      final report = validator.validate(level);
      expect(report.passed, isTrue);
      expect(report.isSolvable, isTrue);
      expect(report.isUnique, isTrue);
      expect(report.solutionCount, 1);
    });

    test('generates deterministically with the same seed', () {
      final level1 = generator.generate(width: 7, height: 7, islandCount: 7, seed: 999);
      final level2 = generator.generate(width: 7, height: 7, islandCount: 7, seed: 999);

      expect(level1, isNotNull);
      expect(level2, isNotNull);
      expect(level1!.id, level2!.id);
      expect(level1.verification?.solutionHash, level2.verification?.solutionHash);
      expect(level1.islands.length, level2.islands.length);

      for (var i = 0; i < level1.islands.length; i++) {
        expect(level1.islands[i].id, level2.islands[i].id);
        expect(level1.islands[i].position, level2.islands[i].position);
        expect(level1.islands[i].requiredBridges, level2.islands[i].requiredBridges);
      }
    });

    test('generates across multiple seeds and difficulty tiers', () {
      const dateSeed = 20261021;
      final dailyLevel = generator.generate(
        width: 7,
        height: 7,
        islandCount: 8,
        seed: dateSeed,
        difficulty: DifficultyTier.medium,
      );

      expect(dailyLevel, isNotNull);
      final report = validator.validate(dailyLevel!);
      expect(report.passed, isTrue);
      expect(report.isUnique, isTrue);

      final masterLevel = generator.generate(
        width: 8,
        height: 8,
        islandCount: 8,
        seed: 424242,
        difficulty: DifficultyTier.hard,
      );
      expect(masterLevel, isNotNull);
      expect(validator.validate(masterLevel!).isUnique, isTrue);
    });
  });
}
