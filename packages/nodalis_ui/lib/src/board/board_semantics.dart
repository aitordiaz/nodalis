import 'package:flutter/widgets.dart';
import 'package:nodalis_domain/nodalis_domain.dart';
import '../tokens/dimensions.dart';
import 'board_geometry.dart';
import 'board_view_model.dart';

/// Accessibility semantics overlay mapping the puzzle board canvas into an accessible widget tree.
/// Ensures TalkBack, VoiceOver, and Web screen readers can fully inspect and interact with the puzzle.
class BoardSemantics extends StatelessWidget {
  final BoardViewModel viewModel;
  final BoardGeometry geometry;
  final ValueChanged<int> onIslandTapped;
  final ValueChanged<int> onIslandCleared;

  const BoardSemantics({
    super.key,
    required this.viewModel,
    required this.geometry,
    required this.onIslandTapped,
    required this.onIslandCleared,
  });

  @override
  Widget build(BuildContext context) {
    final board = viewModel.board;
    const halfTarget = NodalisDimensions.minTouchTarget / 2;

    return Stack(
      children: [
        for (final island in board.islands.values) ...[
          if (geometry.islandPositions[island.id] != null)
            Positioned(
              left: geometry.islandPositions[island.id]!.dx - halfTarget,
              top: geometry.islandPositions[island.id]!.dy - halfTarget,
              width: NodalisDimensions.minTouchTarget,
              height: NodalisDimensions.minTouchTarget,
              child: _buildIslandSemantics(island, board),
            ),
        ],
      ],
    );
  }

  Widget _buildIslandSemantics(Island island, Board board) {
    final connected = board.getConnectedBridgeCount(island.id);
    final remaining = board.getRemainingCapacity(island.id);
    final isSatisfied = board.isIslandSatisfied(island.id);
    final isSelected = viewModel.selectedIslandId == island.id;

    final label =
        'Island at row ${island.position.y + 1}, column ${island.position.x + 1}. Capacity ${island.requiredBridges}.';
    final value = isSatisfied
        ? 'Satisfied with $connected bridges.'
        : '$connected connected, $remaining remaining.';
    final hint = isSelected
        ? 'Selected. Double tap an adjacent island to connect.'
        : 'Double tap to select.';

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      value: value,
      hint: hint,
      onTap: () => onIslandTapped(island.id),
      onDismiss: () => onIslandCleared(island.id),
      child: const SizedBox.expand(),
    );
  }
}
