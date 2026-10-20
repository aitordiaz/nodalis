import 'package:nodalis_level_format/nodalis_level_format.dart';
import 'package:test/test.dart';

void main() {
  group('LevelParser', () {
    const rawJson = '''
{
  "\$schema": "../schemas/level.schema.json",
  "id": "ch01_01_first_steps",
  "version": 1,
  "chapterId": 1,
  "indexInChapter": 1,
  "metadata": {
    "titleKey": "level_01_01_title",
    "author": "Aitor Diaz",
    "difficultyTier": "introductory",
    "estimatedSolveTimeSeconds": 30,
    "parMoves": 2,
    "mechanics": ["single_bridge"]
  },
  "grid": {
    "width": 5,
    "height": 5
  },
  "islands": [
    { "id": 1, "x": 1, "y": 2, "capacity": 1 },
    { "id": 2, "x": 3, "y": 2, "capacity": 1 }
  ],
  "tutorial": {
    "hasInteractiveTutorial": true,
    "hintTriggers": [
      {
        "triggerCondition": "on_start",
        "semanticTextKey": "tutorial_drag_to_connect",
        "highlightIslandIds": [1, 2]
      }
    ]
  },
  "verification": {
    "solutionHash": "d5e89a23f4b67e1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a",
    "uniquenessVerified": true,
    "deductionDepth": 1
  }
}
''';

    test('parses level JSON successfully into typed models', () {
      final level = LevelParser.parseJson(rawJson);

      expect(level.id, equals('ch01_01_first_steps'));
      expect(level.chapterId, equals(1));
      expect(level.indexInChapter, equals(1));
      expect(
          level.metadata.difficultyTier, equals(DifficultyTier.introductory));
      expect(level.gridWidth, equals(5));
      expect(level.gridHeight, equals(5));
      expect(level.islands.length, equals(2));
      expect(level.islands.first.requiredBridges, equals(1));
      expect(level.tutorial.hasInteractiveTutorial, isTrue);
      expect(level.verification?.uniquenessVerified, isTrue);

      final board = level.toInitialBoard();
      expect(board.width, equals(5));
      expect(board.islands.length, equals(2));
      expect(board.isSolved, isFalse);
    });

    test('roundtrips JSON serialization without data loss', () {
      final level = LevelParser.parseJson(rawJson);
      final serialized = LevelParser.toJson(level);
      final reparsed = LevelParser.parseJson(serialized);

      expect(reparsed.id, equals(level.id));
      expect(reparsed.gridWidth, equals(level.gridWidth));
      expect(reparsed.islands.length, equals(level.islands.length));
    });
  });
}
