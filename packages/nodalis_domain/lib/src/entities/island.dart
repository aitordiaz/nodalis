import 'package:meta/meta.dart';
import 'coordinate.dart';

/// Represents an immutable Island on the puzzle board.
@immutable
final class Island {
  final int id;
  final GridPoint position;
  final int requiredBridges;

  const Island({
    required this.id,
    required this.position,
    required this.requiredBridges,
  }) : assert(
            requiredBridges > 0, 'Island capacity must be greater than zero.');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Island &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          position == other.position &&
          requiredBridges == other.requiredBridges;

  @override
  int get hashCode => Object.hash(id, position, requiredBridges);

  @override
  String toString() =>
      'Island(id: $id, pos: (${position.x}, ${position.y}), req: $requiredBridges)';
}
