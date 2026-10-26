import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'captures events outside subtree without blocking buttons or scrolling',
    (tester) async {
      final events = <PointerEvent>[];
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ObservedGestures(
                  onPointerEvent: (_, event) => events.add(event),
                  child: const SizedBox(width: 10, height: 10),
                ),
                FilledButton(
                  onPressed: () => taps++,
                  child: const Text('Outside'),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: 100,
                    itemBuilder: (_, index) =>
                        SizedBox(height: 60, child: Text('Item $index')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Outside'));
      await tester.pump();
      expect(taps, 1);
      expect(events.whereType<PointerDownEvent>(), hasLength(1));
      expect(events.whereType<PointerUpEvent>(), hasLength(1));
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(0));
      expect(events.whereType<PointerMoveEvent>(), isNotEmpty);
    },
  );

  testWidgets(
    'injected router preserves original events, updates, and unregisters',
    (tester) async {
      final router = PointerRouter();
      final first = <PointerEvent>[];
      final second = <PointerEvent>[];
      const event = PointerHoverEvent(position: Offset(200, 300), viewId: 42);
      Widget screen(List<PointerEvent> events) => ObservedGestures(
        pointerRouter: router,
        onPointerEvent: (_, event) => events.add(event),
        child: const SizedBox(),
      );
      await tester.pumpWidget(screen(first));
      router.route(event);
      expect(first, [same(event)]);
      expect(first.single.viewId, 42);
      await tester.pumpWidget(screen(second));
      router.route(event);
      expect(second, [same(event)]);
      await tester.pumpWidget(const SizedBox());
      router.route(event);
      expect(first, hasLength(1));
      expect(second, hasLength(1));
    },
  );

  testWidgets('raw pointer observation does not prevent text input focus', (
    tester,
  ) async {
    final events = <PointerEvent>[];
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ObservedGestures(
            onPointerEvent: (_, event) => events.add(event),
            child: TextField(controller: controller),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'unchanged input');
    expect(controller.text, 'unchanged input');
    expect(events.whereType<PointerDownEvent>(), hasLength(1));
  });

  for (final asynchronous in [false, true]) {
    testWidgets('pointer callback failures are observed: async=$asynchronous', (
      tester,
    ) async {
      final router = PointerRouter();
      final errors = <Object>[];
      final error = StateError('pointer');
      Future<void> failLater(BuildContext _, PointerEvent _) async {
        await Future<void>.value();
        throw error;
      }

      await tester.pumpWidget(
        ObservedGestures(
          pointerRouter: router,
          onPointerEvent: asynchronous ? failLater : (_, event) => throw error,
          onError: (error, _) => errors.add(error),
          child: const SizedBox(),
        ),
      );
      router.route(const PointerDownEvent());
      await tester.pump();
      expect(errors, [same(error)]);
    });
  }

  testWidgets(
    'pointer future failures survive disposal and callback replacement',
    (tester) async {
      final router = PointerRouter();
      final completion = Completer<void>();
      final errors = <Object>[];
      final error = StateError('late pointer');
      await tester.pumpWidget(
        ObservedGestures(
          pointerRouter: router,
          onPointerEvent: (_, event) => completion.future,
          onError: (error, _) => errors.add(error),
          child: const SizedBox(),
        ),
      );
      router.route(const PointerDownEvent());
      await tester.pumpWidget(const SizedBox());
      completion.completeError(error, StackTrace.current);
      await tester.pump();
      expect(errors, [same(error)]);
    },
  );
}
