import 'package:meta/meta.dart';
import '../entities/bridge.dart';

/// Sealed class representing player actions mutating board state.
@immutable
sealed class BoardAction {
  const BoardAction();
}

/// Action to add or set a bridge connection between two islands.
final class SetBridgeAction extends BoardAction {
  final int fromId;
  final int toId;
  final BridgeCount targetCount;

  const SetBridgeAction({
    required this.fromId,
    required this.toId,
    required this.targetCount,
  });

  @override
  String toString() => 'SetBridgeAction($fromId -> $toId: ${targetCount.name})';
}

/// Action to cycle bridge connection count (none -> single -> double -> none).
final class CycleBridgeAction extends BoardAction {
  final int fromId;
  final int toId;

  const CycleBridgeAction({
    required this.fromId,
    required this.toId,
  });

  @override
  String toString() => 'CycleBridgeAction($fromId <-> $toId)';
}

/// Action to clear all bridges connected to a given island.
final class ClearIslandBridgesAction extends BoardAction {
  final int islandId;

  const ClearIslandBridgesAction({required this.islandId});

  @override
  String toString() => 'ClearIslandBridgesAction(island: $islandId)';
}

/// Action to clear all bridges on the board.
final class ResetBoardAction extends BoardAction {
  const ResetBoardAction();

  @override
  String toString() => 'ResetBoardAction()';
}
