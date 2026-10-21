import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nodalis_domain/nodalis_domain.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';
import 'package:nodalis_ui/nodalis_ui.dart';
import '../content/level_repository.dart';
import 'progress_persistence.dart';

/// Manages local player progression, level unlocks, move records, and session persistence.
class ProgressRepository extends ChangeNotifier {
  final ProgressPersistence _persistence;
  final Set<String> _completedLevelIds = {};
  final Map<String, int> _bestMoves = {};
  final Map<String, ActiveBoardState> _activeBoards = {};
  String? _lastCompletedLevelId;
  String? _lastPlayedLevelId;
  String? _lastThemeModeName;
  bool _isLoaded = false;
  bool _hapticsEnabled = true;
  bool _soundEnabled = true;
  bool _reduceMotion = false;
  bool _accessibilityShapes = true;

  ProgressRepository({ProgressPersistence? persistence})
      : _persistence = persistence ?? SharedPreferencesProgressPersistence();

  /// Named constructor for unit and widget testing with in-memory persistence.
  ProgressRepository.inMemory([ProgressData? initialData])
      : _persistence = InMemoryProgressPersistence(initialData);

  bool get isLoaded => _isLoaded;
  Set<String> get completedLevelIds => Set.unmodifiable(_completedLevelIds);
  Map<String, int> get bestMoves => Map.unmodifiable(_bestMoves);
  Map<String, ActiveBoardState> get activeBoards =>
      Map.unmodifiable(_activeBoards);
  String? get lastCompletedLevelId => _lastCompletedLevelId;
  String? get lastPlayedLevelId => _lastPlayedLevelId;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get reduceMotion => _reduceMotion;
  bool get accessibilityShapes => _accessibilityShapes;

  NodalisThemeMode get currentThemeMode {
    if (_lastThemeModeName != null) {
      for (final mode in NodalisThemeMode.values) {
        if (mode.name == _lastThemeModeName) return mode;
      }
    }
    return NodalisThemeMode.light;
  }

  void triggerHaptic({bool medium = false}) {
    if (_hapticsEnabled) {
      if (medium) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
  }

  void updateSettings({
    bool? hapticsEnabled,
    bool? soundEnabled,
    bool? reduceMotion,
    bool? accessibilityShapes,
  }) {
    if (hapticsEnabled != null) _hapticsEnabled = hapticsEnabled;
    if (soundEnabled != null) _soundEnabled = soundEnabled;
    if (reduceMotion != null) _reduceMotion = reduceMotion;
    if (accessibilityShapes != null) _accessibilityShapes = accessibilityShapes;
    notifyListeners();

    _persistence.saveSettings(
      hapticsEnabled: _hapticsEnabled,
      soundEnabled: _soundEnabled,
      reduceMotion: _reduceMotion,
      accessibilityShapes: _accessibilityShapes,
    );
  }

  /// Loads saved progress asynchronously from disk or browser local storage.
  Future<void> load() async {
    final data = await _persistence.loadProgress();
    _completedLevelIds.clear();
    _completedLevelIds.addAll(data.completedLevelIds);

    _bestMoves.clear();
    _bestMoves.addAll(data.bestMoves);

    _activeBoards.clear();
    _activeBoards.addAll(data.activeBoards);

    _lastCompletedLevelId = data.lastCompletedLevelId;
    _lastPlayedLevelId = data.lastPlayedLevelId;
    _lastThemeModeName = data.themeMode;
    _hapticsEnabled = data.hapticsEnabled;
    _soundEnabled = data.soundEnabled;
    _reduceMotion = data.reduceMotion;
    _accessibilityShapes = data.accessibilityShapes;
    _isLoaded = true;
    notifyListeners();
  }

  bool isLevelCompleted(String levelId) => _completedLevelIds.contains(levelId);

  int? getBestMoves(String levelId) => _bestMoves[levelId];

  ActiveBoardState? getActiveBoard(String levelId) => _activeBoards[levelId];

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
  LevelDefinition? getNextRecommendedLevel(
      List<LevelDefinition> chapterLevels) {
    for (final level in chapterLevels) {
      if (isLevelUnlocked(level, chapterLevels) &&
          !isLevelCompleted(level.id)) {
        return level;
      }
    }
    return null;
  }

  /// Determines the ideal level to resume for the player.
  LevelDefinition? getResumeLevel(LevelRepository levelRepo) {
    if (!levelRepo.isLoaded) return null;

    // 1. If player was actively playing a level that is not yet completed:
    if (_lastPlayedLevelId != null) {
      final level = levelRepo.getLevelById(_lastPlayedLevelId!);
      if (level != null && !isLevelCompleted(level.id)) {
        return level;
      }
    }

    // 2. If the last played level is completed, advance to the next level in campaign:
    final referenceLevelId = _lastPlayedLevelId ?? _lastCompletedLevelId;
    if (referenceLevelId != null) {
      final refLevel = levelRepo.getLevelById(referenceLevelId);
      if (refLevel != null) {
        final next = levelRepo.getNextLevel(refLevel);
        if (next != null) {
          return next;
        }
      }
    }

    // 3. Scan chapters in sequence for the first unlocked, uncompleted level:
    for (final chId in levelRepo.chapterIds) {
      if (chId == 0) continue;
      final chLevels = levelRepo.getChapterLevels(chId);
      final next = getNextRecommendedLevel(chLevels);
      if (next != null) return next;
    }

    // 4. Default to first level of Chapter 1 if available:
    final firstChapter = levelRepo.getChapterLevels(1);
    if (firstChapter.isNotEmpty) return firstChapter.first;

    return null;
  }

  Future<void> recordCompletion(String levelId, int moves) async {
    _completedLevelIds.add(levelId);
    final previousBest = _bestMoves[levelId];
    if (previousBest == null || moves < previousBest) {
      _bestMoves[levelId] = moves;
    }
    _lastCompletedLevelId = levelId;
    _lastPlayedLevelId = levelId;
    _activeBoards.remove(levelId);
    notifyListeners();

    await _persistence.clearActiveBoard(levelId);
    await _persistence.saveProgress(
      completedLevelIds: _completedLevelIds,
      bestMoves: _bestMoves,
      lastCompletedLevelId: _lastCompletedLevelId,
      lastPlayedLevelId: _lastPlayedLevelId,
    );
  }

  Future<void> setLastPlayed(String levelId) async {
    final changed = _lastPlayedLevelId != levelId;
    _lastPlayedLevelId = levelId;
    if (changed) {
      notifyListeners();
    }

    await _persistence.saveProgress(
      completedLevelIds: _completedLevelIds,
      bestMoves: _bestMoves,
      lastCompletedLevelId: _lastCompletedLevelId,
      lastPlayedLevelId: _lastPlayedLevelId,
    );
  }

  Future<void> saveActiveBoard(
      String levelId, List<Bridge> bridges, int moveCount) async {
    _activeBoards[levelId] =
        ActiveBoardState(bridges: bridges, moveCount: moveCount);
    _lastPlayedLevelId = levelId;

    await _persistence.saveActiveBoard(
      levelId: levelId,
      bridges: bridges,
      moveCount: moveCount,
    );
    await _persistence.saveProgress(
      completedLevelIds: _completedLevelIds,
      bestMoves: _bestMoves,
      lastCompletedLevelId: _lastCompletedLevelId,
      lastPlayedLevelId: _lastPlayedLevelId,
    );
  }

  Future<void> clearActiveBoard(String levelId) async {
    _activeBoards.remove(levelId);
    await _persistence.clearActiveBoard(levelId);
  }

  Future<void> resetProgress() async {
    _completedLevelIds.clear();
    _bestMoves.clear();
    _activeBoards.clear();
    _lastCompletedLevelId = null;
    _lastPlayedLevelId = null;
    notifyListeners();

    await _persistence.clear();
  }

  Future<void> saveThemeMode(dynamic themeMode) async {
    if (themeMode is NodalisThemeMode) {
      _lastThemeModeName = themeMode.name;
    } else if (themeMode is String) {
      _lastThemeModeName = themeMode;
    } else if (themeMode is bool) {
      _lastThemeModeName = themeMode ? 'dark' : 'light';
    }
    await _persistence.saveThemeMode(themeMode);
  }

  Future<NodalisThemeMode> loadThemeMode() async {
    final data = await _persistence.loadProgress();
    if (data.themeMode != null) {
      for (final mode in NodalisThemeMode.values) {
        if (mode.name == data.themeMode) {
          _lastThemeModeName = mode.name;
          return mode;
        }
      }
    }
    final mode = data.isDarkMode == true
        ? NodalisThemeMode.dark
        : NodalisThemeMode.light;
    _lastThemeModeName = mode.name;
    return mode;
  }
}
