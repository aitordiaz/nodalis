import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nodalis_ui/nodalis_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> clear();
}

/// Production implementation of [ProgressPersistence] backed by [SharedPreferences].
/// Works seamlessly on Web (localStorage), Android, iOS, macOS, Windows, and Linux.
final class SharedPreferencesProgressPersistence
    implements ProgressPersistence {
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

  Future<SharedPreferences> _getPrefs() async {
    return _cachedPrefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<ProgressData> loadProgress() async {
    try {
      final prefs = await _getPrefs();
      final completedList = prefs.getStringList(_keyCompletedLevels) ?? [];
      final bestMovesJson = prefs.getString(_keyBestMoves);
      final lastCompleted = prefs.getString(_keyLastCompleted);
      final lastPlayed = prefs.getString(_keyLastPlayed);
      final isDark = prefs.getBool(_keyThemeDark);
      final themeMode = prefs.getString(_keyThemeMode);
      final haptics = prefs.getBool(_keyHaptics) ?? true;
      final sound = prefs.getBool(_keySound) ?? true;
      final reduceMotion = prefs.getBool(_keyReduceMotion) ?? false;
      final accessibilityShapes =
          prefs.getBool(_keyAccessibilityShapes) ?? true;

      final Map<String, int> bestMoves = {};
      if (bestMovesJson != null && bestMovesJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(bestMovesJson) as Map<String, dynamic>;
          for (final entry in decoded.entries) {
            if (entry.value is int) {
              bestMoves[entry.key] = entry.value as int;
            }
          }
        } catch (e) {
          debugPrint('Failed to decode best moves: $e');
        }
      }

      return ProgressData(
        completedLevelIds: completedList.toSet(),
        bestMoves: bestMoves,
        lastCompletedLevelId: lastCompleted,
        lastPlayedLevelId: lastPlayed,
        isDarkMode: isDark,
        themeMode: themeMode,
        hapticsEnabled: haptics,
        soundEnabled: sound,
        reduceMotion: reduceMotion,
        accessibilityShapes: accessibilityShapes,
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
      await Future.wait([
        prefs.setStringList(_keyCompletedLevels, completedLevelIds.toList()),
        prefs.setString(_keyBestMoves, jsonEncode(bestMoves)),
        if (lastCompletedLevelId != null)
          prefs.setString(_keyLastCompleted, lastCompletedLevelId)
        else
          prefs.remove(_keyLastCompleted),
        if (lastPlayedLevelId != null)
          prefs.setString(_keyLastPlayed, lastPlayedLevelId)
        else
          prefs.remove(_keyLastPlayed),
      ]);
    } catch (e) {
      debugPrint('Failed to persist progress: $e');
    }
  }

  @override
  Future<void> saveThemeMode(dynamic themeMode) async {
    try {
      final prefs = await _getPrefs();
      if (themeMode is NodalisThemeMode) {
        await Future.wait([
          prefs.setString(_keyThemeMode, themeMode.name),
          prefs.setBool(_keyThemeDark, themeMode.isDark),
        ]);
      } else if (themeMode is bool) {
        await Future.wait([
          prefs.setBool(_keyThemeDark, themeMode),
          prefs.setString(_keyThemeMode, themeMode ? 'dark' : 'light'),
        ]);
      } else if (themeMode is String) {
        await prefs.setString(_keyThemeMode, themeMode);
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
      await Future.wait([
        prefs.setBool(_keyHaptics, hapticsEnabled),
        prefs.setBool(_keySound, soundEnabled),
        prefs.setBool(_keyReduceMotion, reduceMotion),
        prefs.setBool(_keyAccessibilityShapes, accessibilityShapes),
      ]);
    } catch (e) {
      debugPrint('Failed to persist settings: $e');
    }
  }

  @override
  Future<void> clear() async {
    try {
      final prefs = await _getPrefs();
      await Future.wait([
        prefs.remove(_keyCompletedLevels),
        prefs.remove(_keyBestMoves),
        prefs.remove(_keyLastCompleted),
        prefs.remove(_keyLastPlayed),
      ]);
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
    );
  }

  @override
  Future<void> clear() async {
    _data = const ProgressData();
  }
}
