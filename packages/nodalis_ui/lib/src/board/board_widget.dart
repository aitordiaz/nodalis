import 'package:flutter/widgets.dart';
import '../tokens/theme.dart';
import 'board_geometry.dart';
import 'board_gesture_detector.dart';
import 'board_painter.dart';
import 'board_semantics.dart';
import 'board_view_model.dart';

/// Top-level composite widget for rendering and interacting with a Nodalis puzzle board.
/// Encapsulates zero-allocation painting, gesture detection, and accessibility semantics.
class BoardWidget extends StatelessWidget {
  final BoardViewModel viewModel;
  final ValueChanged<BoardViewModel> onViewModelChanged;
  final void Function(int fromId, int toId) onConnect;
  final ValueChanged<int>? onIslandCleared;

  const BoardWidget({
    super.key,
    required this.viewModel,
    required this.onViewModelChanged,
    required this.onConnect,
    this.onIslandCleared,
  });

  @override
  Widget build(BuildContext context) {
    final theme = NodalisTheme.of(context);
    final palette = theme.palette;

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        final geometry = BoardGeometry.compute(
          canvasSize: canvasSize,
          gridWidth: viewModel.board.width,
          gridHeight: viewModel.board.height,
          islands: viewModel.board.islands,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Isolated RepaintBoundary: canvas repaints only when board model changes
            RepaintBoundary(
              child: CustomPaint(
                size: canvasSize,
                painter: BoardPainter(
                  viewModel: viewModel,
                  geometry: geometry,
                  palette: palette,
                ),
              ),
            ),

            // 2. Accessibility Semantics Tree (VoiceOver / TalkBack / Web DOM)
            BoardSemantics(
              viewModel: viewModel,
              geometry: geometry,
              onIslandTapped: (islandId) => _handleSemanticIslandTap(islandId),
              onIslandCleared: onIslandCleared ?? (_) {},
            ),

            // 3. Low-latency gesture handling
            BoardGestureDetector(
              viewModel: viewModel,
              geometry: geometry,
              onViewModelChanged: onViewModelChanged,
              onConnect: onConnect,
            ),
          ],
        );
      },
    );
  }

  void _handleSemanticIslandTap(int islandId) {
    final selectedId = viewModel.selectedIslandId;
    if (selectedId == null) {
      onViewModelChanged(viewModel.copyWith(selectedIslandId: () => islandId));
    } else if (selectedId == islandId) {
      onViewModelChanged(viewModel.copyWith(selectedIslandId: () => null));
    } else {
      onConnect(selectedId, islandId);
      onViewModelChanged(viewModel.copyWith(selectedIslandId: () => null));
    }
  }
}
