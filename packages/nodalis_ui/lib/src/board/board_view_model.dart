import 'package:flutter/widgets.dart';
import 'package:nodalis_domain/nodalis_domain.dart';

/// Immutable view model carrying all state needed to render the board and interaction cues.
@immutable
final class BoardViewModel {
  final Board board;
  final int? selectedIslandId;
  final int? hoveredIslandId;
  final int? dragStartIslandId;
  final Offset? dragCurrentPosition;
  final int? potentialTargetIslandId;

  const BoardViewModel({
    required this.board,
    this.selectedIslandId,
    this.hoveredIslandId,
    this.dragStartIslandId,
    this.dragCurrentPosition,
    this.potentialTargetIslandId,
  });

  bool get isDragging =>
      dragStartIslandId != null && dragCurrentPosition != null;

  /// IDs of valid orthogonal neighbor islands connectable to the active island.
  Set<int> get validTargetIslandIds {
    final activeId = dragStartIslandId ?? selectedIslandId;
    if (activeId == null) return const {};
    final neighbors = board.getAvailableOrthogonalNeighbors(activeId);
    return neighbors.map((i) => i.id).toSet();
  }

  BoardViewModel copyWith({
    Board? board,
    int? Function()? selectedIslandId,
    int? Function()? hoveredIslandId,
    int? Function()? dragStartIslandId,
    Offset? Function()? dragCurrentPosition,
    int? Function()? potentialTargetIslandId,
  }) {
    return BoardViewModel(
      board: board ?? this.board,
      selectedIslandId:
          selectedIslandId != null ? selectedIslandId() : this.selectedIslandId,
      hoveredIslandId:
          hoveredIslandId != null ? hoveredIslandId() : this.hoveredIslandId,
      dragStartIslandId: dragStartIslandId != null
          ? dragStartIslandId()
          : this.dragStartIslandId,
      dragCurrentPosition: dragCurrentPosition != null
          ? dragCurrentPosition()
          : this.dragCurrentPosition,
      potentialTargetIslandId: potentialTargetIslandId != null
          ? potentialTargetIslandId()
          : this.potentialTargetIslandId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardViewModel &&
          runtimeType == other.runtimeType &&
          board == other.board &&
          selectedIslandId == other.selectedIslandId &&
          hoveredIslandId == other.hoveredIslandId &&
          dragStartIslandId == other.dragStartIslandId &&
          dragCurrentPosition == other.dragCurrentPosition &&
          potentialTargetIslandId == other.potentialTargetIslandId;

  @override
  int get hashCode => Object.hash(
        board,
        selectedIslandId,
        hoveredIslandId,
        dragStartIslandId,
        dragCurrentPosition,
        potentialTargetIslandId,
      );
}
