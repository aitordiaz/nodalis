import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nodalis_domain/nodalis_domain.dart';
import 'package:nodalis_ui/nodalis_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Immutable representation of an in-progress board configuration.
@immutable
final class ActiveBoardState {
  final List<Bridge> bridges;
  final int moveCount;

  const ActiveBoardState({
    required this.bridges,
    required this.moveCount,
  });
}

/// Immutable snapshot of persisted progress data.
@immutable
final class ProgressData {
  final Set<String> completedLevelIds;
  final Map<String, int> bestMoves;
  final String? lastCompletedLevelId;
  final String? lastPlayedLevelId;
  final bool? isDarkMode;
  final String? themeMode;
  final bool hapticsEnabled;
  final bool soundEnabled;
  final bool reduceMotion;
  final bool accessibilityShapes;
  final Map<String, ActiveBoardState> activeBoards;

  const ProgressData({
    this.completedLevelIds = const {},
    this.bestMoves = const {},
    this.lastCompletedLevelId,
    this.lastPlayedLevelId,
    this.isDarkMode,
    this.themeMode,
    this.hapticsEnabled = true,
    this.soundEnabled = true,
    this.reduceMotion = false,
    this.accessibilityShapes = true,
    this.activeBoards = const {},
  });
}

/// Abstract contract for persisting player progression across sessions.
abstract interface class ProgressPersistence {
  Future<ProgressData> loadProgress();

  Future<void> saveProgress({
    required Set<String> completedLevelIds,
    required Map<String, int> bestMoves,
    required String? lastCompletedLevelId,
    required String? lastPlayedLevelId,
  });

  Future<void> saveThemeMode(dynamic themeMode);

  Future<void> saveSettings({
    required bool hapticsEnabled,
    required bool soundEnabled,
    required bool reduceMotion,
    required bool accessibilityShapes,
  });

  Future<void> saveActiveBoard({
    required String levelId,
    required List<Bridge> bridges,
    required int moveCount,
  });

  Future<void> clearActiveBoard(String levelId);

  Future<void> clear();
}

/// Production implementation of [ProgressPersistence] backed by [SharedPreferences].
/// Works seamlessly on Web (localStorage), Android, iOS, macOS, Windows, and Linux.
final class SharedPreferencesProgressPersistence
    implements ProgressPersistence {
  static const _keyV2Store = 'nodalis_player_store_v2';
  static const _keyActiveBoards = 'nodalis_active_boards_v1';
  static const _keyCompletedLevels = 'nodalis_completed_levels_v1';
  static const _keyBestMoves = 'nodalis_best_moves_v1';
  static const _keyLastCompleted = 'nodalis_last_completed_v1';
  static const _keyLastPlayed = 'nodalis_last_played_v1';
  static const _keyThemeDark = 'nodalis_theme_dark_v1';
  static const _keyThemeMode = 'nodalis_theme_mode_v1';
  static const _keyHaptics = 'nodalis_settings_haptics_v1';
  static const _keySound = 'nodalis_settings_sound_v1';
  static const _keyReduceMotion = 'nodalis_settings_reduce_motion_v1';
  static const _keyAccessibilityShapes =
      'nodalis_settings_accessibility_shapes_v1';

  SharedPreferences? _cachedPrefs;

  SharedPreferencesProgressPersistence([SharedPreferences? prefs])
      : _cachedPrefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _cachedPrefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<ProgressData> loadProgress() async {
    try {
      final prefs = await _getPrefs();

      // 1. Check consolidated atomic V2 store first
      final v2Json = prefs.getString(_keyV2Store);
      Set<String> completedList = {};
      Map<String, int> bestMoves = {};
      String? lastCompleted;
      String? lastPlayed;
      String? themeMode;
      bool? isDark;
      bool haptics = true;
      bool sound = true;
      bool reduceMotion = false;
      bool accessibilityShapes = true;

      if (v2Json != null && v2Json.isNotEmpty) {
        try {
          final decoded = jsonDecode(v2Json) as Map<String, dynamic>;
          final rawCompleted = decoded['completedLevelIds'] as List<dynamic>?;
          if (rawCompleted != null) {
            completedList = rawCompleted.map((e) => e.toString()).toSet();
          }
          final rawBest = decoded['bestMoves'] as Map<String, dynamic>?;
          if (rawBest != null) {
            for (final entry in rawBest.entries) {
              if (entry.value is int) {
                bestMoves[entry.key] = entry.value as int;
              }
            }
          }
          lastCompleted = decoded['lastCompletedLevelId'] as String?;
          lastPlayed = decoded['lastPlayedLevelId'] as String?;
          themeMode = decoded['themeMode'] as String?;
          haptics = decoded['hapticsEnabled'] as bool? ?? true;
          sound = decoded['soundEnabled'] as bool? ?? true;
          reduceMotion = decoded['reduceMotion'] as bool? ?? false;
          accessibilityShapes = decoded['accessibilityShapes'] as bool? ?? true;
        } catch (e) {
          debugPrint('Failed to decode v2 store, falling back to legacy: $e');
        }
      }

      // Fall back to legacy keys if v2 store was absent or empty
      if (completedList.isEmpty && bestMoves.isEmpty && lastPlayed == null) {
        final legacyCompleted = prefs.getStringList(_keyCompletedLevels) ?? [];
        completedList = legacyCompleted.toSet();
        final bestMovesJson = prefs.getString(_keyBestMoves);
        if (bestMovesJson != null && bestMovesJson.isNotEmpty) {
          try {
            final decoded = jsonDecode(bestMovesJson) as Map<String, dynamic>;
            for (final entry in decoded.entries) {
              if (entry.value is int) {
                bestMoves[entry.key] = entry.value as int;
              }
            }
          } catch (_) {}
        }
        lastCompleted = prefs.getString(_keyLastCompleted);
        lastPlayed = prefs.getString(_keyLastPlayed);
      }

      isDark ??= prefs.getBool(_keyThemeDark);
      themeMode ??= prefs.getString(_keyThemeMode);
      haptics = prefs.getBool(_keyHaptics) ?? haptics;
      sound = prefs.getBool(_keySound) ?? sound;
      reduceMotion = prefs.getBool(_keyReduceMotion) ?? reduceMotion;
      accessibilityShapes =
          prefs.getBool(_keyAccessibilityShapes) ?? accessibilityShapes;

      // 2. Load active boards
      final Map<String, ActiveBoardState> activeBoards = {};
      final activeJson = prefs.getString(_keyActiveBoards);
      if (activeJson != null && activeJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(activeJson) as Map<String, dynamic>;
          for (final entry in decoded.entries) {
            final val = entry.value as Map<String, dynamic>;
            final moves = val['moves'] as int? ?? 0;
            final rawBridges = val['bridges'] as List<dynamic>? ?? [];
            final List<Bridge> bridgeList = [];
            for (final rb in rawBridges) {
              final bMap = rb as Map<String, dynamic>;
              final a = bMap['a'] as int;
              final b = bMap['b'] as int;
              final cVal = bMap['c'] as int;
              final count = switch (cVal) {
                2 => BridgeCount.double,
                1 => BridgeCount.single,
                _ => BridgeCount.none,
              };
              bridgeList.add(Bridge(islandAId: a, islandBId: b, count: count));
            }
            activeBoards[entry.key] =
                ActiveBoardState(bridges: bridgeList, moveCount: moves);
          }
        } catch (e) {
          debugPrint('Failed to decode active boards: $e');
        }
      }

      return ProgressData(
        completedLevelIds: completedList,
        bestMoves: bestMoves,
        lastCompletedLevelId: lastCompleted,
        lastPlayedLevelId: lastPlayed,
        isDarkMode: isDark,
        themeMode: themeMode,
        hapticsEnabled: haptics,
        soundEnabled: sound,
        reduceMotion: reduceMotion,
        accessibilityShapes: accessibilityShapes,
        activeBoards: activeBoards,
      );
    } catch (e) {
      debugPrint('Progress load failure (falling back to empty): $e');
      return const ProgressData();
    }
  }

  @override
  Future<void> saveProgress({
    required Set<String> completedLevelIds,
    required Map<String, int> bestMoves,
    required String? lastCompletedLevelId,
    required String? lastPlayedLevelId,
  }) async {
    try {
      final prefs = await _getPrefs();

      // Read current store to merge
      final existingStoreStr = prefs.getString(_keyV2Store);
      Map<String, dynamic> store = {};
      if (existingStoreStr != null && existingStoreStr.isNotEmpty) {
        try {
          store = jsonDecode(existingStoreStr) as Map<String, dynamic>;
        } catch (_) {}
      }

      store['completedLevelIds'] = completedLevelIds.toList();
      store['bestMoves'] = bestMoves;
      if (lastCompletedLevelId != null) {
        store['lastCompletedLevelId'] = lastCompletedLevelId;
      } else {
        store.remove('lastCompletedLevelId');
      }
      if (lastPlayedLevelId != null) {
        store['lastPlayedLevelId'] = lastPlayedLevelId;
      } else {
        store.remove('lastPlayedLevelId');
      }

      // 1. Atomic write to consolidated store first
      await prefs.setString(_keyV2Store, jsonEncode(store));

      // 2. Sequential writes for legacy key compatibility
      await prefs.setStringList(
          _keyCompletedLevels, completedLevelIds.toList());
      await prefs.setString(_keyBestMoves, jsonEncode(bestMoves));
      if (lastCompletedLevelId != null) {
        await prefs.setString(_keyLastCompleted, lastCompletedLevelId);
      } else {
        await prefs.remove(_keyLastCompleted);
      }
      if (lastPlayedLevelId != null) {
        await prefs.setString(_keyLastPlayed, lastPlayedLevelId);
      } else {
        await prefs.remove(_keyLastPlayed);
      }
    } catch (e) {
      debugPrint('Failed to persist progress: $e');
    }
  }

  @override
  Future<void> saveThemeMode(dynamic themeMode) async {
    try {
      final prefs = await _getPrefs();
      String? modeStr;
      bool? darkBool;
      if (themeMode is NodalisThemeMode) {
        modeStr = themeMode.name;
        darkBool = themeMode.isDark;
      } else if (themeMode is bool) {
        darkBool = themeMode;
        modeStr = themeMode ? 'dark' : 'light';
      } else if (themeMode is String) {
        modeStr = themeMode;
        darkBool = themeMode != 'light';
      }

      if (modeStr != null) {
        // Update V2 store
        final existingStoreStr = prefs.getString(_keyV2Store);
        Map<String, dynamic> store = {};
        if (existingStoreStr != null && existingStoreStr.isNotEmpty) {
          try {
            store = jsonDecode(existingStoreStr) as Map<String, dynamic>;
          } catch (_) {}
        }
        store['themeMode'] = modeStr;
        await prefs.setString(_keyV2Store, jsonEncode(store));

        await prefs.setString(_keyThemeMode, modeStr);
      }
      if (darkBool != null) {
        await prefs.setBool(_keyThemeDark, darkBool);
      }
    } catch (e) {
      debugPrint('Failed to persist theme mode: $e');
    }
  }

  @override
  Future<void> saveSettings({
    required bool hapticsEnabled,
    required bool soundEnabled,
    required bool reduceMotion,
    required bool accessibilityShapes,
  }) async {
    try {
      final prefs = await _getPrefs();

      // Update V2 store
      final existingStoreStr = prefs.getString(_keyV2Store);
      Map<String, dynamic> store = {};
      if (existingStoreStr != null && existingStoreStr.isNotEmpty) {
        try {
          store = jsonDecode(existingStoreStr) as Map<String, dynamic>;
        } catch (_) {}
      }
      store['hapticsEnabled'] = hapticsEnabled;
      store['soundEnabled'] = soundEnabled;
      store['reduceMotion'] = reduceMotion;
      store['accessibilityShapes'] = accessibilityShapes;
      await prefs.setString(_keyV2Store, jsonEncode(store));

      await prefs.setBool(_keyHaptics, hapticsEnabled);
      await prefs.setBool(_keySound, soundEnabled);
      await prefs.setBool(_keyReduceMotion, reduceMotion);
      await prefs.setBool(_keyAccessibilityShapes, accessibilityShapes);
    } catch (e) {
      debugPrint('Failed to persist settings: $e');
    }
  }

  @override
  Future<void> saveActiveBoard({
    required String levelId,
    required List<Bridge> bridges,
    required int moveCount,
  }) async {
    try {
      final prefs = await _getPrefs();
      final activeJson = prefs.getString(_keyActiveBoards);
      Map<String, dynamic> map = {};
      if (activeJson != null && activeJson.isNotEmpty) {
        try {
          map = jsonDecode(activeJson) as Map<String, dynamic>;
        } catch (_) {}
      }
      map[levelId] = {
        'moves': moveCount,
        'bridges': bridges
            .where((b) => b.isActive)
            .map(
                (b) => {'a': b.islandAId, 'b': b.islandBId, 'c': b.count.value})
            .toList(),
      };
      await prefs.setString(_keyActiveBoards, jsonEncode(map));
    } catch (e) {
      debugPrint('Failed to save active board: $e');
    }
  }

  @override
  Future<void> clearActiveBoard(String levelId) async {
    try {
      final prefs = await _getPrefs();
      final activeJson = prefs.getString(_keyActiveBoards);
      if (activeJson != null && activeJson.isNotEmpty) {
        try {
          final map = jsonDecode(activeJson) as Map<String, dynamic>;
          if (map.containsKey(levelId)) {
            map.remove(levelId);
            await prefs.setString(_keyActiveBoards, jsonEncode(map));
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Failed to clear active board: $e');
    }
  }

  @override
  Future<void> clear() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_keyV2Store);
      await prefs.remove(_keyActiveBoards);
      await prefs.remove(_keyCompletedLevels);
      await prefs.remove(_keyBestMoves);
      await prefs.remove(_keyLastCompleted);
      await prefs.remove(_keyLastPlayed);
    } catch (e) {
      debugPrint('Failed to clear progress: $e');
    }
  }
}

/// In-memory implementation of [ProgressPersistence] for unit and widget tests.
final class InMemoryProgressPersistence implements ProgressPersistence {
  ProgressData _data;

  InMemoryProgressPersistence([ProgressData? initialData])
      : _data = initialData ?? const ProgressData();

  @override
  Future<ProgressData> loadProgress() async => _data;

  @override
  Future<void> saveProgress({
    required Set<String> completedLevelIds,
    required Map<String, int> bestMoves,
    required String? lastCompletedLevelId,
    required String? lastPlayedLevelId,
  }) async {
    _data = ProgressData(
      completedLevelIds: Set.unmodifiable(completedLevelIds),
      bestMoves: Map.unmodifiable(bestMoves),
      lastCompletedLevelId: lastCompletedLevelId,
      lastPlayedLevelId: lastPlayedLevelId,
      isDarkMode: _data.isDarkMode,
      themeMode: _data.themeMode,
      hapticsEnabled: _data.hapticsEnabled,
      soundEnabled: _data.soundEnabled,
      reduceMotion: _data.reduceMotion,
      accessibilityShapes: _data.accessibilityShapes,
      activeBoards: _data.activeBoards,
    );
  }

  @override
  Future<void> saveThemeMode(dynamic themeMode) async {
    String? modeStr;
    bool? darkBool;
    if (themeMode is NodalisThemeMode) {
      modeStr = themeMode.name;
      darkBool = themeMode.isDark;
    } else if (themeMode is bool) {
      darkBool = themeMode;
      modeStr = themeMode ? 'dark' : 'light';
    } else if (themeMode is String) {
      modeStr = themeMode;
      darkBool = themeMode != 'light';
    }
    _data = ProgressData(
      completedLevelIds: _data.completedLevelIds,
      bestMoves: _data.bestMoves,
      lastCompletedLevelId: _data.lastCompletedLevelId,
      lastPlayedLevelId: _data.lastPlayedLevelId,
      isDarkMode: darkBool,
      themeMode: modeStr,
      hapticsEnabled: _data.hapticsEnabled,
      soundEnabled: _data.soundEnabled,
      reduceMotion: _data.reduceMotion,
      accessibilityShapes: _data.accessibilityShapes,
      activeBoards: _data.activeBoards,
    );
  }

  @override
  Future<void> saveSettings({
    required bool hapticsEnabled,
    required bool soundEnabled,
    required bool reduceMotion,
    required bool accessibilityShapes,
  }) async {
    _data = ProgressData(
      completedLevelIds: _data.completedLevelIds,
      bestMoves: _data.bestMoves,
      lastCompletedLevelId: _data.lastCompletedLevelId,
      lastPlayedLevelId: _data.lastPlayedLevelId,
      isDarkMode: _data.isDarkMode,
      themeMode: _data.themeMode,
      hapticsEnabled: hapticsEnabled,
      soundEnabled: soundEnabled,
      reduceMotion: reduceMotion,
      accessibilityShapes: accessibilityShapes,
      activeBoards: _data.activeBoards,
    );
  }

  @override
  Future<void> saveActiveBoard({
    required String levelId,
    required List<Bridge> bridges,
    required int moveCount,
  }) async {
    final updated = Map<String, ActiveBoardState>.from(_data.activeBoards);
    updated[levelId] = ActiveBoardState(bridges: bridges, moveCount: moveCount);
    _data = ProgressData(
      completedLevelIds: _data.completedLevelIds,
      bestMoves: _data.bestMoves,
      lastCompletedLevelId: _data.lastCompletedLevelId,
      lastPlayedLevelId: _data.lastPlayedLevelId,
      isDarkMode: _data.isDarkMode,
      themeMode: _data.themeMode,
      hapticsEnabled: _data.hapticsEnabled,
      soundEnabled: _data.soundEnabled,
      reduceMotion: _data.reduceMotion,
      accessibilityShapes: _data.accessibilityShapes,
      activeBoards: updated,
    );
  }

  @override
  Future<void> clearActiveBoard(String levelId) async {
    final updated = Map<String, ActiveBoardState>.from(_data.activeBoards);
    updated.remove(levelId);
    _data = ProgressData(
      completedLevelIds: _data.completedLevelIds,
      bestMoves: _data.bestMoves,
      lastCompletedLevelId: _data.lastCompletedLevelId,
      lastPlayedLevelId: _data.lastPlayedLevelId,
      isDarkMode: _data.isDarkMode,
      themeMode: _data.themeMode,
      hapticsEnabled: _data.hapticsEnabled,
      soundEnabled: _data.soundEnabled,
      reduceMotion: _data.reduceMotion,
      accessibilityShapes: _data.accessibilityShapes,
      activeBoards: updated,
    );
  }

  @override
  Future<void> clear() async {
    _data = const ProgressData();
  }
}
