import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'builder starts with current state; changes arrive without a frame',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final changes = <AppLifecycleState>[];
      final built = <AppLifecycleState?>[];
      await tester.pumpWidget(
        ObservedAppLifecycle(
          binding: tester.binding,
          onStateChanged: (context, state) {
            expect(context.mounted, isTrue);
            changes.add(state);
          },
          builder: (_, state, child) {
            built.add(state);

            return child;
          },
          child: const SizedBox(),
        ),
      );
      expect(built, [AppLifecycleState.resumed]);
      expect(changes, isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      expect(changes, [AppLifecycleState.inactive]);
      await tester.pump();
      expect(built.last, AppLifecycleState.inactive);
      await tester.pumpWidget(const SizedBox());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(changes, hasLength(1));
    },
  );

  testWidgets(
    'covers complete OS cycle, suppresses repeats, uses latest callback',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final states = <AppLifecycleState>[];
      final latest = <AppLifecycleState>[];
      Widget screen(List<AppLifecycleState> changes) => ObservedAppLifecycle(
        onStateChanged: (_, state) => changes.add(state),
        child: const SizedBox(),
      );
      await tester.pumpWidget(screen(states));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpWidget(screen(latest));
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      expect(states, [AppLifecycleState.inactive]);
      expect(latest, [
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final asynchronous in [false, true]) {
    testWidgets('lifecycle errors use shared handler: async=$asynchronous', (
      tester,
    ) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final errors = <Object>[];
      final error = StateError('lifecycle');
      Future<void> failLater(BuildContext _, AppLifecycleState _) async {
        await Future<void>.value();
        throw error;
      }

      await tester.pumpWidget(
        ObservedAppLifecycle(
          onStateChanged: asynchronous ? failLater : (_, state) => throw error,
          onError: (error, _) => errors.add(error),
          child: const SizedBox(),
        ),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(errors, [same(error)]);
      await tester.pumpWidget(const SizedBox());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
  }

  testWidgets('lifecycle failure after disposal retains original handler', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final completion = Completer<void>();
    final errors = <Object>[];
    final error = StateError('late lifecycle');
    await tester.pumpWidget(
      ObservedAppLifecycle(
        onStateChanged: (_, state) => completion.future,
        onError: (error, _) => errors.add(error),
        child: const SizedBox(),
      ),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpWidget(const SizedBox());
    completion.completeError(error, StackTrace.current);
    await tester.pump();
    expect(errors, [same(error)]);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
}
