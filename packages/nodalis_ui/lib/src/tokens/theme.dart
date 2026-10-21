import 'package:flutter/material.dart';
import 'palette.dart';

/// Supported display theme modes for Nodalis.
enum NodalisThemeMode {
  light,
  dark,
  oled;

  bool get isDark => this != NodalisThemeMode.light;

  NodalisThemeMode get next {
    switch (this) {
      case NodalisThemeMode.light:
        return NodalisThemeMode.dark;
      case NodalisThemeMode.dark:
        return NodalisThemeMode.oled;
      case NodalisThemeMode.oled:
        return NodalisThemeMode.light;
    }
  }

  String get label {
    switch (this) {
      case NodalisThemeMode.light:
        return 'Light';
      case NodalisThemeMode.dark:
        return 'Dark';
      case NodalisThemeMode.oled:
        return 'OLED Battery Saver';
    }
  }
}

/// Complete theme specification for Nodalis.
@immutable
final class NodalisThemeData {
  final NodalisPalette palette;
  final bool isDark;
  final NodalisThemeMode mode;

  const NodalisThemeData({
    required this.palette,
    required this.isDark,
    this.mode = NodalisThemeMode.light,
  });

  static const light = NodalisThemeData(
    palette: NodalisPalette.light,
    isDark: false,
    mode: NodalisThemeMode.light,
  );

  static const dark = NodalisThemeData(
    palette: NodalisPalette.dark,
    isDark: true,
    mode: NodalisThemeMode.dark,
  );

  static const oled = NodalisThemeData(
    palette: NodalisPalette.oled,
    isDark: true,
    mode: NodalisThemeMode.oled,
  );

  static const highContrast = NodalisThemeData(
    palette: NodalisPalette.highContrast,
    isDark: true,
    mode: NodalisThemeMode.dark,
  );

  static NodalisThemeData fromMode(NodalisThemeMode mode) {
    switch (mode) {
      case NodalisThemeMode.light:
        return light;
      case NodalisThemeMode.dark:
        return dark;
      case NodalisThemeMode.oled:
        return oled;
    }
  }

  ThemeData toMaterialTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: palette.islandSelectedStroke,
        onPrimary: palette.background,
        secondary: palette.islandSatisfiedStroke,
        onSecondary: palette.background,
        error: palette.islandExceededStroke,
        onError: Colors.white,
        surface: palette.surface,
        onSurface: palette.textPrimary,
      ),
      fontFamily: 'sans-serif',
    );
  }
}

/// InheritedWidget providing [NodalisThemeData] down the tree.
class NodalisTheme extends InheritedWidget {
  final NodalisThemeData data;

  const NodalisTheme({
    super.key,
    required this.data,
    required super.child,
  });

  static NodalisThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<NodalisTheme>();
    return theme?.data ?? NodalisThemeData.light;
  }

  @override
  bool updateShouldNotify(NodalisTheme oldWidget) => data != oldWidget.data;
}
