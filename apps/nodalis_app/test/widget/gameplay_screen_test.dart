import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    testWidgets(
        'undo and redo restore and advance board state in gameplay screen',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));

      // Unlock level 2
      progressRepo.recordCompletion('ch01_01_first_steps', 2);

      await tester.pumpWidget(NodalisApp(
        levelRepository: levelRepo,
        progressRepository: progressRepo,
      ));
      await tester.pumpAndSettle();

      // Enter Level 2 (where connecting 1-2 does not immediately solve the puzzle)
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      expect(find.text('Level 2'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Redo'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      final undoButtonFinder = find.ancestor(
        of: find.text('Undo'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );
      final redoButtonFinder = find.ancestor(
        of: find.text('Redo'),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      );

      expect(
          tester.widget<ButtonStyleButton>(undoButtonFinder).enabled, isFalse);
      expect(
          tester.widget<ButtonStyleButton>(redoButtonFinder).enabled, isFalse);

      // Connect islands 1 and 2 (row 2 col 2 to row 2 col 4)
      await tester.tap(
        find.bySemanticsLabel(RegExp(r'Island at row 2, column 2\.')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsLabel(RegExp(r'Island at row 2, column 4\.')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // Undo is enabled
      expect(
          tester.widget<ButtonStyleButton>(undoButtonFinder).enabled, isTrue);
      await tester.tap(undoButtonFinder);
      await tester.pumpAndSettle();

      // Redo is now enabled!
      expect(
          tester.widget<ButtonStyleButton>(redoButtonFinder).enabled, isTrue);
      await tester.tap(redoButtonFinder);
      await tester.pumpAndSettle();

      // Redo restored the connection, undo is enabled again
      expect(
          tester.widget<ButtonStyleButton>(undoButtonFinder).enabled, isTrue);
    });

    testWidgets(
        'tapping hint button opens deductive hint dialog with progressive stages',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));

      await tester.pumpWidget(NodalisApp(
        levelRepository: levelRepo,
        progressRepository: progressRepo,
      ));
      await tester.pumpAndSettle();

      // Enter Level 2
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      // Tap Hint button
      await tester.tap(find.byIcon(Icons.lightbulb_outline_rounded));
      await tester.pumpAndSettle();

      // Verify Deductive Hint Dialog opened
      expect(find.text('Logical Hint'), findsOneWidget);
      expect(find.text('NUDGE'), findsOneWidget);
      expect(find.text('Explain the Logic (Insight)'), findsOneWidget);

      // Tap Explain the Logic
      await tester.tap(find.text('Explain the Logic (Insight)'));
      await tester.pumpAndSettle();
      expect(find.text('INSIGHT'), findsOneWidget);
      expect(find.text('Show Exact Move'), findsOneWidget);

      // Tap Show Exact Move
      await tester.tap(find.text('Show Exact Move'));
      await tester.pumpAndSettle();
      expect(find.text('ACTION'), findsOneWidget);
      expect(find.text('Apply Step'), findsOneWidget);

      // Close hint
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Logical Hint'), findsNothing);
    });

    testWidgets(
        'theme toggle cycles between light, dark, OLED, and High Contrast',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));

      await tester.pumpWidget(NodalisApp(
        levelRepository: levelRepo,
        progressRepository: progressRepo,
      ));
      await tester.pumpAndSettle();

      // Initially Light mode
      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);

      // Tap theme button -> Dark mode
      await tester.tap(find.byIcon(Icons.light_mode_outlined));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

      // Tap theme button -> OLED battery saver mode
      await tester.tap(find.byIcon(Icons.dark_mode_outlined));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.battery_saver_rounded), findsOneWidget);

      // Tap theme button -> High Contrast mode
      await tester.tap(find.byIcon(Icons.battery_saver_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.contrast_rounded), findsOneWidget);

      // Tap theme button -> back to Light mode
      await tester.tap(find.byIcon(Icons.contrast_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    });

    testWidgets('settings dialog opens and updates accessibility switches',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));

      await tester.pumpWidget(NodalisApp(
        levelRepository: levelRepo,
        progressRepository: progressRepo,
      ));
      await tester.pumpAndSettle();

      // Tap settings button on top bar
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Haptic Feedback'), findsOneWidget);
      expect(find.text('Multi-Channel Status Shapes'), findsOneWidget);
      expect(find.text('Reduce Motion'), findsOneWidget);

      // Tap Reduce Motion switch
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(3));
      await tester.tap(switches.last);
      await tester.pumpAndSettle();

      expect(progressRepo.reduceMotion, isTrue);

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets(
        'keyboard shortcuts support island navigation and bridge building',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));

      await tester.pumpWidget(NodalisApp(
        levelRepository: levelRepo,
        progressRepository: progressRepo,
      ));
      await tester.pumpAndSettle();

      // Enter Level 1
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      // Navigate using ArrowRight key to select first island
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      // Construct bridge to the right using Shift + ArrowRight
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Level 1 has par 1 bridge between (1,2) and (3,2) -> connects and solves!
      expect(find.text('Level Solved'), findsOneWidget);
    });

    testWidgets(
        'daily and infinite tab displays procedural options and launches puzzle',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));

      await tester.pumpWidget(NodalisApp(
        levelRepository: levelRepo,
        progressRepository: progressRepo,
      ));
      await tester.pumpAndSettle();

      // Tap Daily & Infinite pill
      expect(find.text('Daily & Infinite'), findsOneWidget);
      await tester.tap(find.text('Daily & Infinite'));
      await tester.pumpAndSettle();

      // Verify Infinite play view is displayed
      expect(find.text('DAILY & INFINITE'), findsOneWidget);
      expect(find.text('DAILY CHALLENGE'), findsOneWidget);
      expect(find.text('PROCEDURAL PUZZLES'), findsOneWidget);
      expect(find.text('Gentle'), findsOneWidget);
      expect(find.text('Balanced'), findsOneWidget);
      expect(find.text('Master'), findsOneWidget);

      // Tap Play on Gentle card
      final playButtons = find.widgetWithText(FilledButton, 'Play');
      expect(playButtons, findsWidgets);
      await tester.tap(playButtons.first);
      await tester.pumpAndSettle();

      // Verify launched into procedural gameplay
      expect(find.text('Procedural Puzzle'), findsOneWidget);
      expect(find.text('EASY'), findsOneWidget);
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
