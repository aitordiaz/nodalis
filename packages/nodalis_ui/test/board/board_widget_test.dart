import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodalis_domain/nodalis_domain.dart';
import 'package:nodalis_ui/nodalis_ui.dart';

void main() {
  group('BoardWidget & Accessibility', () {
    late Board testBoard;

    setUp(() {
      testBoard = Board.initial(
        width: 5,
        height: 5,
        islands: [
          const Island(id: 1, position: (x: 1, y: 1), requiredBridges: 2),
          const Island(id: 2, position: (x: 3, y: 1), requiredBridges: 2),
        ],
      );
    });

    testWidgets('renders BoardWidget and exposes accessible semantics nodes',
        (tester) async {
      final handle = tester.ensureSemantics();

      var viewModel = BoardViewModel(board: testBoard);
      var connectFired = false;
      int? connectedFrom;
      int? connectedTo;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: NodalisTheme(
            data: NodalisThemeData.light,
            child: SizedBox(
              width: 400,
              height: 400,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return BoardWidget(
                    viewModel: viewModel,
                    onViewModelChanged: (newVm) {
                      setState(() {
                        viewModel = newVm;
                      });
                    },
                    onConnect: (from, to) {
                      connectFired = true;
                      connectedFrom = from;
                      connectedTo = to;
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Verify Semantics exist for Island 1 and Island 2
      expect(
        find.bySemanticsLabel(
            RegExp(r'Island at row 2, column 2\. Capacity 2\.')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
            RegExp(r'Island at row 2, column 4\. Capacity 2\.')),
        findsOneWidget,
      );

      // Tap on Island 1 to select
      await tester.tap(
        find.bySemanticsLabel(RegExp(r'Island at row 2, column 2\.')),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(viewModel.selectedIslandId, equals(1));

      // Tap on Island 2 to connect
      await tester.tap(
        find.bySemanticsLabel(RegExp(r'Island at row 2, column 4\.')),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(connectFired, isTrue);
      expect(connectedFrom, equals(1));
      expect(connectedTo, equals(2));

      handle.dispose();
    });
  });
}
