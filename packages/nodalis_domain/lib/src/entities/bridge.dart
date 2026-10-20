import 'package:meta/meta.dart';

/// Number of parallel bridges connecting two islands.
enum BridgeCount {
  none(0),
  single(1),
  double(2);

  final int value;
  const BridgeCount(this.value);

  /// Returns the next bridge count in the normal cycle (none -> single -> double -> none).
  BridgeCount get next => switch (this) {
        BridgeCount.none => BridgeCount.single,
        BridgeCount.single => BridgeCount.double,
        BridgeCount.double => BridgeCount.none,
      };
}

/// Normalized canonical key for an undirected bridge between two island IDs.
typedef BridgeKey = ({int a, int b});

/// Helper to produce a normalized key where `a < b`.
BridgeKey makeBridgeKey(int id1, int id2) {
  assert(id1 != id2, 'An island cannot connect to itself.');
  return id1 < id2 ? (a: id1, b: id2) : (a: id2, b: id1);
}

/// Represents an immutable bridge between two islands.
@immutable
final class Bridge {
  final int islandAId;
  final int islandBId;
  final BridgeCount count;

  Bridge({
    required int islandAId,
    required int islandBId,
    required this.count,
  })  : assert(islandAId != islandBId, 'An island cannot connect to itself.'),
        islandAId = islandAId < islandBId ? islandAId : islandBId,
        islandBId = islandAId < islandBId ? islandBId : islandAId;

  BridgeKey get key => (a: islandAId, b: islandBId);

  bool get isActive => count != BridgeCount.none;

  Bridge copyWith({BridgeCount? count}) => Bridge(
        islandAId: islandAId,
        islandBId: islandBId,
        count: count ?? this.count,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bridge &&
          runtimeType == other.runtimeType &&
          islandAId == other.islandAId &&
          islandBId == other.islandBId &&
          count == other.count;

  @override
  int get hashCode => Object.hash(islandAId, islandBId, count);

  @override
  String toString() =>
      'Bridge($islandAId <-> $islandBId, count: ${count.name})';
}
