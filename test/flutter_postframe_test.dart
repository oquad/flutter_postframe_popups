import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets(
    'default scheduler runs after child layout, once across rebuilds',
    (tester) async {
      var calls = 0;
      final childKey = GlobalKey();
      Widget screen() => host(
        PostFrameCallback(
          callback: (context) {
            expect(context.mounted, isTrue);
            expect(childKey.currentContext!.size, const Size(20, 20));
            calls++;
          },
          child: SizedBox(key: childKey, width: 20, height: 20),
        ),
      );
      await tester.pumpWidget(screen());
      expect(calls, 1);
      await tester.pumpWidget(screen());
      await tester.pump();
      expect(calls, 1);
    },
  );

  testWidgets('scheduler injection and latest callback before start', (
    tester,
  ) async {
    VoidCallback? pending;
    var calls = 0;
    void schedule(VoidCallback callback) => pending = callback;
    await tester.pumpWidget(
      PostFrameCallback(
        scheduler: schedule,
        callback: (_) {
          calls += 1;
        },
        child: const SizedBox(),
      ),
    );
    expect(calls, 0);
    await tester.pumpWidget(
      PostFrameCallback(
        scheduler: schedule,
        callback: (_) {
          calls += 10;
        },
        child: const SizedBox(),
      ),
    );
    pending!();
    pending!();
    await tester.pump();
    expect(calls, 10);
  });

  testWidgets('disposal before execution skips callback', (tester) async {
    VoidCallback? pending;
    await tester.pumpWidget(
      PostFrameCallback(
        scheduler: (callback) => pending = callback,
        callback: (_) => fail('Disposed callback ran'),
        child: const SizedBox(),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    pending!();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('new key creates another lifecycle', (tester) async {
    var calls = 0;
    for (var i = 0; i < 2; i++) {
      await tester.pumpWidget(
        PostFrameCallback(
          key: ValueKey(i),
          callback: (_) {
            calls++;
          },
          child: const SizedBox(),
        ),
      );
    }
    expect(calls, 2);
  });

  for (final asynchronous in [false, true]) {
    testWidgets(
      'onError catches ${asynchronous ? 'async' : 'sync'} failure once',
      (tester) async {
        final error = StateError('action failed');
        final errors = <Object>[];
        Future<void> failLater(BuildContext _) async {
          await Future<void>.value();
          throw error;
        }

        await tester.pumpWidget(
          PostFrameCallback(
            callback: asynchronous ? failLater : (_) => throw error,
            onError: (e, stack) {
              expect(stack.toString(), isNotEmpty);
              errors.add(e);
            },
            child: const SizedBox(),
          ),
        );
        await tester.pump();
        expect(errors, [same(error)]);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('default policy reports async error through FlutterError', (
    tester,
  ) async {
    final error = StateError('reported');
    await tester.pumpWidget(
      PostFrameCallback(
        callback: (_) async {
          await Future<void>.value();
          throw error;
        },
        child: const SizedBox(),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), same(error));
    expect(tester.takeException(), isNull);
  });

  testWidgets('handler failure reports both errors with stacks', (
    tester,
  ) async {
    final originalHandler = FlutterError.onError;
    final reports = <FlutterErrorDetails>[];
    FlutterError.onError = reports.add;
    addTearDown(() => FlutterError.onError = originalHandler);
    final originalError = StateError('original');
    final handlerError = StateError('handler');
    await tester.pumpWidget(
      PostFrameCallback(
        callback: (_) => throw originalError,
        onError: (_, _) => throw handlerError,
        child: const SizedBox(),
      ),
    );
    await tester.pump();
    expect(reports.map((e) => e.exception), [originalError, handlerError]);
    expect(
      reports.every(
        (e) => e.stack != null && e.library == 'flutter_postframe_popups',
      ),
      isTrue,
    );
  });

  testWidgets('started future error still reports after disposal', (
    tester,
  ) async {
    final completion = Completer<void>();
    final errors = <Object>[];
    final error = StateError('late failure');
    await tester.pumpWidget(
      PostFrameCallback(
        callback: (_) => completion.future,
        onError: (e, _) => errors.add(e),
        child: const SizedBox(),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    completion.completeError(error, StackTrace.current);
    await tester.pump();
    expect(errors, [error]);
  });
}
