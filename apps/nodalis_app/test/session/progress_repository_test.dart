import 'package:flutter_test/flutter_test.dart';
import 'package:nodalis_app/content/level_repository.dart';
import 'package:nodalis_app/session/progress_persistence.dart';
import 'package:nodalis_app/session/progress_repository.dart';
import 'package:nodalis_domain/nodalis_domain.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';
import 'package:nodalis_ui/nodalis_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ProgressRepository & Persistence', () {
    late LevelDefinition level1;
    late LevelDefinition level2;
    late LevelDefinition level3;

    setUp(() {
      level1 = const LevelDefinition(
        id: 'ch01_01',
        version: 1,
        chapterId: 1,
        indexInChapter: 1,
        metadata: LevelMetadata(
          titleKey: 'l1',
          author: 'Aitor',
          difficultyTier: DifficultyTier.introductory,
          estimatedSolveTimeSeconds: 30,
          parMoves: 2,
          mechanics: ['single_bridge'],
        ),
        gridWidth: 5,
        gridHeight: 5,
        islands: [
          Island(id: 1, position: (x: 1, y: 1), requiredBridges: 1),
          Island(id: 2, position: (x: 3, y: 1), requiredBridges: 1),
        ],
        tutorial: LevelTutorial(
          hasInteractiveTutorial: false,
          hintTriggers: [],
        ),
      );

      level2 = const LevelDefinition(
        id: 'ch01_02',
        version: 1,
        chapterId: 1,
        indexInChapter: 2,
        metadata: LevelMetadata(
          titleKey: 'l2',
          author: 'Aitor',
          difficultyTier: DifficultyTier.introductory,
          estimatedSolveTimeSeconds: 40,
          parMoves: 2,
          mechanics: ['single_bridge'],
        ),
        gridWidth: 5,
        gridHeight: 5,
        islands: [
          Island(id: 1, position: (x: 1, y: 1), requiredBridges: 1),
          Island(id: 2, position: (x: 3, y: 1), requiredBridges: 2),
          Island(id: 3, position: (x: 3, y: 3), requiredBridges: 1),
        ],
        tutorial: LevelTutorial(
          hasInteractiveTutorial: false,
          hintTriggers: [],
        ),
      );

      level3 = const LevelDefinition(
        id: 'ch01_03',
        version: 1,
        chapterId: 1,
        indexInChapter: 3,
        metadata: LevelMetadata(
          titleKey: 'l3',
          author: 'Aitor',
          difficultyTier: DifficultyTier.easy,
          estimatedSolveTimeSeconds: 60,
          parMoves: 4,
          mechanics: ['single_bridge'],
        ),
        gridWidth: 5,
        gridHeight: 5,
        islands: [
          Island(id: 1, position: (x: 0, y: 0), requiredBridges: 2),
          Island(id: 2, position: (x: 2, y: 0), requiredBridges: 2),
        ],
        tutorial: LevelTutorial(
          hasInteractiveTutorial: false,
          hintTriggers: [],
        ),
      );
    });

    test('fresh repository unlocks first level and has no completions', () {
      final repo = ProgressRepository.inMemory();
      final chapterLevels = [level1, level2, level3];

      expect(repo.isLevelUnlocked(level1, chapterLevels), isTrue);
      expect(repo.isLevelUnlocked(level2, chapterLevels), isFalse);
      expect(repo.isLevelUnlocked(level3, chapterLevels), isFalse);
      expect(repo.getNextRecommendedLevel(chapterLevels), equals(level1));
    });

    test('recording completion persists data and unlocks subsequent level',
        () async {
      final persistence = InMemoryProgressPersistence();
      final repo = ProgressRepository(persistence: persistence);
      final chapterLevels = [level1, level2, level3];

      await repo.recordCompletion('ch01_01', 3);

      expect(repo.isLevelCompleted('ch01_01'), isTrue);
      expect(repo.getBestMoves('ch01_01'), equals(3));
      expect(repo.lastCompletedLevelId, equals('ch01_01'));
      expect(repo.lastPlayedLevelId, equals('ch01_01'));
      expect(repo.isLevelUnlocked(level2, chapterLevels), isTrue);
      expect(repo.getNextRecommendedLevel(chapterLevels), equals(level2));

      // Simulate app restart by loading new repository from same persistence
      final restoredRepo = ProgressRepository(persistence: persistence);
      await restoredRepo.load();

      expect(restoredRepo.isLevelCompleted('ch01_01'), isTrue);
      expect(restoredRepo.getBestMoves('ch01_01'), equals(3));
      expect(restoredRepo.lastCompletedLevelId, equals('ch01_01'));
      expect(restoredRepo.lastPlayedLevelId, equals('ch01_01'));
      expect(restoredRepo.isLevelUnlocked(level2, chapterLevels), isTrue);
      expect(
          restoredRepo.getNextRecommendedLevel(chapterLevels), equals(level2));
    });

    test(
        'SharedPreferencesProgressPersistence roundtrips with SharedPreferences',
        () async {
      SharedPreferences.setMockInitialValues({});
      final persistence = SharedPreferencesProgressPersistence();

      await persistence.saveProgress(
        completedLevelIds: {'ch01_01', 'ch01_02'},
        bestMoves: {'ch01_01': 2, 'ch01_02': 4},
        lastCompletedLevelId: 'ch01_02',
        lastPlayedLevelId: 'ch01_02',
      );
      await persistence.saveThemeMode(NodalisThemeMode.oled);

      final loaded = await persistence.loadProgress();
      expect(loaded.completedLevelIds, containsAll(['ch01_01', 'ch01_02']));
      expect(loaded.bestMoves['ch01_01'], equals(2));
      expect(loaded.bestMoves['ch01_02'], equals(4));
      expect(loaded.lastCompletedLevelId, equals('ch01_02'));
      expect(loaded.lastPlayedLevelId, equals('ch01_02'));
      expect(loaded.isDarkMode, isTrue);
      expect(loaded.themeMode, equals('oled'));

      final repo = ProgressRepository(persistence: persistence);
      final mode = await repo.loadThemeMode();
      expect(mode, equals(NodalisThemeMode.oled));
    });

    test('resetProgress clears both memory and persistence', () async {
      final persistence = InMemoryProgressPersistence();
      final repo = ProgressRepository(persistence: persistence);

      await repo.recordCompletion('ch01_01', 2);
      expect(repo.isLevelCompleted('ch01_01'), isTrue);

      await repo.resetProgress();
      expect(repo.completedLevelIds, isEmpty);
      expect(repo.bestMoves, isEmpty);
      expect(repo.lastCompletedLevelId, isNull);

      final restored = ProgressRepository(persistence: persistence);
      await restored.load();
      expect(restored.completedLevelIds, isEmpty);
    });

    test('settings and accessibility options update and persist', () async {
      final persistence = InMemoryProgressPersistence();
      final repo = ProgressRepository(persistence: persistence);

      expect(repo.hapticsEnabled, isTrue);
      expect(repo.reduceMotion, isFalse);
      expect(repo.accessibilityShapes, isTrue);

      repo.updateSettings(
        hapticsEnabled: false,
        reduceMotion: true,
        accessibilityShapes: false,
      );

      expect(repo.hapticsEnabled, isFalse);
      expect(repo.reduceMotion, isTrue);
      expect(repo.accessibilityShapes, isFalse);

      final restored = ProgressRepository(persistence: persistence);
      await restored.load();
      expect(restored.hapticsEnabled, isFalse);
      expect(restored.reduceMotion, isTrue);
      expect(restored.accessibilityShapes, isFalse);
    });

    test(
        'getResumeLevel resolves active or recommended next level across chapters',
        () async {
      final levelRepo = LevelRepository();
      levelRepo.loadLevels([level1, level2, level3]);
      final repo = ProgressRepository.inMemory();

      // Brand new user -> starts at level 1
      expect(repo.getResumeLevel(levelRepo)?.id, equals('ch01_01'));

      // Started level 1 but not finished -> resumes level 1
      await repo.setLastPlayed('ch01_01');
      expect(repo.getResumeLevel(levelRepo)?.id, equals('ch01_01'));

      // Solved level 1 -> resumes level 2
      await repo.recordCompletion('ch01_01', 2);
      expect(repo.getResumeLevel(levelRepo)?.id, equals('ch01_02'));

      // Started level 2 -> resumes level 2
      await repo.setLastPlayed('ch01_02');
      expect(repo.getResumeLevel(levelRepo)?.id, equals('ch01_02'));

      // Solved level 2 -> resumes level 3
      await repo.recordCompletion('ch01_02', 3);
      expect(repo.getResumeLevel(levelRepo)?.id, equals('ch01_03'));
    });

    test('saveActiveBoard persists bridges and restores across cold restart',
        () async {
      SharedPreferences.setMockInitialValues({});
      final persistence = SharedPreferencesProgressPersistence();
      final repo = ProgressRepository(persistence: persistence);

      final bridge = Bridge(
        islandAId: 1,
        islandBId: 2,
        count: BridgeCount.single,
      );

      await repo.saveActiveBoard('ch01_01', [bridge], 1);

      expect(repo.getActiveBoard('ch01_01')?.bridges.length, equals(1));
      expect(repo.getActiveBoard('ch01_01')?.moveCount, equals(1));
      expect(repo.lastPlayedLevelId, equals('ch01_01'));

      // Cold restart
      final reloadedRepo = ProgressRepository(persistence: persistence);
      await reloadedRepo.load();

      expect(reloadedRepo.getActiveBoard('ch01_01')?.bridges.length, equals(1));
      expect(reloadedRepo.getActiveBoard('ch01_01')?.bridges.first.count,
          equals(BridgeCount.single));
      expect(reloadedRepo.getActiveBoard('ch01_01')?.moveCount, equals(1));
      expect(reloadedRepo.lastPlayedLevelId, equals('ch01_01'));

      // Completing the level cleans up active board state
      await reloadedRepo.recordCompletion('ch01_01', 2);
      expect(reloadedRepo.getActiveBoard('ch01_01'), isNull);
      expect(reloadedRepo.isLevelCompleted('ch01_01'), isTrue);
    });
  });
}
