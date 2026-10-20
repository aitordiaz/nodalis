import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodalis_app/main.dart';

void main() {
  group('GameplayScreen Full Loop', () {
    testWidgets('plays and solves introductory level end-to-end',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));

      await tester.pumpWidget(const NodalisApp());
      await tester.pumpAndSettle();

      // Verify header renders
      expect(find.text('Chapter 1'), findsOneWidget);
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('Moves: 0'), findsOneWidget);

      // Verify Undo button renders
      expect(find.text('Undo'), findsOneWidget);
      expect(find.byIcon(Icons.undo_rounded), findsOneWidget);

      // Tap on Island 1 to select it
      await tester.tap(
        find.bySemanticsLabel(RegExp(r'Island at row 3, column 2\.')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // Tap on Island 2 to connect
      await tester.tap(
        find.bySemanticsLabel(RegExp(r'Island at row 3, column 4\.')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // Moves incremented to 1
      expect(find.text('Moves: 1'), findsOneWidget);

      // Level Solved dialog should appear
      expect(find.text('Level Solved'), findsOneWidget);
      expect(find.text('Completed in 1 moves.'), findsOneWidget);

      // Tap Replay button
      await tester.tap(find.text('Replay'));
      await tester.pumpAndSettle();

      // Dialog dismissed, board reset
      expect(find.text('Level Solved'), findsNothing);
      expect(find.text('Moves: 2'), findsOneWidget); // reset recorded
    });
  });
}
