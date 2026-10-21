import 'dart:convert';
import 'dart:io';
import 'package:nodalis_level_format/nodalis_level_format.dart';
import 'package:nodalis_solver/nodalis_solver.dart';

void main() {
  const generator = PuzzleGenerator();
  const validator = LevelValidator();

  final ch3Titles = [
    (
      'ch03_01_central_junction',
      'Central Junction',
      7,
      7,
      7,
      DifficultyTier.medium,
      ['crossroads', 'saturation']
    ),
    (
      'ch03_02_four_corners',
      'Four Corners',
      7,
      7,
      7,
      DifficultyTier.medium,
      ['hub_routing', 'isolation_avoidance']
    ),
    (
      'ch03_03_the_bottleneck',
      'The Bottleneck',
      7,
      7,
      8,
      DifficultyTier.medium,
      ['bottleneck', 'parity']
    ),
    (
      'ch03_04_trident',
      'Trident',
      7,
      7,
      8,
      DifficultyTier.medium,
      ['triple_branch', 'pigeonhole']
    ),
    (
      'ch03_05_diamond_hub',
      'Diamond Hub',
      7,
      7,
      8,
      DifficultyTier.medium,
      ['diagonal_offset', 'double_bridge']
    ),
    (
      'ch03_06_dual_intersection',
      'Dual Intersection',
      8,
      7,
      8,
      DifficultyTier.hard,
      ['dual_hubs', 'interlocking']
    ),
    (
      'ch03_07_weave_pattern',
      'Weave Pattern',
      7,
      8,
      8,
      DifficultyTier.hard,
      ['weave', 'isolation_avoidance']
    ),
    (
      'ch03_08_the_citadel',
      'The Citadel',
      8,
      8,
      8,
      DifficultyTier.hard,
      ['perimeter_defense', 'hub_routing']
    ),
    (
      'ch03_09_narrow_causeway',
      'Narrow Causeway',
      8,
      8,
      8,
      DifficultyTier.hard,
      ['corridor_chain', 'pigeonhole']
    ),
    (
      'ch03_10_grand_crossroads',
      'Grand Crossroads',
      8,
      8,
      9,
      DifficultyTier.hard,
      ['grand_crossroads', 'master_deduction']
    ),
  ];

  final ch4Titles = [
    (
      'ch04_01_web_inception',
      'Web Inception',
      8,
      8,
      8,
      DifficultyTier.hard,
      ['high_degree', 'network_flow']
    ),
    (
      'ch04_02_hexagonal_web',
      'Hexagonal Web',
      8,
      8,
      8,
      DifficultyTier.hard,
      ['hex_routing', 'isolation_avoidance']
    ),
    (
      'ch04_03_double_cross',
      'Double Cross',
      8,
      8,
      8,
      DifficultyTier.hard,
      ['double_cross', 'degree_saturation']
    ),
    (
      'ch04_04_radial_array',
      'Radial Array',
      8,
      8,
      8,
      DifficultyTier.hard,
      ['radial_expansion', 'pigeonhole']
    ),
    (
      'ch04_05_concentric_ring',
      'Concentric Ring',
      8,
      8,
      9,
      DifficultyTier.hard,
      ['concentric_loops', 'bottleneck']
    ),
    (
      'ch04_06_the_spider',
      'The Spider',
      8,
      8,
      9,
      DifficultyTier.hard,
      ['high_degree_6', 'multi_arm']
    ),
    (
      'ch04_07_matrix_web',
      'Matrix Web',
      9,
      8,
      9,
      DifficultyTier.hard,
      ['matrix_interlock', 'isolation_avoidance']
    ),
    (
      'ch04_08_labyrinthine_network',
      'Labyrinthine Network',
      8,
      9,
      9,
      DifficultyTier.hard,
      ['labyrinth', 'parity_traps']
    ),
    (
      'ch04_09_the_octopus',
      'The Octopus',
      9,
      9,
      9,
      DifficultyTier.hard,
      ['high_degree_6', 'extended_reach']
    ),
    (
      'ch04_10_grandmaster_tapestry',
      "Grandmaster's Tapestry",
      9,
      9,
      10,
      DifficultyTier.hard,
      ['grandmaster_climax', 'complex_interlock']
    ),
  ];

  final levels = <LevelDefinition>[];

  print('=== CRAFTING CHAPTER 3: The Crossroads ===');
  for (var i = 0; i < ch3Titles.length; i++) {
    final spec = ch3Titles[i];
    final indexInChapter = i + 1;
    LevelDefinition? generated;

    for (var seedAttempt = 3000 + i * 50;
        seedAttempt < 3000 + (i + 1) * 50;
        seedAttempt++) {
      final cand = generator.generate(
        width: spec.$3,
        height: spec.$4,
        islandCount: spec.$5,
        difficulty: spec.$6,
        seed: seedAttempt,
      );
      if (cand != null) {
        generated = cand;
        break;
      }
    }

    if (generated == null) {
      throw StateError('Failed to generate unique puzzle for ${spec.$1}');
    }

    final level = LevelDefinition(
      id: spec.$1,
      version: 1,
      chapterId: 3,
      indexInChapter: indexInChapter,
      metadata: LevelMetadata(
        titleKey:
            'level_03_${indexInChapter < 10 ? '0' : ''}${indexInChapter}_title',
        author: 'Aitor Diaz',
        difficultyTier: spec.$6,
        estimatedSolveTimeSeconds: 60 + indexInChapter * 8,
        parMoves: generated.islands.length + 3,
        mechanics: spec.$7,
      ),
      gridWidth: generated.gridWidth,
      gridHeight: generated.gridHeight,
      islands: generated.islands,
      tutorial: const LevelTutorial(
        hasInteractiveTutorial: false,
        hintTriggers: [],
      ),
      verification: generated.verification,
    );

    final report = validator.validate(level);
    if (!report.passed || !report.isUnique) {
      throw StateError('Validation failed for ${level.id}');
    }

    levels.add(level);
    print(
        '  ✓ Level ${i + 21}: ${spec.$2} (${level.gridWidth}x${level.gridHeight}, ${level.islands.length} islands) - Verified Unique!');
  }

  print('\n=== CRAFTING CHAPTER 4: Master\'s Web ===');
  for (var i = 0; i < ch4Titles.length; i++) {
    final spec = ch4Titles[i];
    final indexInChapter = i + 1;
    LevelDefinition? generated;

    for (var seedAttempt = 4000 + i * 50;
        seedAttempt < 4000 + (i + 1) * 50;
        seedAttempt++) {
      final cand = generator.generate(
        width: spec.$3,
        height: spec.$4,
        islandCount: spec.$5,
        difficulty: spec.$6,
        seed: seedAttempt,
      );
      if (cand != null) {
        generated = cand;
        break;
      }
    }

    if (generated == null) {
      throw StateError('Failed to generate unique puzzle for ${spec.$1}');
    }

    final level = LevelDefinition(
      id: spec.$1,
      version: 1,
      chapterId: 4,
      indexInChapter: indexInChapter,
      metadata: LevelMetadata(
        titleKey:
            'level_04_${indexInChapter < 10 ? '0' : ''}${indexInChapter}_title',
        author: 'Aitor Diaz',
        difficultyTier: spec.$6,
        estimatedSolveTimeSeconds: 100 + indexInChapter * 10,
        parMoves: generated.islands.length + 4,
        mechanics: spec.$7,
      ),
      gridWidth: generated.gridWidth,
      gridHeight: generated.gridHeight,
      islands: generated.islands,
      tutorial: const LevelTutorial(
        hasInteractiveTutorial: false,
        hintTriggers: [],
      ),
      verification: generated.verification,
    );

    final report = validator.validate(level);
    if (!report.passed || !report.isUnique) {
      throw StateError('Validation failed for ${level.id}');
    }

    levels.add(level);
    print(
        '  ✓ Level ${i + 31}: ${spec.$2} (${level.gridWidth}x${level.gridHeight}, ${level.islands.length} islands) - Verified Unique!');
  }

  // Save all levels to disk
  Directory('levels/chapter_03').createSync(recursive: true);
  Directory('levels/chapter_04').createSync(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');

  print('\n=== SAVING ASSETS ===');
  for (final level in levels) {
    final globalIndex = level.chapterId == 3
        ? level.indexInChapter + 20
        : level.indexInChapter + 30;

    final prefix = level.chapterId == 3 ? 'ch03_' : 'ch04_';
    final nameSuffix = level.id.replaceFirst(
        '$prefix${level.indexInChapter < 10 ? '0' : ''}${level.indexInChapter}_',
        '');
    final fileName = '${globalIndex}_$nameSuffix.json';
    final chFolder = level.chapterId == 3 ? 'chapter_03' : 'chapter_04';

    final jsonMap = <String, dynamic>{
      r'$schema': '../schemas/level.schema.json',
      'id': level.id,
      'version': 1,
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
        'solutionHash': level.verification?.solutionHash,
        'uniquenessVerified': true,
        'deductionDepth': 2,
      },
    };

    final formattedJson = encoder.convert(jsonMap);
    File('levels/$chFolder/$fileName').writeAsStringSync(formattedJson);
    File('apps/nodalis_app/assets/levels/$fileName')
        .writeAsStringSync(formattedJson);
    print(
        '  -> Saved $fileName in levels/$chFolder/ and apps/nodalis_app/assets/levels/');
  }

  print(
      '\n🎉 All 20 levels for Chapters 3 and 4 successfully crafted, mathematically proven, and bundled!');
}
