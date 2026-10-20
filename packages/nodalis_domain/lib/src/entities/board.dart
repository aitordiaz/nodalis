import 'package:meta/meta.dart';
import '../actions/board_action.dart';
import '../common/result.dart';
import '../rules/domain_failure.dart';
import '../rules/rules_engine.dart';
import 'bridge.dart';
import 'island.dart';

/// Immutable representation of the puzzle board.
@immutable
final class Board {
  final int width;
  final int height;
  final Map<int, Island> islands;
  final Map<BridgeKey, Bridge> bridges;

  const Board({
    required this.width,
    required this.height,
    required this.islands,
    required this.bridges,
  })  : assert(width > 0, 'Width must be positive'),
        assert(height > 0, 'Height must be positive');

  /// Creates an empty board with specified dimensions and islands, but zero bridges.
  factory Board.initial({
    required int width,
    required int height,
    required Iterable<Island> islands,
  }) {
    final islandMap = {for (final island in islands) island.id: island};
    return Board(
      width: width,
      height: height,
      islands: islandMap,
      bridges: const {},
    );
  }

  /// Evaluates whether the current board state fulfills all win conditions.
  bool get isSolved => RulesEngine.isBoardSolved(
        islands: islands,
        bridges: bridges,
      );

  /// Number of active bridges placed on the board.
  int get activeBridgeCount => bridges.values.where((b) => b.isActive).length;

  /// Returns the current number of bridges connected to [islandId].
  int getConnectedBridgeCount(int islandId) =>
      RulesEngine.calculateConnectedBridgeCount(islandId, bridges);

  /// Returns remaining bridges required for [islandId].
  int getRemainingCapacity(int islandId) {
    final island = islands[islandId];
    if (island == null) return 0;
    return island.requiredBridges - getConnectedBridgeCount(islandId);
  }

  /// Whether an island has exactly its required bridge count satisfied.
  bool isIslandSatisfied(int islandId) {
    final island = islands[islandId];
    if (island == null) return false;
    return getConnectedBridgeCount(islandId) == island.requiredBridges;
  }

  /// Finds all direct orthogonal neighbor islands that could legally connect to [islandId].
  List<Island> getAvailableOrthogonalNeighbors(int islandId) {
    final current = islands[islandId];
    if (current == null) return const [];

    final result = <Island>[];
    // Directions: North, South, East, West
    final directions = [(0, -1), (0, 1), (1, 0), (-1, 0)];

    for (final (dx, dy) in directions) {
      Island? closest;
      var minDist = 999999;

      for (final other in islands.values) {
        if (other.id == islandId) continue;
        final deltaX = other.position.x - current.position.x;
        final deltaY = other.position.y - current.position.y;

        // Check alignment in this direction
        final aligned = (dx != 0 && deltaY == 0 && (deltaX > 0) == (dx > 0)) ||
            (dy != 0 && deltaX == 0 && (deltaY > 0) == (dy > 0));

        if (aligned) {
          final dist = deltaX.abs() + deltaY.abs();
          if (dist < minDist) {
            minDist = dist;
            closest = other;
          }
        }
      }

      if (closest != null) {
        result.add(closest);
      }
    }

    return result;
  }

  /// Pure transition function: applies a [BoardAction] and returns either a new [Board] or a [DomainFailure].
  Result<Board, DomainFailure> applyAction(BoardAction action) {
    return switch (action) {
      SetBridgeAction(:final fromId, :final toId, :final targetCount) =>
        _setBridge(fromId, toId, targetCount),
      CycleBridgeAction(:final fromId, :final toId) =>
        _cycleBridge(fromId, toId),
      ClearIslandBridgesAction(:final islandId) =>
        _clearIslandBridges(islandId),
      ResetBoardAction() => Result.ok(_resetBoard()),
    };
  }

  Result<Board, DomainFailure> _setBridge(
    int fromId,
    int toId,
    BridgeCount targetCount,
  ) {
    final from = islands[fromId];
    if (from == null) return Result.err(IslandNotFoundFailure(fromId));

    final to = islands[toId];
    if (to == null) return Result.err(IslandNotFoundFailure(toId));

    final validation = RulesEngine.validateBridgePlacement(
      from: from,
      to: to,
      allIslands: islands.values,
      existingBridges: bridges,
      islandMap: islands,
      newCount: targetCount,
    );

    if (validation.isErr) {
      return Result.err(validation.errorOrNull!);
    }

    final key = makeBridgeKey(fromId, toId);
    final newBridges = Map<BridgeKey, Bridge>.from(bridges);

    if (targetCount == BridgeCount.none) {
      newBridges.remove(key);
    } else {
      newBridges[key] = Bridge(
        islandAId: fromId,
        islandBId: toId,
        count: targetCount,
      );
    }

    return Result.ok(Board(
      width: width,
      height: height,
      islands: islands,
      bridges: Map.unmodifiable(newBridges),
    ));
  }

  Result<Board, DomainFailure> _cycleBridge(int fromId, int toId) {
    final key = makeBridgeKey(fromId, toId);
    final currentCount = bridges[key]?.count ?? BridgeCount.none;

    if (currentCount == BridgeCount.none) {
      return _setBridge(fromId, toId, BridgeCount.single);
    } else if (currentCount == BridgeCount.single) {
      // Try double bridge first; if capacity would be exceeded, wrap directly to none
      final doubleResult = _setBridge(fromId, toId, BridgeCount.double);
      if (doubleResult.isOk) {
        return doubleResult;
      }
      if (doubleResult.errorOrNull is CapacityExceededFailure) {
        return _setBridge(fromId, toId, BridgeCount.none);
      }
      return doubleResult;
    } else {
      return _setBridge(fromId, toId, BridgeCount.none);
    }
  }

  Result<Board, DomainFailure> _clearIslandBridges(int islandId) {
    if (!islands.containsKey(islandId)) {
      return Result.err(IslandNotFoundFailure(islandId));
    }

    final newBridges = Map<BridgeKey, Bridge>.from(bridges);
    newBridges.removeWhere(
      (key, bridge) =>
          bridge.islandAId == islandId || bridge.islandBId == islandId,
    );

    return Result.ok(Board(
      width: width,
      height: height,
      islands: islands,
      bridges: Map.unmodifiable(newBridges),
    ));
  }

  Board _resetBoard() => Board(
        width: width,
        height: height,
        islands: islands,
        bridges: const {},
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Board &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          height == other.height &&
          _mapsEqual(islands, other.islands) &&
          _mapsEqual(bridges, other.bridges);

  @override
  int get hashCode => Object.hash(
        width,
        height,
        Object.hashAll(islands.entries),
        Object.hashAll(bridges.entries),
      );

  static bool _mapsEqual<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) return false;
    }
    return true;
  }
}
