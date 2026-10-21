import 'package:flutter/widgets.dart';
import 'package:nodalis_domain/nodalis_domain.dart';
import '../tokens/theme.dart';
import 'board_geometry.dart';
import 'board_gesture_detector.dart';
import 'board_painter.dart';
import 'board_semantics.dart';
import 'board_view_model.dart';

/// Top-level composite widget for rendering and interacting with a Nodalis puzzle board.
/// Encapsulates zero-allocation painting, gesture detection, and accessibility semantics.
class BoardWidget extends StatefulWidget {
  final BoardViewModel viewModel;
  final ValueChanged<BoardViewModel> onViewModelChanged;
  final void Function(int fromId, int toId) onConnect;
  final ValueChanged<int>? onIslandCleared;
  final bool accessibilityShapes;

  const BoardWidget({
    super.key,
    required this.viewModel,
    required this.onViewModelChanged,
    required this.onConnect,
    this.onIslandCleared,
    this.accessibilityShapes = true,
  });

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  Size? _lastSize;
  int? _lastWidth;
  int? _lastHeight;
  Map<int, Island>? _lastIslands;
  BoardGeometry? _cachedGeometry;

  BoardGeometry _getOrCreateGeometry(Size canvasSize) {
    final board = widget.viewModel.board;
    if (_cachedGeometry != null &&
        _lastSize == canvasSize &&
        _lastWidth == board.width &&
        _lastHeight == board.height &&
        identical(_lastIslands, board.islands)) {
      return _cachedGeometry!;
    }

    _lastSize = canvasSize;
    _lastWidth = board.width;
    _lastHeight = board.height;
    _lastIslands = board.islands;
    _cachedGeometry = BoardGeometry.compute(
      canvasSize: canvasSize,
      gridWidth: board.width,
      gridHeight: board.height,
      islands: board.islands,
    );
    return _cachedGeometry!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = NodalisTheme.of(context);
    final palette = theme.palette;

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
        final geometry = _getOrCreateGeometry(canvasSize);

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Isolated RepaintBoundary: canvas repaints only when board model changes
            RepaintBoundary(
              child: CustomPaint(
                size: canvasSize,
                painter: BoardPainter(
                  viewModel: widget.viewModel,
                  geometry: geometry,
                  palette: palette,
                  accessibilityShapes: widget.accessibilityShapes,
                ),
              ),
            ),

            // 2. Accessibility Semantics Tree (VoiceOver / TalkBack / Web DOM)
            BoardSemantics(
              viewModel: widget.viewModel,
              geometry: geometry,
              onIslandTapped: (islandId) => _handleSemanticIslandTap(islandId),
              onIslandCleared: widget.onIslandCleared ?? (_) {},
            ),

            // 3. Low-latency gesture handling
            BoardGestureDetector(
              viewModel: widget.viewModel,
              geometry: geometry,
              onViewModelChanged: widget.onViewModelChanged,
              onConnect: widget.onConnect,
            ),
          ],
        );
      },
    );
  }

  void _handleSemanticIslandTap(int islandId) {
    final selectedId = widget.viewModel.selectedIslandId;
    if (selectedId == null) {
      widget.onViewModelChanged(
          widget.viewModel.copyWith(selectedIslandId: () => islandId));
    } else if (selectedId == islandId) {
      widget.onViewModelChanged(
          widget.viewModel.copyWith(selectedIslandId: () => null));
    } else {
      widget.onConnect(selectedId, islandId);
      widget.onViewModelChanged(
          widget.viewModel.copyWith(selectedIslandId: () => null));
    }
  }
}
