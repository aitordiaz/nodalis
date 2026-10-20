import 'package:flutter/material.dart';

/// Calm, refined color palette for Nodalis.
/// Designed for high readability, minimal eye fatigue, and WCAG AA/AAA compliance.
@immutable
final class NodalisPalette {
  final Color background;
  final Color surface;
  final Color surfaceSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // Board & Island colors
  final Color islandNormalFill;
  final Color islandNormalStroke;
  final Color islandSelectedStroke;
  final Color islandSatisfiedFill;
  final Color islandSatisfiedStroke;
  final Color islandExceededFill;
  final Color islandExceededStroke;

  // Bridge colors
  final Color bridgeNormal;
  final Color bridgePreview;
  final Color bridgeConflict;
  final Color gridDot;

  const NodalisPalette({
    required this.background,
    required this.surface,
    required this.surfaceSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.islandNormalFill,
    required this.islandNormalStroke,
    required this.islandSelectedStroke,
    required this.islandSatisfiedFill,
    required this.islandSatisfiedStroke,
    required this.islandExceededFill,
    required this.islandExceededStroke,
    required this.bridgeNormal,
    required this.bridgePreview,
    required this.bridgeConflict,
    required this.gridDot,
  });

  /// Premium calm light theme (architectural paper aesthetic).
  static const light = NodalisPalette(
    background: Color(0xFFF9F9F8),
    surface: Color(0xFFEFEFEF),
    surfaceSubtle: Color(0xFFE5E5E3),
    textPrimary: Color(0xFF1E2022),
    textSecondary: Color(0xFF5A6065),
    textMuted: Color(0xFF8C9298),
    islandNormalFill: Color(0xFFFFFFFF),
    islandNormalStroke: Color(0xFF2C3034),
    islandSelectedStroke: Color(0xFF2A6877),
    islandSatisfiedFill: Color(0xFFE7ECEB),
    islandSatisfiedStroke: Color(0xFF386B63),
    islandExceededFill: Color(0xFFFDF0ED),
    islandExceededStroke: Color(0xFFB84A39),
    bridgeNormal: Color(0xFF2C3034),
    bridgePreview: Color(0xFF5B8A96),
    bridgeConflict: Color(0xFFB84A39),
    gridDot: Color(0xFFD6D6D4),
  );

  /// Deep calm dark theme (minimal OLED eye strain).
  static const dark = NodalisPalette(
    background: Color(0xFF121417),
    surface: Color(0xFF1C1F24),
    surfaceSubtle: Color(0xFF272B32),
    textPrimary: Color(0xFFEDEDED),
    textSecondary: Color(0xFFA5ACB4),
    textMuted: Color(0xFF6F7680),
    islandNormalFill: Color(0xFF1E2228),
    islandNormalStroke: Color(0xFFD0D5DC),
    islandSelectedStroke: Color(0xFF6BB5C7),
    islandSatisfiedFill: Color(0xFF1D2E2B),
    islandSatisfiedStroke: Color(0xFF5FA89B),
    islandExceededFill: Color(0xFF3B1E1B),
    islandExceededStroke: Color(0xFFE06D5C),
    bridgeNormal: Color(0xFFD0D5DC),
    bridgePreview: Color(0xFF6BB5C7),
    bridgeConflict: Color(0xFFE06D5C),
    gridDot: Color(0xFF272B32),
  );

  /// High-contrast theme for enhanced visual accessibility.
  static const highContrast = NodalisPalette(
    background: Color(0xFF000000),
    surface: Color(0xFF1A1A1A),
    surfaceSubtle: Color(0xFF333333),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFEEEEEE),
    textMuted: Color(0xFFCCCCCC),
    islandNormalFill: Color(0xFF000000),
    islandNormalStroke: Color(0xFFFFFFFF),
    islandSelectedStroke: Color(0xFF00E5FF),
    islandSatisfiedFill: Color(0xFF003322),
    islandSatisfiedStroke: Color(0xFF00FF88),
    islandExceededFill: Color(0xFF440000),
    islandExceededStroke: Color(0xFFFF3333),
    bridgeNormal: Color(0xFFFFFFFF),
    bridgePreview: Color(0xFF00E5FF),
    bridgeConflict: Color(0xFFFF3333),
    gridDot: Color(0xFF555555),
  );
}
