import 'package:flutter/material.dart';
import 'palette.dart';

/// Complete theme specification for Nodalis.
@immutable
final class NodalisThemeData {
  final NodalisPalette palette;
  final bool isDark;

  const NodalisThemeData({
    required this.palette,
    required this.isDark,
  });

  static const light = NodalisThemeData(
    palette: NodalisPalette.light,
    isDark: false,
  );

  static const dark = NodalisThemeData(
    palette: NodalisPalette.dark,
    isDark: true,
  );

  static const highContrast = NodalisThemeData(
    palette: NodalisPalette.highContrast,
    isDark: true,
  );

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
