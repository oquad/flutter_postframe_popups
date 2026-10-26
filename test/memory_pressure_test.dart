import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'subscribes once, uses latest callback, removes observer on disposal',
    (tester) async {
      var calls = 0;
      Widget screen(int increment) => ObservedMemoryPressure(
        binding: tester.binding,
        onMemoryPressure: (context) {
          expect(context.mounted, isTrue);
          calls += increment;
        },
        child: const SizedBox(),
      );
      await tester.pumpWidget(screen(1));
      expect(calls, 0);
      tester.binding.handleMemoryPressure();
      expect(calls, 1);
      await tester.pumpWidget(screen(10));
      tester.binding.handleMemoryPressure();
      expect(calls, 11);
      await tester.pumpWidget(const SizedBox());
      tester.binding.handleMemoryPressure();
      expect(calls, 11);
    },
  );

  testWidgets('coalesces overlapping cleanup and accepts later notifications', (
    tester,
  ) async {
    var calls = 0;
    final completion = Completer<void>();
    await tester.pumpWidget(
      ObservedMemoryPressure(
        onMemoryPressure: (_) {
          calls++;

          return completion.future;
        },
        child: const SizedBox(),
      ),
    );
    tester.binding.handleMemoryPressure();
    tester.binding.handleMemoryPressure();
    expect(calls, 1);
    completion.complete();
    await tester.pump();
    tester.binding.handleMemoryPressure();
    await tester.pump();
    expect(calls, 2);
  });

  for (final asynchronous in [false, true]) {
    testWidgets('cleanup errors recover: async=$asynchronous', (tester) async {
      final errors = <Object>[];
      final error = StateError('cleanup');
      Future<void> failLater(BuildContext _) async {
        await Future<void>.value();
        throw error;
      }

      await tester.pumpWidget(
        ObservedMemoryPressure(
          onMemoryPressure: asynchronous ? failLater : (_) => throw error,
          onError: (error, _) => errors.add(error),
          child: const SizedBox(),
        ),
      );
      tester.binding.handleMemoryPressure();
      await tester.pump();
      tester.binding.handleMemoryPressure();
      await tester.pump();
      expect(errors, [same(error), same(error)]);
    });
  }

  testWidgets('cleanup failure after disposal keeps original error handler', (
    tester,
  ) async {
    final completion = Completer<void>();
    final errors = <Object>[];
    final error = StateError('late cleanup');
    await tester.pumpWidget(
      ObservedMemoryPressure(
        onMemoryPressure: (_) => completion.future,
        onError: (error, _) => errors.add(error),
        child: const SizedBox(),
      ),
    );
    tester.binding.handleMemoryPressure();
    await tester.pumpWidget(const SizedBox());
    completion.completeError(error, StackTrace.current);
    await tester.pump();
    expect(errors, [same(error)]);
  });

  testWidgets('missing onError reports cleanup failure through FlutterError', (
    tester,
  ) async {
    final error = StateError('reported cleanup');
    await tester.pumpWidget(
      ObservedMemoryPressure(
        onMemoryPressure: (_) => throw error,
        child: const SizedBox(),
      ),
    );
    tester.binding.handleMemoryPressure();
    await tester.pump();
    expect(tester.takeException(), same(error));
  });
}
