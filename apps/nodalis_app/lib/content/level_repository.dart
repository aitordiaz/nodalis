import 'package:flutter/services.dart';
import 'package:nodalis_level_format/nodalis_level_format.dart';

/// Asset-backed repository providing access to handcrafted chapters and levels.
class LevelRepository {
  final Map<String, LevelDefinition> _levelsById = {};
  final Map<int, List<LevelDefinition>> _levelsByChapter = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  static const List<String> _chapter1FileNames = [
    '01_first_steps.json',
    '02_triangle.json',
    '03_the_line.json',
    '04_double_bridge.json',
    '05_corner_lock.json',
    '06_crossroads.json',
    '07_pinch_point.json',
    '08_weaving.json',
    '09_the_anchor.json',
    '10_chapter_finale.json',
  ];

  /// Loads all bundled levels into memory from asset bundle.
  Future<void> loadBundledLevels([AssetBundle? bundle]) async {
    final assetBundle = bundle ?? rootBundle;
    _levelsById.clear();
    _levelsByChapter.clear();

    for (final fileName in _chapter1FileNames) {
      final jsonString =
          await assetBundle.loadString('assets/levels/$fileName');
      final level = LevelParser.parseJson(jsonString);
      _registerLevel(level);
    }

    _isLoaded = true;
  }

  /// Manually loads a list of levels (useful for tests and offline fallbacks).
  void loadLevels(Iterable<LevelDefinition> levels) {
    _levelsById.clear();
    _levelsByChapter.clear();
    for (final level in levels) {
      _registerLevel(level);
    }
    _isLoaded = true;
  }

  void _registerLevel(LevelDefinition level) {
    _levelsById[level.id] = level;
    _levelsByChapter.putIfAbsent(level.chapterId, () => []).add(level);
    _levelsByChapter[level.chapterId]!
        .sort((a, b) => a.indexInChapter.compareTo(b.indexInChapter));
  }

  List<LevelDefinition> getChapterLevels(int chapterId) {
    return _levelsByChapter[chapterId] ?? const [];
  }

  LevelDefinition? getLevel(int chapterId, int indexInChapter) {
    final chapter = _levelsByChapter[chapterId];
    if (chapter == null) return null;
    return chapter.firstWhere(
      (l) => l.indexInChapter == indexInChapter,
      orElse: () => chapter.first,
    );
  }

  LevelDefinition? getNextLevel(LevelDefinition current) {
    final chapter = _levelsByChapter[current.chapterId];
    if (chapter == null) return null;

    final nextIndex = current.indexInChapter + 1;
    final inChapter = chapter.where((l) => l.indexInChapter == nextIndex);
    if (inChapter.isNotEmpty) return inChapter.first;

    // Next chapter first level
    final nextChapter = _levelsByChapter[current.chapterId + 1];
    if (nextChapter != null && nextChapter.isNotEmpty) {
      return nextChapter.first;
    }
    return null;
  }
}
