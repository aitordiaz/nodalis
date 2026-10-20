/// Dimension and spacing tokens for Nodalis.
abstract final class NodalisDimensions {
  /// Minimum touch target size meeting WCAG 2.5.5 / 2.5.8 (48x48 dp).
  static const double minTouchTarget = 48.0;

  /// Visual radius of an island node on the grid.
  static const double islandVisualRadius = 22.0;

  /// Visual diameter of an island node.
  static const double islandVisualDiameter = islandVisualRadius * 2;

  /// Hit test radius for touch interaction (expanded for thumb reachability).
  static const double islandHitRadius = 26.0;

  /// Stroke width for island outlines.
  static const double islandStrokeWidth = 2.0;

  /// Stroke width for a single bridge.
  static const double bridgeStrokeWidth = 2.5;

  /// Offset between the two parallel lines in a double bridge.
  static const double doubleBridgeGap = 6.0;

  /// Hysteresis threshold for dragging connections between islands (dp).
  static const double dragHysteresis = 12.0;

  /// Border radius tokens.
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 14.0;
  static const double radiusLarge = 20.0;
}
