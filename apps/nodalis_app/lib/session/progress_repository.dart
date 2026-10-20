import 'package:flutter/foundation.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';

/// Manages local player progression, level unlocks, and move records.
class ProgressRepository extends ChangeNotifier {
  final Set<String> _completedLevelIds = {};
  final Map<String, int> _bestMoves = {};
  String? _lastPlayedLevelId;

  Set<String> get completedLevelIds => Set.unmodifiable(_completedLevelIds);
  Map<String, int> get bestMoves => Map.unmodifiable(_bestMoves);
  String? get lastPlayedLevelId => _lastPlayedLevelId;

  bool isLevelCompleted(String levelId) => _completedLevelIds.contains(levelId);

  int? getBestMoves(String levelId) => _bestMoves[levelId];

  /// A level is unlocked if it is the first level of Chapter 1,
  /// or if the preceding level in the chapter has been completed.
  bool isLevelUnlocked(
      LevelDefinition level, List<LevelDefinition> chapterLevels) {
    if (level.chapterId == 1 && level.indexInChapter == 1) return true;

    final prevIndex = level.indexInChapter - 1;
    final prevLevel = chapterLevels.where((l) => l.indexInChapter == prevIndex);
    if (prevLevel.isNotEmpty) {
      return isLevelCompleted(prevLevel.first.id);
    }
    return false;
  }

  void recordCompletion(String levelId, int moves) {
    _completedLevelIds.add(levelId);
    final previousBest = _bestMoves[levelId];
    if (previousBest == null || moves < previousBest) {
      _bestMoves[levelId] = moves;
    }
    _lastPlayedLevelId = levelId;
    notifyListeners();
  }

  void setLastPlayed(String levelId) {
    _lastPlayedLevelId = levelId;
    notifyListeners();
  }

  void resetProgress() {
    _completedLevelIds.clear();
    _bestMoves.clear();
    _lastPlayedLevelId = null;
    notifyListeners();
  }
}
