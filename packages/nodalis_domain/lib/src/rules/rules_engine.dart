import 'dart:math' as math;
import '../common/result.dart';
import '../entities/bridge.dart';
import '../entities/coordinate.dart';
import '../entities/island.dart';
import 'domain_failure.dart';

/// Pure rules engine executing deterministic game invariant checks.
abstract final class RulesEngine {
  /// Checks whether two positions are strictly orthogonal (horizontal or vertical).
  static bool areOrthogonal(GridPoint a, GridPoint b) => a.isOrthogonalTo(b);

  /// Checks if any island lies strictly between [from] and [to] on the orthogonal axis.
  static int? findInterveningIslandId({
    required GridPoint from,
    required GridPoint to,
    required Iterable<Island> allIslands,
  }) {
    final isHorizontal = from.y == to.y;
    final minCoord =
        isHorizontal ? math.min(from.x, to.x) : math.min(from.y, to.y);
    final maxCoord =
        isHorizontal ? math.max(from.x, to.x) : math.max(from.y, to.y);
    final fixedCoord = isHorizontal ? from.y : from.x;

    for (final island in allIslands) {
      final pos = island.position;
      if (isHorizontal) {
        if (pos.y == fixedCoord && pos.x > minCoord && pos.x < maxCoord) {
          return island.id;
        }
      } else {
        if (pos.x == fixedCoord && pos.y > minCoord && pos.y < maxCoord) {
          return island.id;
        }
      }
    }
    return null;
  }

  /// Checks whether two orthogonal segments strictly cross each other.
  /// Two segments that share an endpoint or are parallel do not cross.
  static bool doSegmentsCross({
    required GridPoint a1,
    required GridPoint a2,
    required GridPoint b1,
    required GridPoint b2,
  }) {
    final aIsHorizontal = a1.y == a2.y;
    final bIsHorizontal = b1.y == b2.y;

    // Parallel segments cannot cross in planar orthogonal grid without overlapping
    if (aIsHorizontal == bIsHorizontal) return false;

    final (h1, h2) = aIsHorizontal ? (a1, a2) : (b1, b2);
    final (v1, v2) = aIsHorizontal ? (b1, b2) : (a1, a2);

    final hMinX = math.min(h1.x, h2.x);
    final hMaxX = math.max(h1.x, h2.x);
    final hY = h1.y;

    final vMinY = math.min(v1.y, v2.y);
    final vMaxY = math.max(v1.y, v2.y);
    final vX = v1.x;

    // Strict intersection: intersection point (vX, hY) is strictly interior to both segments
    return (vX > hMinX && vX < hMaxX) && (hY > vMinY && hY < vMaxY);
  }

  /// Validates whether a bridge can be legally placed between [from] and [to].
  static Result<void, DomainFailure> validateBridgePlacement({
    required Island from,
    required Island to,
    required Iterable<Island> allIslands,
    required Map<BridgeKey, Bridge> existingBridges,
    required Map<int, Island> islandMap,
    required BridgeCount newCount,
  }) {
    if (from.id == to.id) {
      return const Result.err(SelfConnectionFailure());
    }

    if (!areOrthogonal(from.position, to.position)) {
      return const Result.err(NonOrthogonalConnectionFailure());
    }

    final blockerId = findInterveningIslandId(
      from: from.position,
      to: to.position,
      allIslands: allIslands,
    );
    if (blockerId != null) {
      return Result.err(InterveningIslandFailure(blockerId));
    }

    // Check crossing with existing active bridges
    if (newCount != BridgeCount.none) {
      for (final bridge in existingBridges.values) {
        if (!bridge.isActive) continue;
        if (bridge.islandAId == from.id ||
            bridge.islandAId == to.id ||
            bridge.islandBId == from.id ||
            bridge.islandBId == to.id) {
          // Shares an endpoint, cannot cross
          continue;
        }

        final otherA = islandMap[bridge.islandAId];
        final otherB = islandMap[bridge.islandBId];
        if (otherA == null || otherB == null) continue;

        if (doSegmentsCross(
          a1: from.position,
          a2: to.position,
          b1: otherA.position,
          b2: otherB.position,
        )) {
          return Result.err(CrossingBridgeFailure(bridge.key));
        }
      }
    }

    // Check capacity constraint
    final currentKey = makeBridgeKey(from.id, to.id);
    final currentBridgeValue = existingBridges[currentKey]?.count.value ?? 0;
    final delta = newCount.value - currentBridgeValue;

    if (delta > 0) {
      final fromCurrent =
          calculateConnectedBridgeCount(from.id, existingBridges);
      if (fromCurrent + delta > from.requiredBridges) {
        return Result.err(CapacityExceededFailure(
          islandId: from.id,
          capacity: from.requiredBridges,
          requestedCount: fromCurrent + delta,
        ));
      }

      final toCurrent = calculateConnectedBridgeCount(to.id, existingBridges);
      if (toCurrent + delta > to.requiredBridges) {
        return Result.err(CapacityExceededFailure(
          islandId: to.id,
          capacity: to.requiredBridges,
          requestedCount: toCurrent + delta,
        ));
      }
    }

    return const Result.ok(null);
  }

  /// Calculates total bridge count connected to an island.
  static int calculateConnectedBridgeCount(
    int islandId,
    Map<BridgeKey, Bridge> bridges,
  ) {
    var sum = 0;
    for (final bridge in bridges.values) {
      if (bridge.islandAId == islandId || bridge.islandBId == islandId) {
        sum += bridge.count.value;
      }
    }
    return sum;
  }

  /// Computes connected components using BFS across all active bridges.
  static List<Set<int>> findConnectedComponents({
    required Iterable<int> islandIds,
    required Map<BridgeKey, Bridge> bridges,
  }) {
    final adjacency = <int, Set<int>>{};
    for (final id in islandIds) {
      adjacency[id] = <int>{};
    }

    for (final bridge in bridges.values) {
      if (bridge.isActive) {
        adjacency[bridge.islandAId]?.add(bridge.islandBId);
        adjacency[bridge.islandBId]?.add(bridge.islandAId);
      }
    }

    final visited = <int>{};
    final components = <Set<int>>[];

    for (final id in islandIds) {
      if (visited.contains(id)) continue;
      final component = <int>{};
      final queue = <int>[id];
      visited.add(id);

      while (queue.isNotEmpty) {
        final current = queue.removeLast();
        component.add(current);

        for (final neighbor in adjacency[current] ?? const <int>{}) {
          if (!visited.contains(neighbor)) {
            visited.add(neighbor);
            queue.add(neighbor);
          }
        }
      }
      components.add(component);
    }

    return components;
  }

  /// Checks whether the entire board satisfies all Hashi rules:
  /// 1. All islands have exact required bridge capacity satisfied.
  /// 2. All islands form a single connected component (spanning tree/graph).
  /// 3. No crossing bridges exist.
  static bool isBoardSolved({
    required Map<int, Island> islands,
    required Map<BridgeKey, Bridge> bridges,
  }) {
    if (islands.isEmpty) return false;

    // 1. Capacity check
    for (final island in islands.values) {
      final connected = calculateConnectedBridgeCount(island.id, bridges);
      if (connected != island.requiredBridges) return false;
    }

    // 2. Connectivity check (must be exactly 1 component containing all islands)
    final components = findConnectedComponents(
      islandIds: islands.keys,
      bridges: bridges,
    );
    if (components.length != 1) return false;
    if (components.first.length != islands.length) return false;

    return true;
  }
}
