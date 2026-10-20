import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:nodalis_domain/nodalis_domain.dart';
import '../tokens/dimensions.dart';

/// Precomputed layout geometry for rendering and hit-testing the puzzle board.
@immutable
final class BoardGeometry {
  final Size canvasSize;
  final int gridWidth;
  final int gridHeight;
  final double cellSize;
  final Offset origin;
  final Map<int, Offset> islandPositions;

  const BoardGeometry._({
    required this.canvasSize,
    required this.gridWidth,
    required this.gridHeight,
    required this.cellSize,
    required this.origin,
    required this.islandPositions,
  });

  /// Factory computing geometry fitted within [canvasSize] with padding.
  factory BoardGeometry.compute({
    required Size canvasSize,
    required int gridWidth,
    required int gridHeight,
    required Map<int, Island> islands,
    double padding = 24.0,
  }) {
    final availableWidth = math.max(0.0, canvasSize.width - padding * 2);
    final availableHeight = math.max(0.0, canvasSize.height - padding * 2);

    final cellW =
        gridWidth > 1 ? availableWidth / (gridWidth - 1) : availableWidth;
    final cellH =
        gridHeight > 1 ? availableHeight / (gridHeight - 1) : availableHeight;
    final cellSize = math.min(cellW, cellH).clamp(32.0, 96.0);

    final boardWidth = (gridWidth - 1) * cellSize;
    final boardHeight = (gridHeight - 1) * cellSize;

    final originX = (canvasSize.width - boardWidth) / 2;
    final originY = (canvasSize.height - boardHeight) / 2;
    final origin = Offset(originX, originY);

    final positions = <int, Offset>{};
    for (final island in islands.values) {
      positions[island.id] = Offset(
        originX + island.position.x * cellSize,
        originY + island.position.y * cellSize,
      );
    }

    return BoardGeometry._(
      canvasSize: canvasSize,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      cellSize: cellSize,
      origin: origin,
      islandPositions: positions,
    );
  }

  /// Converts a grid coordinate to canvas pixel offset.
  Offset gridToOffset(GridPoint point) {
    return Offset(
      origin.dx + point.x * cellSize,
      origin.dy + point.y * cellSize,
    );
  }

  /// Hit-tests a screen point to identify an island (using minimum touch target radius).
  int? hitTestIsland(Offset localPosition,
      {double hitRadius = NodalisDimensions.islandHitRadius}) {
    for (final entry in islandPositions.entries) {
      final distance = (entry.value - localPosition).distance;
      if (distance <= hitRadius) {
        return entry.key;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardGeometry &&
          runtimeType == other.runtimeType &&
          canvasSize == other.canvasSize &&
          gridWidth == other.gridWidth &&
          gridHeight == other.gridHeight &&
          cellSize == other.cellSize &&
          origin == other.origin;

  @override
  int get hashCode =>
      Object.hash(canvasSize, gridWidth, gridHeight, cellSize, origin);
}
