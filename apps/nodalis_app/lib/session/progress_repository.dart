import 'package:flutter/foundation.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';
import 'progress_persistence.dart';

/// Manages local player progression, level unlocks, move records, and session persistence.
class ProgressRepository extends ChangeNotifier {
  final ProgressPersistence _persistence;
  final Set<String> _completedLevelIds = {};
  final Map<String, int> _bestMoves = {};
  String? _lastCompletedLevelId;
  String? _lastPlayedLevelId;
  bool _isLoaded = false;

  ProgressRepository({ProgressPersistence? persistence})
      : _persistence = persistence ?? SharedPreferencesProgressPersistence();

  /// Named constructor for unit and widget testing with in-memory persistence.
  ProgressRepository.inMemory([ProgressData? initialData])
      : _persistence = InMemoryProgressPersistence(initialData);

  bool get isLoaded => _isLoaded;
  Set<String> get completedLevelIds => Set.unmodifiable(_completedLevelIds);
  Map<String, int> get bestMoves => Map.unmodifiable(_bestMoves);
  String? get lastCompletedLevelId => _lastCompletedLevelId;
  String? get lastPlayedLevelId => _lastPlayedLevelId;

  /// Loads saved progress asynchronously from disk or browser local storage.
  Future<void> load() async {
    final data = await _persistence.loadProgress();
    _completedLevelIds.clear();
    _completedLevelIds.addAll(data.completedLevelIds);

    _bestMoves.clear();
    _bestMoves.addAll(data.bestMoves);

    _lastCompletedLevelId = data.lastCompletedLevelId;
    _lastPlayedLevelId = data.lastPlayedLevelId;
    _isLoaded = true;
    notifyListeners();
  }

  bool isLevelCompleted(String levelId) => _completedLevelIds.contains(levelId);

  int? getBestMoves(String levelId) => _bestMoves[levelId];

  /// A level is unlocked if it is the first level of Chapter 1,
  /// or if the first level of Chapter N where Chapter N-1 is completed,
  /// or if the preceding level in the chapter has been completed.
  bool isLevelUnlocked(
      LevelDefinition level, List<LevelDefinition> chapterLevels,
      {List<LevelDefinition>? previousChapterLevels}) {
    if (level.chapterId == 1 && level.indexInChapter == 1) return true;

    if (level.indexInChapter == 1) {
      if (previousChapterLevels == null || previousChapterLevels.isEmpty) {
        return true;
      }
      return isLevelCompleted(previousChapterLevels.last.id);
    }

    final prevIndex = level.indexInChapter - 1;
    final prevLevel = chapterLevels.where((l) => l.indexInChapter == prevIndex);
    if (prevLevel.isNotEmpty) {
      return isLevelCompleted(prevLevel.first.id);
    }
    return false;
  }

  /// Finds the next uncompleted level that is currently unlocked, or the last level if all are completed.
  LevelDefinition? getNextRecommendedLevel(List<LevelDefinition> chapterLevels) {
    for (final level in chapterLevels) {
      if (isLevelUnlocked(level, chapterLevels) &&
          !isLevelCompleted(level.id)) {
        return level;
      }
    }
    return null;
  }

  void recordCompletion(String levelId, int moves) {
    _completedLevelIds.add(levelId);
    final previousBest = _bestMoves[levelId];
    if (previousBest == null || moves < previousBest) {
      _bestMoves[levelId] = moves;
    }
    _lastCompletedLevelId = levelId;
    _lastPlayedLevelId = levelId;
    notifyListeners();

    // Persist asynchronously in background
    _persistence.saveProgress(
      completedLevelIds: _completedLevelIds,
      bestMoves: _bestMoves,
      lastCompletedLevelId: _lastCompletedLevelId,
      lastPlayedLevelId: _lastPlayedLevelId,
    );
  }

  void setLastPlayed(String levelId) {
    _lastPlayedLevelId = levelId;
    notifyListeners();

    _persistence.saveProgress(
      completedLevelIds: _completedLevelIds,
      bestMoves: _bestMoves,
      lastCompletedLevelId: _lastCompletedLevelId,
      lastPlayedLevelId: _lastPlayedLevelId,
    );
  }

  void resetProgress() {
    _completedLevelIds.clear();
    _bestMoves.clear();
    _lastCompletedLevelId = null;
    _lastPlayedLevelId = null;
    notifyListeners();

    _persistence.clear();
  }

  Future<void> saveThemeMode(bool isDark) => _persistence.saveThemeMode(isDark);

  Future<bool?> loadThemeMode() async =>
      (await _persistence.loadProgress()).isDarkMode;
}
