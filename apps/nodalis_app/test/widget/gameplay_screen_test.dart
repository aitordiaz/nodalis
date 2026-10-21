import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodalis_app/content/level_repository.dart';
import 'package:nodalis_app/main.dart';
import 'package:nodalis_app/session/progress_repository.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';

void main() {
  group('Nodalis App End-to-End Progression Flow', () {
    late LevelRepository levelRepo;
    late ProgressRepository progressRepo;

    setUp(() {
      levelRepo = LevelRepository();
      levelRepo.loadLevels([
        LevelParser.parseJson(_testLevel1Json),
        LevelParser.parseJson(_testLevel2Json),
      ]);
      progressRepo = ProgressRepository.inMemory();
    });

    testWidgets('browses levels, plays level 1, solves it, and unlocks level 2',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));

      await tester.pumpWidget(NodalisApp(
        levelRepository: levelRepo,
        progressRepository: progressRepo,
      ));
      await tester.pumpAndSettle();

      // 1. Verify Level Select Screen
      expect(find.text('Chapter 1: First Connections'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Level 2 initially shows lock icon
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

      // 2. Tap Level 1 to enter Gameplay
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      expect(find.text('Chapter 1'), findsOneWidget);
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('Moves: 0'), findsOneWidget);

      // 3. Connect Island 1 to Island 2 to solve Level 1
      await tester.tap(
        find.bySemanticsLabel(RegExp(r'Island at row 3, column 2\.')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.bySemanticsLabel(RegExp(r'Island at row 3, column 4\.')),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Solved dialog appears
      expect(find.text('Level Solved'), findsOneWidget);
      expect(find.text('Next Level'), findsOneWidget);

      // Tap Next Level -> loads Level 2!
      await tester.tap(find.text('Next Level'));
      await tester.pumpAndSettle();

      expect(find.text('Level 2'), findsOneWidget);

      // Tap back button to return to Level Select
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Now on Level Select:
      // Level 1 shows completed checkmark
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      // Level 2 is unlocked (no lock icon!)
      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    });
  });
}

const _testLevel1Json = '''
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
    "hasInteractiveTutorial": false,
    "hintTriggers": []
  },
  "verification": {
    "solutionHash": "db23a7416c02f812e1e04052c751e8df09a72d84a101677eaae2b124729b7a20",
    "uniquenessVerified": true,
    "deductionDepth": 1
  }
}
''';

const _testLevel2Json = '''
{
  "\$schema": "../schemas/level.schema.json",
  "id": "ch01_02_triangle",
  "version": 1,
  "chapterId": 1,
  "indexInChapter": 2,
  "metadata": {
    "titleKey": "level_01_02_title",
    "author": "Aitor Diaz",
    "difficultyTier": "introductory",
    "estimatedSolveTimeSeconds": 40,
    "parMoves": 2,
    "mechanics": ["single_bridge"]
  },
  "grid": {
    "width": 5,
    "height": 5
  },
  "islands": [
    { "id": 1, "x": 1, "y": 1, "capacity": 1 },
    { "id": 2, "x": 3, "y": 1, "capacity": 2 },
    { "id": 3, "x": 3, "y": 3, "capacity": 1 }
  ],
  "tutorial": {
    "hasInteractiveTutorial": false,
    "hintTriggers": []
  },
  "verification": {
    "solutionHash": "2acf61e1231222e7723249593d2e6d83e1e3f2a5b95e8ec82eb2feeeea6e475a",
    "uniquenessVerified": true,
    "deductionDepth": 1
  }
}
''';
