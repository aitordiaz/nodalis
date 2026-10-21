import 'package:flutter/widgets.dart';
import 'package:nodalis_domain/nodalis_domain.dart';
import 'board_geometry.dart';
import 'board_view_model.dart';

/// Touch and pointer gesture handler for the Nodalis puzzle board.
/// Translates low-level pointer events into high-level connection commands.
class BoardGestureDetector extends StatefulWidget {
  final BoardViewModel viewModel;
  final BoardGeometry geometry;
  final ValueChanged<BoardViewModel> onViewModelChanged;
  final void Function(int fromId, int toId) onConnect;

  const BoardGestureDetector({
    super.key,
    required this.viewModel,
    required this.geometry,
    required this.onViewModelChanged,
    required this.onConnect,
  });

  @override
  State<BoardGestureDetector> createState() => _BoardGestureDetectorState();
}

class _BoardGestureDetectorState extends State<BoardGestureDetector> {
  int? _activePanStartIslandId;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.viewModel.hoveredIslandId != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onHover: (event) {
        final islandId = widget.geometry.hitTestIsland(event.localPosition);
        if (islandId != widget.viewModel.hoveredIslandId) {
          widget.onViewModelChanged(
            widget.viewModel.copyWith(hoveredIslandId: () => islandId),
          );
        }
      },
      onExit: (_) {
        if (widget.viewModel.hoveredIslandId != null) {
          widget.onViewModelChanged(
            widget.viewModel.copyWith(hoveredIslandId: () => null),
          );
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: _handleTapUp,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        onPanCancel: _handlePanCancel,
        child: const SizedBox.expand(),
      ),
    );
  }

  void _handleTapUp(TapUpDetails details) {
    final tappedId = widget.geometry.hitTestIsland(details.localPosition);
    final selectedId = widget.viewModel.selectedIslandId;

    if (tappedId == null) {
      // 1. If an island was selected, check if user tapped in the corridor toward a valid neighbor
      if (selectedId != null) {
        final startPos = widget.geometry.islandPositions[selectedId];
        if (startPos != null) {
          final neighbors = widget.viewModel.board
              .getAvailableOrthogonalNeighbors(selectedId);
          for (final neighbor in neighbors) {
            final neighborPos = widget.geometry.islandPositions[neighbor.id];
            if (neighborPos == null) continue;

            final distToSegment = BoardGeometry.distanceToSegment(
                details.localPosition, startPos, neighborPos);
            if (distToSegment <= 35.0) {
              // Tapped along the corridor between selected island and this neighbor!
              widget.onConnect(selectedId, neighbor.id);
              widget.onViewModelChanged(
                widget.viewModel.copyWith(selectedIslandId: () => null),
              );
              return;
            }
          }
        }

        // Tapped empty space far from corridor: deselect
        widget.onViewModelChanged(
          widget.viewModel.copyWith(selectedIslandId: () => null),
        );
        return;
      }

      // 2. If no island was selected, check if user tapped directly on an existing active bridge to cycle it
      final bridgeHit = widget.geometry.hitTestBridge(
        details.localPosition,
        widget.viewModel.board.bridges,
      );
      if (bridgeHit != null) {
        widget.onConnect(bridgeHit.fromId, bridgeHit.toId);
        return;
      }

      return;
    }

    if (selectedId == null) {
      // First island selection
      widget.onViewModelChanged(
        widget.viewModel.copyWith(selectedIslandId: () => tappedId),
      );
    } else if (selectedId == tappedId) {
      // Tapped selected island again: deselect
      widget.onViewModelChanged(
        widget.viewModel.copyWith(selectedIslandId: () => null),
      );
    } else {
      // Tapped second island: attempt connection
      final board = widget.viewModel.board;
      final from = board.islands[selectedId];
      final to = board.islands[tappedId];

      if (from != null &&
          to != null &&
          from.position.isOrthogonalTo(to.position)) {
        widget.onConnect(selectedId, tappedId);
        widget.onViewModelChanged(
          widget.viewModel.copyWith(selectedIslandId: () => null),
        );
      } else {
        // Not orthogonal: switch selection to tapped island
        widget.onViewModelChanged(
          widget.viewModel.copyWith(selectedIslandId: () => tappedId),
        );
      }
    }
  }

  void _handlePanStart(DragStartDetails details) {
    final islandId = widget.geometry.hitTestIsland(details.localPosition);
    if (islandId != null) {
      _activePanStartIslandId = islandId;
      widget.onViewModelChanged(
        widget.viewModel.copyWith(
          dragStartIslandId: () => islandId,
          dragCurrentPosition: () => details.localPosition,
          potentialTargetIslandId: () => null,
          selectedIslandId: () => islandId,
        ),
      );
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_activePanStartIslandId == null) return;

    final startId = _activePanStartIslandId!;
    final currentPos = details.localPosition;
    final board = widget.viewModel.board;
    final startIsland = board.islands[startId];
    final startPos = widget.geometry.islandPositions[startId];

    int? candidateTargetId;
    if (startIsland != null && startPos != null) {
      final neighbors = board.getAvailableOrthogonalNeighbors(startId);
      final dragVector = currentPos - startPos;

      for (final neighbor in neighbors) {
        final neighborPos = widget.geometry.islandPositions[neighbor.id];
        if (neighborPos == null) continue;

        final targetVector = neighborPos - startPos;
        final targetDistance = targetVector.distance;
        if (targetDistance <= 0) continue;

        // Dot product projection of drag vector onto target vector
        final dot =
            dragVector.dx * targetVector.dx + dragVector.dy * targetVector.dy;
        if (dot > 0) {
          final projection = dot / targetDistance;
          // Perpendicular distance from drag position to axis
          final perpDistance = (dragVector -
                  Offset(
                    targetVector.dx * (projection / targetDistance),
                    targetVector.dy * (projection / targetDistance),
                  ))
              .distance;

          // Snap if within 45dp corridor of line and dragged at least 25% or within 55dp of target
          if (perpDistance <= 45.0 &&
              (projection >= targetDistance * 0.25 ||
                  (neighborPos - currentPos).distance <= 55.0)) {
            candidateTargetId = neighbor.id;
            break;
          }
        }
      }
    }

    widget.onViewModelChanged(
      widget.viewModel.copyWith(
        dragCurrentPosition: () => currentPos,
        potentialTargetIslandId: () => candidateTargetId,
      ),
    );
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_activePanStartIslandId != null) {
      final startId = _activePanStartIslandId!;
      final targetId = widget.viewModel.potentialTargetIslandId;

      if (targetId != null && targetId != startId) {
        widget.onConnect(startId, targetId);
      }
    }
    _clearDragState();
  }

  void _handlePanCancel() {
    _clearDragState();
  }

  void _clearDragState() {
    _activePanStartIslandId = null;
    widget.onViewModelChanged(
      widget.viewModel.copyWith(
        dragStartIslandId: () => null,
        dragCurrentPosition: () => null,
        potentialTargetIslandId: () => null,
      ),
    );
  }
}
