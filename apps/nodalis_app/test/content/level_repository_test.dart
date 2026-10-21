import 'package:flutter_test/flutter_test.dart';
import 'package:nodalis_app/content/level_repository.dart';
import 'package:nodalis_domain/nodalis_domain.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';

void main() {
  group('LevelRepository', () {
    late LevelRepository repo;
    late LevelDefinition ch1L1;
    late LevelDefinition ch1L2;
    late LevelDefinition ch1L10;
    late LevelDefinition ch2L1;

    setUp(() {
      repo = LevelRepository();
      ch1L1 = const LevelDefinition(
        id: 'ch01_01',
        version: 1,
        chapterId: 1,
        indexInChapter: 1,
        gridWidth: 5,
        gridHeight: 5,
        metadata: LevelMetadata(
          titleKey: 'l1',
          author: 'Test',
          difficultyTier: DifficultyTier.introductory,
          estimatedSolveTimeSeconds: 30,
          parMoves: 2,
          mechanics: ['single_bridge'],
        ),
        islands: [
          Island(id: 1, position: (x: 1, y: 1), requiredBridges: 1),
          Island(id: 2, position: (x: 3, y: 1), requiredBridges: 1),
        ],
        tutorial:
            LevelTutorial(hasInteractiveTutorial: false, hintTriggers: []),
      );
      ch1L2 = const LevelDefinition(
        id: 'ch01_02',
        version: 1,
        chapterId: 1,
        indexInChapter: 2,
        gridWidth: 5,
        gridHeight: 5,
        metadata: LevelMetadata(
          titleKey: 'l2',
          author: 'Test',
          difficultyTier: DifficultyTier.introductory,
          estimatedSolveTimeSeconds: 35,
          parMoves: 2,
          mechanics: ['single_bridge'],
        ),
        islands: [
          Island(id: 1, position: (x: 1, y: 1), requiredBridges: 1),
          Island(id: 2, position: (x: 3, y: 1), requiredBridges: 1),
        ],
        tutorial:
            LevelTutorial(hasInteractiveTutorial: false, hintTriggers: []),
      );
      ch1L10 = const LevelDefinition(
        id: 'ch01_10',
        version: 1,
        chapterId: 1,
        indexInChapter: 10,
        gridWidth: 5,
        gridHeight: 5,
        metadata: LevelMetadata(
          titleKey: 'l10',
          author: 'Test',
          difficultyTier: DifficultyTier.medium,
          estimatedSolveTimeSeconds: 90,
          parMoves: 5,
          mechanics: ['double_bridge'],
        ),
        islands: [
          Island(id: 1, position: (x: 1, y: 1), requiredBridges: 2),
          Island(id: 2, position: (x: 3, y: 1), requiredBridges: 2),
        ],
        tutorial:
            LevelTutorial(hasInteractiveTutorial: false, hintTriggers: []),
      );
      ch2L1 = const LevelDefinition(
        id: 'ch02_01',
        version: 1,
        chapterId: 2,
        indexInChapter: 1,
        gridWidth: 6,
        gridHeight: 6,
        metadata: LevelMetadata(
          titleKey: 'ch2_l1',
          author: 'Test',
          difficultyTier: DifficultyTier.easy,
          estimatedSolveTimeSeconds: 60,
          parMoves: 6,
          mechanics: ['parallel_paths'],
        ),
        islands: [
          Island(id: 1, position: (x: 1, y: 1), requiredBridges: 1),
          Island(id: 2, position: (x: 4, y: 1), requiredBridges: 1),
        ],
        tutorial:
            LevelTutorial(hasInteractiveTutorial: false, hintTriggers: []),
      );

      repo.loadLevels([ch1L1, ch1L2, ch1L10, ch2L1]);
    });

    test('partitions levels by chapter and exposes chapter IDs', () {
      expect(repo.chapterIds, [1, 2]);
      expect(repo.getChapterLevels(1).length, 3);
      expect(repo.getChapterLevels(2).length, 1);
      expect(repo.totalLevels, 4);
      expect(repo.getChapterTitle(1), 'First Connections');
      expect(repo.getChapterTitle(2), 'Parallel Paths');
      expect(repo.getChapterTitle(3), 'The Crossroads');
      expect(repo.getChapterTitle(4), "Master's Web");
    });

    test('getNextLevel transitions within chapter and crosses chapter boundary',
        () {
      // From Ch1 L1 to Ch1 L2
      final nextInChapter = repo.getNextLevel(ch1L1);
      expect(nextInChapter, isNotNull);
      expect(nextInChapter!.id, 'ch01_02');

      // When at the end of Chapter 1, transitions to Chapter 2 Level 1!
      final nextChapterLevel = repo.getNextLevel(ch1L10);
      expect(nextChapterLevel, isNotNull);
      expect(nextChapterLevel!.id, 'ch02_01');
      expect(nextChapterLevel.chapterId, 2);
      expect(nextChapterLevel.indexInChapter, 1);
    });
  });
}
