import 'dart:convert';
import 'package:nodalis_domain/nodalis_domain.dart';
import '../models/level_definition.dart';

/// Schema parser and serializer for Nodalis level JSON documents.
final class LevelParser {
  /// Parses a raw JSON string into a strongly-typed [LevelDefinition].
  static LevelDefinition parseJson(String jsonString) {
    final Map<String, dynamic> json =
        jsonDecode(jsonString) as Map<String, dynamic>;
    return fromMap(json);
  }

  /// Parses a decoded Map into a [LevelDefinition].
  static LevelDefinition fromMap(Map<String, dynamic> json) {
    final metadataMap = json['metadata'] as Map<String, dynamic>? ?? {};
    final gridMap = json['grid'] as Map<String, dynamic>? ?? {};
    final islandsList = json['islands'] as List<dynamic>? ?? [];
    final tutorialMap = json['tutorial'] as Map<String, dynamic>? ?? {};
    final verificationMap = json['verification'] as Map<String, dynamic>?;

    final metadata = LevelMetadata(
      titleKey: metadataMap['titleKey'] as String? ?? '',
      author: metadataMap['author'] as String? ?? 'Unknown',
      difficultyTier: DifficultyTier.fromString(
        metadataMap['difficultyTier'] as String? ?? 'medium',
      ),
      estimatedSolveTimeSeconds:
          metadataMap['estimatedSolveTimeSeconds'] as int? ?? 60,
      parMoves: metadataMap['parMoves'] as int? ?? 10,
      mechanics: (metadataMap['mechanics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );

    final islands = islandsList.map((item) {
      final map = item as Map<String, dynamic>;
      return Island(
        id: map['id'] as int,
        position: (x: map['x'] as int, y: map['y'] as int),
        requiredBridges: map['capacity'] as int,
      );
    }).toList();

    final hintTriggersList =
        tutorialMap['hintTriggers'] as List<dynamic>? ?? [];
    final hintTriggers = hintTriggersList.map((item) {
      final map = item as Map<String, dynamic>;
      return HintTrigger(
        triggerCondition: map['triggerCondition'] as String? ?? '',
        semanticTextKey: map['semanticTextKey'] as String? ?? '',
        highlightIslandIds: (map['highlightIslandIds'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            const [],
      );
    }).toList();

    final tutorial = LevelTutorial(
      hasInteractiveTutorial:
          tutorialMap['hasInteractiveTutorial'] as bool? ?? false,
      hintTriggers: hintTriggers,
    );

    LevelVerification? verification;
    if (verificationMap != null) {
      verification = LevelVerification(
        solutionHash: verificationMap['solutionHash'] as String? ?? '',
        uniquenessVerified:
            verificationMap['uniquenessVerified'] as bool? ?? false,
        deductionDepth: verificationMap['deductionDepth'] as int? ?? 1,
      );
    }

    return LevelDefinition(
      id: json['id'] as String,
      version: json['version'] as int? ?? 1,
      chapterId: json['chapterId'] as int? ?? 1,
      indexInChapter: json['indexInChapter'] as int? ?? 1,
      metadata: metadata,
      gridWidth: gridMap['width'] as int? ?? 5,
      gridHeight: gridMap['height'] as int? ?? 5,
      islands: islands,
      tutorial: tutorial,
      verification: verification,
    );
  }

  /// Serializes a [LevelDefinition] into a canonical formatted JSON string.
  static String toJson(LevelDefinition level) {
    final map = {
      r'$schema': '../schemas/level.schema.json',
      'id': level.id,
      'version': level.version,
      'chapterId': level.chapterId,
      'indexInChapter': level.indexInChapter,
      'metadata': {
        'titleKey': level.metadata.titleKey,
        'author': level.metadata.author,
        'difficultyTier': level.metadata.difficultyTier.value,
        'estimatedSolveTimeSeconds': level.metadata.estimatedSolveTimeSeconds,
        'parMoves': level.metadata.parMoves,
        'mechanics': level.metadata.mechanics,
      },
      'grid': {
        'width': level.gridWidth,
        'height': level.gridHeight,
      },
      'islands': level.islands
          .map((i) => {
                'id': i.id,
                'x': i.position.x,
                'y': i.position.y,
                'capacity': i.requiredBridges,
              })
          .toList(),
      'tutorial': {
        'hasInteractiveTutorial': level.tutorial.hasInteractiveTutorial,
        'hintTriggers': level.tutorial.hintTriggers
            .map((h) => {
                  'triggerCondition': h.triggerCondition,
                  'semanticTextKey': h.semanticTextKey,
                  'highlightIslandIds': h.highlightIslandIds,
                })
            .toList(),
      },
      if (level.verification != null)
        'verification': {
          'solutionHash': level.verification!.solutionHash,
          'uniquenessVerified': level.verification!.uniquenessVerified,
          'deductionDepth': level.verification!.deductionDepth,
        },
    };

    return const JsonEncoder.withIndent('  ').convert(map);
  }
}
