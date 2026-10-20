import 'package:nodalis_domain/nodalis_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Island', () {
    test('creates valid island and checks equality', () {
      const island1 = Island(id: 1, position: (x: 2, y: 3), requiredBridges: 4);
      const island2 = Island(id: 1, position: (x: 2, y: 3), requiredBridges: 4);
      const island3 = Island(id: 2, position: (x: 2, y: 3), requiredBridges: 4);

      expect(island1, equals(island2));
      expect(island1.hashCode, equals(island2.hashCode));
      expect(island1, isNot(equals(island3)));
      expect(island1.toString(), contains('Island(id: 1'));
    });

    test('asserts positive required bridges', () {
      expect(
        () => Island(id: 1, position: (x: 0, y: 0), requiredBridges: 0),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('GridPoint extension', () {
    test('detects orthogonality accurately', () {
      const origin = (x: 2, y: 2);
      expect(origin.isOrthogonalTo((x: 2, y: 5)), isTrue);
      expect(origin.isOrthogonalTo((x: 5, y: 2)), isTrue);
      expect(origin.isOrthogonalTo((x: 2, y: 2)), isFalse); // Same point
      expect(origin.isOrthogonalTo((x: 3, y: 3)), isFalse); // Diagonal
    });

    test('computes manhattan distance', () {
      const p1 = (x: 1, y: 2);
      const p2 = (x: 4, y: 6);
      expect(p1.manhattanDistanceTo(p2), equals(7));
    });
  });

  group('Bridge', () {
    test('normalizes endpoint IDs so islandAId < islandBId', () {
      final b1 = Bridge(islandAId: 5, islandBId: 2, count: BridgeCount.single);
      expect(b1.islandAId, equals(2));
      expect(b1.islandBId, equals(5));
      expect(b1.isActive, isTrue);
    });

    test('cycles bridge count correctly', () {
      expect(BridgeCount.none.next, equals(BridgeCount.single));
      expect(BridgeCount.single.next, equals(BridgeCount.double));
      expect(BridgeCount.double.next, equals(BridgeCount.none));
    });
  });
}
