import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_postframe_popups_example/content/pointer_event_details.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(PointerEvent? event) => MaterialApp(
  home: Scaffold(body: PointerEventDetails(event: event)),
);

void main() {
  testWidgets('inspector shows a prompt before the first event', (
    tester,
  ) async {
    await tester.pumpWidget(_host(null));
    expect(find.text('Tap anywhere'), findsOneWidget);
  });

  testWidgets(
    'inspector labels event properties and preserves compound values',
    (tester) async {
      await tester.pumpWidget(
        _host(
          const PointerScrollEvent(
            position: Offset(100, 150),
            scrollDelta: Offset(2, 3),
          ),
        ),
      );
      expect(find.text('PointerScrollEvent'), findsOneWidget);
      expect(find.text('position'), findsOneWidget);
      expect(find.text('scrollDelta'), findsOneWidget);
      expect(find.text('Offset(100.0, 150.0)'), findsWidgets);
      expect(find.text('Offset(2.0, 3.0)'), findsOneWidget);
      expect(find.byType(SelectableText), findsWidgets);
    },
  );

  testWidgets('inspector scrolls on a narrow viewport without overflowing', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      _host(
        const PointerMoveEvent(position: Offset(100, 150), delta: Offset(2, 3)),
      ),
    );
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
