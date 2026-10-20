/// Logical 2D coordinate on the puzzle grid (0-indexed).
typedef GridPoint = ({int x, int y});

extension GridPointExtension on GridPoint {
  /// Checks whether [other] is strictly horizontally or vertically aligned.
  bool isOrthogonalTo(GridPoint other) =>
      (x == other.x && y != other.y) || (y == other.y && x != other.x);

  /// Manhattan distance between two points.
  int manhattanDistanceTo(GridPoint other) =>
      (x - other.x).abs() + (y - other.y).abs();
}
