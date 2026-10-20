import 'package:flutter/widgets.dart';
import 'package:nodalis_domain/nodalis_domain.dart';
import '../tokens/dimensions.dart';
import '../tokens/palette.dart';
import 'board_geometry.dart';
import 'board_view_model.dart';

/// Highly optimized, zero-heap-allocation CustomPainter for the Nodalis puzzle board.
/// Repaints strictly when the immutable [BoardViewModel], [BoardGeometry], or [NodalisPalette] changes.
final class BoardPainter extends CustomPainter {
  final BoardViewModel viewModel;
  final BoardGeometry geometry;
  final NodalisPalette palette;

  // Reusable, pre-allocated Paint objects
  late final Paint _gridDotPaint;
  late final Paint _islandFillPaint;
  late final Paint _islandStrokePaint;
  late final Paint _islandSelectedStrokePaint;
  late final Paint _islandSatisfiedFillPaint;
  late final Paint _islandSatisfiedStrokePaint;
  late final Paint _islandExceededFillPaint;
  late final Paint _islandExceededStrokePaint;
  late final Paint _bridgePaint;
  late final Paint _bridgePreviewPaint;

  // Cached TextPainters for digits 1..8
  final Map<int, TextPainter> _cachedTextPainters = {};

  BoardPainter({
    required this.viewModel,
    required this.geometry,
    required this.palette,
  }) : super() {
    _initPaints();
    _initTextPainters();
  }

  void _initPaints() {
    _gridDotPaint = Paint()
      ..color = palette.gridDot
      ..style = PaintingStyle.fill;

    _islandFillPaint = Paint()
      ..color = palette.islandNormalFill
      ..style = PaintingStyle.fill;

    _islandStrokePaint = Paint()
      ..color = palette.islandNormalStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = NodalisDimensions.islandStrokeWidth;

    _islandSelectedStrokePaint = Paint()
      ..color = palette.islandSelectedStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    _islandSatisfiedFillPaint = Paint()
      ..color = palette.islandSatisfiedFill
      ..style = PaintingStyle.fill;

    _islandSatisfiedStrokePaint = Paint()
      ..color = palette.islandSatisfiedStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = NodalisDimensions.islandStrokeWidth;

    _islandExceededFillPaint = Paint()
      ..color = palette.islandExceededFill
      ..style = PaintingStyle.fill;

    _islandExceededStrokePaint = Paint()
      ..color = palette.islandExceededStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = NodalisDimensions.islandStrokeWidth;

    _bridgePaint = Paint()
      ..color = palette.bridgeNormal
      ..style = PaintingStyle.stroke
      ..strokeWidth = NodalisDimensions.bridgeStrokeWidth
      ..strokeCap = StrokeCap.round;

    _bridgePreviewPaint = Paint()
      ..color = palette.bridgePreview
      ..style = PaintingStyle.stroke
      ..strokeWidth = NodalisDimensions.bridgeStrokeWidth
      ..strokeCap = StrokeCap.round;
  }

  void _initTextPainters() {
    final baseStyle = TextStyle(
      color: palette.textPrimary,
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
    );

    for (var i = 1; i <= 8; i++) {
      final painter = TextPainter(
        text: TextSpan(text: '$i', style: baseStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      _cachedTextPainters[i] = painter;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawGridBackground(canvas);
    _drawBridges(canvas);
    _drawDragPreview(canvas);
    _drawIslands(canvas);
  }

  void _drawGridBackground(Canvas canvas) {
    for (var x = 0; x < geometry.gridWidth; x++) {
      for (var y = 0; y < geometry.gridHeight; y++) {
        final offset = geometry.gridToOffset((x: x, y: y));
        canvas.drawCircle(offset, 1.5, _gridDotPaint);
      }
    }
  }

  void _drawBridges(Canvas canvas) {
    final board = viewModel.board;

    for (final bridge in board.bridges.values) {
      if (!bridge.isActive) continue;

      final posA = geometry.islandPositions[bridge.islandAId];
      final posB = geometry.islandPositions[bridge.islandBId];
      if (posA == null || posB == null) continue;

      final isHorizontal = posA.dy == posB.dy;

      switch (bridge.count) {
        case BridgeCount.single:
          canvas.drawLine(posA, posB, _bridgePaint);
        case BridgeCount.double:
          const halfGap = NodalisDimensions.doubleBridgeGap / 2;
          if (isHorizontal) {
            canvas.drawLine(
              Offset(posA.dx, posA.dy - halfGap),
              Offset(posB.dx, posB.dy - halfGap),
              _bridgePaint,
            );
            canvas.drawLine(
              Offset(posA.dx, posA.dy + halfGap),
              Offset(posB.dx, posB.dy + halfGap),
              _bridgePaint,
            );
          } else {
            canvas.drawLine(
              Offset(posA.dx - halfGap, posA.dy),
              Offset(posB.dx - halfGap, posB.dy),
              _bridgePaint,
            );
            canvas.drawLine(
              Offset(posA.dx + halfGap, posA.dy),
              Offset(posB.dx + halfGap, posB.dy),
              _bridgePaint,
            );
          }
        case BridgeCount.none:
          break;
      }
    }
  }

  void _drawDragPreview(Canvas canvas) {
    if (!viewModel.isDragging) return;

    final startId = viewModel.dragStartIslandId!;
    final startPos = geometry.islandPositions[startId];
    if (startPos == null) return;

    final targetId = viewModel.potentialTargetIslandId;
    final targetPos =
        targetId != null ? geometry.islandPositions[targetId] : null;

    final endPos = targetPos ?? viewModel.dragCurrentPosition!;
    canvas.drawLine(startPos, endPos, _bridgePreviewPaint);
  }

  void _drawIslands(Canvas canvas) {
    final board = viewModel.board;

    for (final island in board.islands.values) {
      final center = geometry.islandPositions[island.id];
      if (center == null) continue;

      final connected = board.getConnectedBridgeCount(island.id);
      final isSatisfied = connected == island.requiredBridges;
      final isExceeded = connected > island.requiredBridges;
      final isSelected = viewModel.selectedIslandId == island.id;
      final isTargeted = viewModel.potentialTargetIslandId == island.id;

      // 1. Draw fill
      final fillPaint = isExceeded
          ? _islandExceededFillPaint
          : (isSatisfied ? _islandSatisfiedFillPaint : _islandFillPaint);
      canvas.drawCircle(
          center, NodalisDimensions.islandVisualRadius, fillPaint);

      // 2. Draw outline
      final strokePaint = isSelected || isTargeted
          ? _islandSelectedStrokePaint
          : (isExceeded
              ? _islandExceededStrokePaint
              : (isSatisfied
                  ? _islandSatisfiedStrokePaint
                  : _islandStrokePaint));
      canvas.drawCircle(
          center, NodalisDimensions.islandVisualRadius, strokePaint);

      // 3. Multi-channel accessibility indicator: subtle concentric ring for satisfied
      if (isSatisfied && !isExceeded) {
        canvas.drawCircle(center, NodalisDimensions.islandVisualRadius - 4.5,
            _islandSatisfiedStrokePaint);
      }

      // 4. Draw number digit
      final textPainter = _cachedTextPainters[island.requiredBridges];
      if (textPainter != null) {
        final textOffset = Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        );
        textPainter.paint(canvas, textOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return viewModel != oldDelegate.viewModel ||
        geometry != oldDelegate.geometry ||
        palette != oldDelegate.palette;
  }
}
