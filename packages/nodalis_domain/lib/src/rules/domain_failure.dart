import 'package:meta/meta.dart';

/// Sealed hierarchy of all domain validation failures.
@immutable
sealed class DomainFailure {
  final String message;
  const DomainFailure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

final class IslandNotFoundFailure extends DomainFailure {
  final int islandId;
  const IslandNotFoundFailure(this.islandId)
      : super('Island with id $islandId not found.');
}

final class SelfConnectionFailure extends DomainFailure {
  const SelfConnectionFailure() : super('An island cannot connect to itself.');
}

final class NonOrthogonalConnectionFailure extends DomainFailure {
  const NonOrthogonalConnectionFailure()
      : super('Bridges can only be horizontal or vertical.');
}

final class InterveningIslandFailure extends DomainFailure {
  final int intermediateIslandId;
  const InterveningIslandFailure(this.intermediateIslandId)
      : super(
            'Connection blocked by intermediate island $intermediateIslandId.');
}

final class CrossingBridgeFailure extends DomainFailure {
  final ({int a, int b}) conflictingBridge;
  CrossingBridgeFailure(this.conflictingBridge)
      : super(
            'Bridge crosses existing bridge (${conflictingBridge.a} <-> ${conflictingBridge.b}).');
}

final class CapacityExceededFailure extends DomainFailure {
  final int islandId;
  final int capacity;
  final int requestedCount;
  CapacityExceededFailure({
    required this.islandId,
    required this.capacity,
    required this.requestedCount,
  }) : super(
            'Island $islandId capacity ($capacity) exceeded by requested count ($requestedCount).');
}
