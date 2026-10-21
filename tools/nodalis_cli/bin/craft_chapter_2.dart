import 'dart:convert';
import 'dart:io';
import 'package:nodalis_domain/nodalis_domain.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';
import 'package:nodalis_solver/nodalis_solver.dart';

void main() {
  const solver = BacktrackingSolver();

  LevelDefinition makeLevel({
    required String id,
    required int index,
    required String titleKey,
    required DifficultyTier difficulty,
    required int solveTime,
    required int parMoves,
    required int gridW,
    required int gridH,
    required List<String> mechanics,
    required List<(int, int, int, int)> islands,
  }) {
    return LevelDefinition(
      id: id,
      version: 1,
      chapterId: 2,
      indexInChapter: index,
      metadata: LevelMetadata(
        titleKey: titleKey,
        author: 'Aitor Diaz',
        difficultyTier: difficulty,
        estimatedSolveTimeSeconds: solveTime,
        parMoves: parMoves,
        mechanics: mechanics,
      ),
      gridWidth: gridW,
      gridHeight: gridH,
      islands: islands
          .map((i) => Island(
                id: i.$1,
                position: (x: i.$2, y: i.$3),
                requiredBridges: i.$4,
              ))
          .toList(),
      tutorial: const LevelTutorial(
        hasInteractiveTutorial: false,
        hintTriggers: [],
      ),
    );
  }

  final levels = <LevelDefinition>[
    // Level 11 (Ch 2, Level 1): Twin Crossings
    makeLevel(
      id: 'ch02_01_twin_crossings',
      index: 1,
      titleKey: 'level_02_01_title',
      difficulty: DifficultyTier.easy,
      solveTime: 60,
      parMoves: 6,
      gridW: 6,
      gridH: 6,
      mechanics: ['parallel_paths', 'double_bridge'],
      islands: [
        (1, 1, 1, 1),
        (2, 4, 1, 1),
        (3, 1, 3, 2),
        (4, 4, 3, 2),
        (5, 1, 5, 2),
        (6, 4, 5, 2)
      ],
    ),

    // Level 12 (Ch 2, Level 2): Ladder Logic
    makeLevel(
      id: 'ch02_02_ladder_logic',
      index: 2,
      titleKey: 'level_02_02_title',
      difficulty: DifficultyTier.easy,
      solveTime: 75,
      parMoves: 7,
      gridW: 6,
      gridH: 6,
      mechanics: ['parallel_paths', 'pigeonhole'],
      islands: [
        (1, 1, 1, 2),
        (2, 4, 1, 2),
        (3, 1, 3, 2),
        (4, 4, 3, 2),
        (5, 1, 5, 2),
        (6, 4, 5, 2),
        (7, 2, 5, 2)
      ],
    ),

    // Level 13 (Ch 2, Level 3): Ring Road
    makeLevel(
      id: 'ch02_03_ring_road',
      index: 3,
      titleKey: 'level_02_03_title',
      difficulty: DifficultyTier.easy,
      solveTime: 90,
      parMoves: 7,
      gridW: 6,
      gridH: 6,
      mechanics: ['loop_avoidance', 'saturation'],
      islands: [
        (1, 1, 1, 3),
        (2, 4, 1, 2),
        (3, 1, 4, 3),
        (4, 4, 4, 3),
        (5, 2, 2, 2),
        (6, 2, 4, 5)
      ],
    ),

    // Level 14 (Ch 2, Level 4): The Hourglass
    makeLevel(
      id: 'ch02_04_the_hourglass',
      index: 4,
      titleKey: 'level_02_04_title',
      difficulty: DifficultyTier.medium,
      solveTime: 100,
      parMoves: 8,
      gridW: 7,
      gridH: 7,
      mechanics: ['pinch_point', 'double_bridge'],
      islands: [
        (1, 1, 1, 2),
        (2, 5, 1, 1),
        (3, 3, 1, 5),
        (4, 3, 3, 4),
        (5, 3, 5, 5),
        (6, 1, 5, 1),
        (7, 5, 5, 2)
      ],
    ),

    // Level 15 (Ch 2, Level 5): Checkerboard
    makeLevel(
      id: 'ch02_05_checkerboard',
      index: 5,
      titleKey: 'level_02_05_title',
      difficulty: DifficultyTier.medium,
      solveTime: 120,
      parMoves: 9,
      gridW: 7,
      gridH: 7,
      mechanics: ['parallel_paths', 'saturation'],
      islands: [
        (1, 1, 1, 3),
        (2, 3, 1, 3),
        (3, 5, 1, 2),
        (4, 1, 3, 3),
        (5, 5, 3, 3),
        (6, 1, 5, 2),
        (7, 3, 5, 4),
        (8, 5, 5, 2)
      ],
    ),

    // Level 16 (Ch 2, Level 6): Serpentine
    makeLevel(
      id: 'ch02_06_serpentine',
      index: 6,
      titleKey: 'level_02_06_title',
      difficulty: DifficultyTier.medium,
      solveTime: 130,
      parMoves: 9,
      gridW: 7,
      gridH: 7,
      mechanics: ['multi_step_deduction', 'double_bridge'],
      islands: [
        (1, 1, 1, 1),
        (2, 4, 1, 2),
        (3, 4, 3, 5),
        (4, 2, 3, 4),
        (5, 2, 5, 3),
        (6, 5, 5, 3),
        (7, 5, 3, 4)
      ],
    ),

    // Level 17 (Ch 2, Level 7): Diamond Lattice
    makeLevel(
      id: 'ch02_07_diamond_lattice',
      index: 7,
      titleKey: 'level_02_07_title',
      difficulty: DifficultyTier.medium,
      solveTime: 140,
      parMoves: 9,
      gridW: 7,
      gridH: 7,
      mechanics: ['pigeonhole', 'symmetry'],
      islands: [
        (1, 3, 1, 1),
        (2, 1, 3, 3),
        (3, 3, 3, 5),
        (4, 5, 3, 2),
        (5, 3, 5, 6),
        (6, 1, 5, 4),
        (7, 5, 5, 3)
      ],
    ),

    // Level 18 (Ch 2, Level 8): Narrow Strait
    makeLevel(
      id: 'ch02_08_narrow_strait',
      index: 8,
      titleKey: 'level_02_08_title',
      difficulty: DifficultyTier.hard,
      solveTime: 160,
      parMoves: 10,
      gridW: 8,
      gridH: 6,
      mechanics: ['choke_point', 'isolation_avoidance'],
      islands: [
        (1, 1, 1, 3),
        (2, 3, 1, 6),
        (3, 6, 1, 4),
        (4, 1, 4, 3),
        (5, 3, 4, 5),
        (6, 6, 4, 4),
        (7, 4, 1, 6),
        (8, 4, 4, 5)
      ],
    ),

    // Level 19 (Ch 2, Level 9): The Fortress
    makeLevel(
      id: 'ch02_09_the_fortress',
      index: 9,
      titleKey: 'level_02_09_title',
      difficulty: DifficultyTier.hard,
      solveTime: 180,
      parMoves: 11,
      gridW: 8,
      gridH: 8,
      mechanics: ['corner_lock', 'multi_step_deduction'],
      islands: [
        (1, 1, 1, 3),
        (2, 6, 1, 2),
        (3, 1, 4, 4),
        (4, 4, 4, 5),
        (5, 6, 4, 4),
        (6, 1, 6, 3),
        (7, 4, 6, 6),
        (8, 6, 6, 3)
      ],
    ),

    // Level 20 (Ch 2, Level 10): Parallel Ascension (Finale)
    makeLevel(
      id: 'ch02_10_parallel_ascension',
      index: 10,
      titleKey: 'level_02_10_title',
      difficulty: DifficultyTier.hard,
      solveTime: 200,
      parMoves: 14,
      gridW: 8,
      gridH: 8,
      mechanics: ['parallel_paths', 'grand_finale', 'double_bridge'],
      islands: [
        (1, 1, 1, 3),
        (2, 3, 1, 6),
        (3, 6, 1, 4),
        (4, 1, 4, 5),
        (5, 3, 4, 8),
        (6, 6, 4, 5),
        (7, 1, 6, 4),
        (8, 3, 6, 6),
        (9, 6, 6, 3)
      ],
    ),
  ];

  print('Verifying all 10 Chapter 2 levels...');
  Directory('levels/chapter_02').createSync(recursive: true);
  Directory('apps/nodalis_app/assets/levels').createSync(recursive: true);

  const encoder = JsonEncoder.withIndent('  ');
  for (final level in levels) {
    final res = solver.solve(level.toInitialBoard(), maxSolutions: 2);
    if (!res.isUnique) {
      throw StateError(
          'Level ${level.id} is not unique! Found ${res.solutions.length} solutions');
    }
    final hash = BacktrackingSolver.calculateSolutionHash(res.solutions.first);
    print(
        '  ✓ Level ${level.indexInChapter} (${level.id}): UNIQUE (hash: ${hash.substring(0, 8)}...)');

    final jsonMap = {
      r'$schema': '../schemas/level.schema.json',
      'id': level.id,
      'version': level.version,
      'chapterId': level.chapterId,
      'indexInChapter': level.indexInChapter,
      'metadata': {
        'titleKey': level.metadata.titleKey,
        'author': level.metadata.author,
        'difficultyTier': level.metadata.difficultyTier.name,
        'estimatedSolveTimeSeconds': level.metadata.estimatedSolveTimeSeconds,
        'parMoves': level.metadata.parMoves,
        'mechanics': level.metadata.mechanics,
      },
      'grid': {
        'width': level.gridWidth,
        'height': level.gridHeight,
      },
      'islands': level.islands
          .map((isl) => {
                'id': isl.id,
                'x': isl.position.x,
                'y': isl.position.y,
                'capacity': isl.requiredBridges,
              })
          .toList(),
      'tutorial': {
        'hasInteractiveTutorial': false,
        'hintTriggers': <Map<String, dynamic>>[],
      },
      'verification': {
        'solutionHash': hash,
        'uniquenessVerified': true,
        'deductionDepth': 2,
      },
    };

    final formattedJson = encoder.convert(jsonMap);
    final numStr = '${level.indexInChapter + 10}';
    final nameSuffix = level.id.replaceFirst(
        'ch02_${level.indexInChapter < 10 ? '0' : ''}${level.indexInChapter}_',
        '');
    final fileName = '${numStr}_$nameSuffix.json';

    File('levels/chapter_02/$fileName').writeAsStringSync(formattedJson);
    File('apps/nodalis_app/assets/levels/$fileName')
        .writeAsStringSync(formattedJson);
    print('    -> Saved $fileName');
  }

  print('\nAll 10 Chapter 2 levels generated and saved successfully.');
}
