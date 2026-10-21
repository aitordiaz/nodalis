import 'dart:ui' as ui;
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
  late final Paint _doubleBridgePaint;
  late final Paint _bridgeSatisfiedPaint;
  late final Paint _doubleBridgeSatisfiedPaint;
  late final Paint _bridgePreviewPaint;
  late final Paint _candidateHaloPaint;
  late final Paint _islandSelectedGlowPaint;
  late final Paint _pipFilledPaint;
  late final Paint _pipEmptyPaint;

  // Cached TextPainters for digits 1..8
  final Map<int, TextPainter> _cachedTextPainters = {};
  // Precomputed island text top-left offsets for zero heap allocation during paint
  final Map<int, Offset> _islandTextOffsets = {};
  // Precomputed double bridge parallel line pairs: key -> (line1A, line1B, line2A, line2B)
  final Map<BridgeKey, ({Offset a1, Offset b1, Offset a2, Offset b2})>
      _doubleBridgeLines = {};

  BoardPainter({
    required this.viewModel,
    required this.geometry,
    required this.palette,
  }) : super() {
    _initPaints();
    _initTextPainters();
    _precomputeDoubleBridges();
  }

  void _initPaints() {
    _gridDotPaint = Paint()
      ..color = palette.gridDot
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

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

    _doubleBridgePaint = Paint()
      ..color = palette.bridgeNormal
      ..style = PaintingStyle.stroke
      ..strokeWidth = NodalisDimensions.doubleBridgeStrokeWidth
      ..strokeCap = StrokeCap.round;

    _bridgeSatisfiedPaint = Paint()
      ..color = palette.islandSatisfiedStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = NodalisDimensions.bridgeStrokeWidth
      ..strokeCap = StrokeCap.round;

    _doubleBridgeSatisfiedPaint = Paint()
      ..color = palette.islandSatisfiedStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = NodalisDimensions.doubleBridgeStrokeWidth
      ..strokeCap = StrokeCap.round;

    _bridgePreviewPaint = Paint()
      ..color = palette.bridgePreview
      ..style = PaintingStyle.stroke
      ..strokeWidth = NodalisDimensions.bridgeStrokeWidth
      ..strokeCap = StrokeCap.round;

    _candidateHaloPaint = Paint()
      ..color = palette.islandSelectedStroke.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    _islandSelectedGlowPaint = Paint()
      ..color = palette.islandSelectedStroke.withOpacity(0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    _pipFilledPaint = Paint()
      ..color = palette.islandSatisfiedStroke
      ..style = PaintingStyle.fill;

    _pipEmptyPaint = Paint()
      ..color = palette.textMuted.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
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

    // Precalculate digit text top-left offsets for all islands
    for (final island in viewModel.board.islands.values) {
      final center = geometry.islandPositions[island.id];
      final painter = _cachedTextPainters[island.requiredBridges];
      if (center != null && painter != null) {
        _islandTextOffsets[island.id] = Offset(
          center.dx - painter.width / 2,
          center.dy - painter.height / 2 - 2.5,
        );
      }
    }
  }

  void _precomputeDoubleBridges() {
    const halfGap = NodalisDimensions.doubleBridgeGap / 2;
    for (final bridge in viewModel.board.bridges.values) {
      if (bridge.count != BridgeCount.double) continue;
      final posA = geometry.islandPositions[bridge.islandAId];
      final posB = geometry.islandPositions[bridge.islandBId];
      if (posA == null || posB == null) continue;

      final isHorizontal = (posA.dy - posB.dy).abs() < 1.0;
      if (isHorizontal) {
        _doubleBridgeLines[bridge.key] = (
          a1: Offset(posA.dx, posA.dy - halfGap),
          b1: Offset(posB.dx, posB.dy - halfGap),
          a2: Offset(posA.dx, posA.dy + halfGap),
          b2: Offset(posB.dx, posB.dy + halfGap),
        );
      } else {
        _doubleBridgeLines[bridge.key] = (
          a1: Offset(posA.dx - halfGap, posA.dy),
          b1: Offset(posB.dx - halfGap, posB.dy),
          a2: Offset(posA.dx + halfGap, posA.dy),
          b2: Offset(posB.dx + halfGap, posB.dy),
        );
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawGridBackground(canvas);
    _drawConnectionGuides(canvas);
    _drawBridges(canvas);
    _drawDragPreview(canvas);
    _drawIslands(canvas);
  }

  void _drawConnectionGuides(Canvas canvas) {
    final activeId = viewModel.dragStartIslandId ?? viewModel.selectedIslandId;
    if (activeId == null) return;

    for (final targetId in viewModel.validTargetIslandIds) {
      final targetPos = geometry.islandPositions[targetId];
      if (targetPos == null) continue;

      // Draw clear candidate target halo ring indicating valid tap/drop destination
      canvas.drawCircle(
        targetPos,
        NodalisDimensions.islandVisualRadius + 5.0,
        _candidateHaloPaint,
      );
    }
  }

  void _drawGridBackground(Canvas canvas) {
    if (geometry.gridDotOffsets.isNotEmpty) {
      canvas.drawPoints(
        ui.PointMode.points,
        geometry.gridDotOffsets,
        _gridDotPaint,
      );
    }
  }

  void _drawBridges(Canvas canvas) {
    final board = viewModel.board;

    for (final bridge in board.bridges.values) {
      if (!bridge.isActive) continue;

      final posA = geometry.islandPositions[bridge.islandAId];
      final posB = geometry.islandPositions[bridge.islandBId];
      if (posA == null || posB == null) continue;

      final bothSatisfied = board.isIslandSatisfied(bridge.islandAId) &&
          board.isIslandSatisfied(bridge.islandBId);

      final singlePaint = bothSatisfied ? _bridgeSatisfiedPaint : _bridgePaint;
      final doublePaint =
          bothSatisfied ? _doubleBridgeSatisfiedPaint : _doubleBridgePaint;

      switch (bridge.count) {
        case BridgeCount.single:
          canvas.drawLine(posA, posB, singlePaint);
        case BridgeCount.double:
          final lines = _doubleBridgeLines[bridge.key];
          if (lines != null) {
            canvas.drawLine(lines.a1, lines.b1, doublePaint);
            canvas.drawLine(lines.a2, lines.b2, doublePaint);
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

      // 0. Selected island outer glowing halo
      if (isSelected || isTargeted) {
        canvas.drawCircle(
          center,
          NodalisDimensions.islandVisualRadius + 6.0,
          _islandSelectedGlowPaint,
        );
      }

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

      // 4. Draw number digit from precomputed offset
      final textPainter = _cachedTextPainters[island.requiredBridges];
      final textOffset = _islandTextOffsets[island.id];
      if (textPainter != null && textOffset != null) {
        textPainter.paint(canvas, textOffset);
      }

      // 5. Draw connection progress pips from precomputed positions
      final pips = geometry.islandPipPositions[island.id];
      if (pips != null && pips.isNotEmpty) {
        const pipRadius = 2.0;
        for (var i = 0; i < pips.length; i++) {
          final pipCenter = pips[i];
          final paint = i < connected ? _pipFilledPaint : _pipEmptyPaint;
          canvas.drawCircle(pipCenter, pipRadius, paint);
        }
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
