import 'dart:io';
import 'package:args/args.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addCommand('validate-all')
    ..addOption('dir', abbr: 'd', defaultsTo: 'levels');

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
    var errors = 0;

    for (final file in levelFiles) {
      try {
        final content = file.readAsStringSync();
        final level = LevelParser.parseJson(content);

        // Sanity checks:
        if (level.islands.isEmpty) {
          throw FormatException('Level ${level.id} contains no islands');
        }

        // Check for duplicate island coordinates or IDs
        final seenCoords = <String>{};
        final seenIds = <int>{};

        for (final island in level.islands) {
          final coordKey = '${island.position.x},${island.position.y}';
          if (!seenCoords.add(coordKey)) {
            throw FormatException(
                'Duplicate island position ($coordKey) in level ${level.id}');
          }
          if (!seenIds.add(island.id)) {
            throw FormatException(
                'Duplicate island ID (${island.id}) in level ${level.id}');
          }
          if (island.position.x < 0 || island.position.x >= level.gridWidth) {
            throw FormatException(
                'Island ${island.id} X (${island.position.x}) out of bounds');
          }
          if (island.position.y < 0 || island.position.y >= level.gridHeight) {
            throw FormatException(
                'Island ${island.id} Y (${island.position.y}) out of bounds');
          }
        }

        stdout.writeln(
            '  ✓ [PASS] ${file.path} (${level.id}) - ${level.islands.length} islands');
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
