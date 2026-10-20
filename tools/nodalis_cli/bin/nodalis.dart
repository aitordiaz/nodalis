import 'dart:io';
import 'package:args/args.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';
import 'package:nodalis_solver/nodalis_solver.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addCommand('validate-all')
    ..addOption('dir', abbr: 'd', defaultsTo: 'levels')
    ..addFlag('update-hashes', abbr: 'u', defaultsTo: false);

  final results = parser.parse(arguments);

  if (results.command?.name == 'validate-all' || arguments.isEmpty) {
    final dirPath = results['dir'] as String? ?? 'levels';
    final directory = Directory(dirPath);

    if (!directory.existsSync()) {
      stderr.writeln('Directory not found: $dirPath');
      exit(1);
    }

    final levelFiles = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.json') && !f.path.contains('schema'))
        .toList();

    if (levelFiles.isEmpty) {
      stdout.writeln('No level files found in $dirPath');
      exit(0);
    }

    stdout.writeln('Validating ${levelFiles.length} level file(s)...');
    final shouldUpdateHashes = results['update-hashes'] as bool? ?? false;
    const validator = LevelValidator();
    var errors = 0;

    for (final file in levelFiles) {
      try {
        final content = file.readAsStringSync();
        var level = LevelParser.parseJson(content);

        var report = validator.validate(level);

        if (shouldUpdateHashes &&
            report.isUnique &&
            report.computedSolutionHash != null) {
          if (level.verification?.solutionHash != report.computedSolutionHash) {
            level = LevelDefinition(
              id: level.id,
              version: level.version,
              chapterId: level.chapterId,
              indexInChapter: level.indexInChapter,
              metadata: level.metadata,
              gridWidth: level.gridWidth,
              gridHeight: level.gridHeight,
              islands: level.islands,
              tutorial: level.tutorial,
              verification: LevelVerification(
                solutionHash: report.computedSolutionHash!,
                uniquenessVerified: true,
                deductionDepth: level.verification?.deductionDepth ?? 1,
              ),
            );
            file.writeAsStringSync(LevelParser.toJson(level));
            stdout.writeln(
                '  [HASH UPDATED] ${file.path} -> ${report.computedSolutionHash}');
            report = validator.validate(level);
          }
        }

        if (!report.passed) {
          throw FormatException(report.errors.join(', '));
        }

        stdout.writeln(
            '  ✓ [PASS] ${file.path} (${level.id}) - ${level.islands.length} islands, unique solution verified (hash: ${report.computedSolutionHash?.substring(0, 8)}...)');
      } catch (e) {
        stderr.writeln('  ✗ [FAIL] ${file.path}: $e');
        errors++;
      }
    }

    if (errors > 0) {
      stderr.writeln('\nValidation failed with $errors error(s).');
      exit(1);
    }

    stdout.writeln('\nAll levels validated successfully.');
  } else {
    stdout.writeln('Usage: nodalis validate-all [--dir=levels]');
  }
}
