import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Presentation { dialog, bottomSheet }

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

Widget _prompt(
  _Presentation kind, {
  Key? key,
  Widget? content,
  Widget child = const Text('Underlying screen'),
  CustomShowDialog<int>? presenter,
  FutureOr<void> Function(BuildContext context, int? result)? onResult,
  PostFrameErrorHandler? onError,
}) {
  final modal = content ?? _ChoiceContent(kind: kind);

  return switch (kind) {
    _Presentation.dialog => PostFrameDialog<int>(
      key: key,
      dialog: modal,
      customShowDialog: presenter,
      onResult: onResult,
      onError: onError,
      child: child,
    ),
    _Presentation.bottomSheet => PostFrameBottomSheet<int>(
      key: key,
      bottomSheet: modal,
      customShowBottomSheet: presenter,
      onResult: onResult,
      onError: onError,
      child: child,
    ),
  };
}

class _ChoiceContent extends StatelessWidget {
  const _ChoiceContent({required this.kind});

  final _Presentation kind;

  @override
  Widget build(BuildContext context) {
    final choose = TextButton(
      onPressed: () => Navigator.of(context).pop(42),
      child: const Text('Choose'),
    );

    return switch (kind) {
      _Presentation.dialog => AlertDialog(actions: [choose]),
      _Presentation.bottomSheet => SizedBox(
        height: 160,
        child: Center(child: choose),
      ),
    };
  }
}

class _CounterChild extends StatefulWidget {
  const _CounterChild();

  @override
  State<_CounterChild> createState() => _CounterChildState();
}

class _CounterChildState extends State<_CounterChild> {
  int _count = 0;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => setState(() => _count++),
    child: Text('Child count: $_count'),
  );
}

class _ThrowingContent extends StatelessWidget {
  const _ThrowingContent(this.error);

  final StateError error;

  @override
  Widget build(BuildContext context) => throw error;
}

void main() {
  for (final kind in _Presentation.values) {
    group(kind.name, () {
      testWidgets('default presenter returns a typed result without replay', (
        tester,
      ) async {
        final results = <int?>[];
        Widget screen() =>
            _host(_prompt(kind, onResult: (_, result) => results.add(result)));
        await tester.pumpWidget(screen());
        await tester.pumpAndSettle();
        expect(find.text('Underlying screen'), findsOneWidget);
        await tester.tap(find.text('Choose'));
        await tester.pumpAndSettle();
        await tester.pumpWidget(screen());
        expect(results, [42]);
        expect(find.text('Choose'), findsNothing);
        expect(find.text('Underlying screen'), findsOneWidget);
      });

      testWidgets('screen child retains state across results and rebuilds', (
        tester,
      ) async {
        var calls = 0;
        Widget screen() => _host(
          _prompt(
            kind,
            presenter: ({required context, required builder}) => ++calls,
            child: const _CounterChild(),
          ),
        );
        await tester.pumpWidget(screen());
        await tester.pump();
        await tester.tap(find.text('Child count: 0'));
        await tester.pump();
        await tester.pumpWidget(screen());
        expect(find.text('Child count: 1'), findsOneWidget);
        expect(calls, 1);
      });

      testWidgets('barrier dismissal delivers null', (tester) async {
        final results = <int?>[];
        await tester.pumpWidget(
          _host(_prompt(kind, onResult: (_, value) => results.add(value))),
        );
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
        expect(results, [null]);
        expect(find.text('Choose'), findsNothing);
      });

      testWidgets(
        'sync presenter runs after child layout with separate content',
        (tester) async {
          final childKey = GlobalKey();
          const content = Text('Modal content');
          var calls = 0;
          final results = <int?>[];
          int present({
            required BuildContext context,
            required WidgetBuilder builder,
          }) {
            expect(context.mounted, isTrue);
            expect(ModalRoute.of(context), isA<PageRoute<Object?>>());
            expect(childKey.currentContext!.size, const Size(20, 20));
            expect(builder(context), same(content));
            calls++;

            return 7;
          }

          await tester.pumpWidget(
            _host(
              _prompt(
                kind,
                presenter: present,
                content: content,
                onResult: (context, result) {
                  expect(context.mounted, isTrue);
                  results.add(result);
                },
                child: SizedBox(key: childKey, width: 20, height: 20),
              ),
            ),
          );
          await tester.pump();
          expect(calls, 1);
          expect(results, [7]);
          expect(find.text('Modal content'), findsNothing);
        },
      );

      testWidgets('async presenter waits for its result', (tester) async {
        final completion = Completer<int?>();
        final results = <int?>[];
        await tester.pumpWidget(
          _host(
            _prompt(
              kind,
              presenter: ({required context, required builder}) =>
                  completion.future,
              onResult: (_, result) => results.add(result),
            ),
          ),
        );
        expect(results, isEmpty);
        completion.complete(11);
        await tester.pump();
        expect(results, [11]);
      });

      for (final asynchronous in [false, true]) {
        testWidgets('reports presenter failure, async=$asynchronous', (
          tester,
        ) async {
          final error = StateError('Presenter failed');
          final stack = StackTrace.current;
          final completion = Completer<int?>();
          final errors = <Object>[];
          FutureOr<int?> present({
            required BuildContext context,
            required WidgetBuilder builder,
          }) {
            expect(context.mounted, isTrue);
            expect(builder(context), isA<_ChoiceContent>());
            if (asynchronous) {
              return completion.future;
            }
            Error.throwWithStackTrace(error, stack);
          }

          await tester.pumpWidget(
            _host(
              _prompt(
                kind,
                presenter: present,
                onResult: (_, _) => fail('Failure must not deliver a result'),
                onError: (caught, trace) {
                  expect(trace.toString(), stack.toString());
                  errors.add(caught);
                },
              ),
            ),
          );
          if (asynchronous) {
            completion.completeError(error, stack);
          }
          await tester.pump();
          expect(errors, [same(error)]);
          expect(tester.takeException(), isNull);
        });

        testWidgets('awaits result-handler failures, async=$asynchronous', (
          tester,
        ) async {
          final error = StateError('Result handler failed');
          final errors = <Object>[];
          FutureOr<void> handleResult(BuildContext context, int? result) {
            expect(context.mounted, isTrue);
            expect(result, 7);
            if (asynchronous) {
              return Future<void>.error(error, StackTrace.current);
            }
            throw error;
          }

          await tester.pumpWidget(
            _host(
              _prompt(
                kind,
                presenter: ({required context, required builder}) => 7,
                onResult: handleResult,
                onError: (caught, _) => errors.add(caught),
              ),
            ),
          );
          await tester.pump();
          expect(errors, [same(error)]);
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('missing onError reports through FlutterError', (
        tester,
      ) async {
        final error = StateError('Unhandled presenter failure');
        await tester.pumpWidget(
          _host(
            _prompt(
              kind,
              presenter: ({required context, required builder}) => throw error,
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), same(error));
        expect(tester.takeException(), isNull);
      });

      testWidgets('completion after disposal skips the result callback', (
        tester,
      ) async {
        final completion = Completer<int?>();
        await tester.pumpWidget(
          _host(
            _prompt(
              kind,
              presenter: ({required context, required builder}) =>
                  completion.future,
              onResult: (_, _) => fail('Disposed wrapper delivered a result'),
            ),
          ),
        );
        await tester.pumpWidget(const SizedBox());
        completion.complete(5);
        await tester.pump();
        expect(tester.takeException(), isNull);
      });

      testWidgets('failure after disposal still reports', (tester) async {
        final completion = Completer<int?>();
        final errors = <Object>[];
        final error = StateError('Late presenter failure');
        await tester.pumpWidget(
          _host(
            _prompt(
              kind,
              presenter: ({required context, required builder}) =>
                  completion.future,
              onError: (caught, _) => errors.add(caught),
            ),
          ),
        );
        await tester.pumpWidget(const SizedBox());
        completion.completeError(error, StackTrace.current);
        await tester.pump();
        expect(errors, [same(error)]);
      });

      testWidgets('removing the wrapper leaves its open route intact', (
        tester,
      ) async {
        late StateSetter rebuild;
        var visible = true;
        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (_, setState) {
                rebuild = setState;

                return visible
                    ? _prompt(
                        kind,
                        onResult: (_, _) =>
                            fail('Disposed wrapper ran onResult'),
                      )
                    : const Text('Wrapper removed');
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        rebuild(() => visible = false);
        await tester.pump();
        expect(find.text('Choose'), findsOneWidget);
        await tester.tap(find.text('Choose'));
        await tester.pumpAndSettle();
        expect(find.text('Wrapper removed'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('a new key starts a new presentation', (tester) async {
        var calls = 0;
        for (var index = 0; index < 2; index++) {
          await tester.pumpWidget(
            _host(
              _prompt(
                kind,
                key: ValueKey(index),
                presenter: ({required context, required builder}) => ++calls,
              ),
            ),
          );
        }
        expect(calls, 2);
      });

      testWidgets('in-flight presentation keeps its original result handler', (
        tester,
      ) async {
        final completion = Completer<int?>();
        final results = <int?>[];
        await tester.pumpWidget(
          _host(
            _prompt(
              kind,
              presenter: ({required context, required builder}) =>
                  completion.future,
              onResult: (_, result) => results.add(result),
            ),
          ),
        );
        await tester.pumpWidget(
          _host(
            _prompt(
              kind,
              presenter: ({required context, required builder}) =>
                  fail('Rebuild must not start a second presentation'),
              onResult: (_, _) => fail('In-flight handler was replaced'),
            ),
          ),
        );
        completion.complete(9);
        await tester.pump();
        expect(results, [9]);
      });

      for (final custom in [false, true]) {
        testWidgets('nested Navigator and barrier behavior, custom=$custom', (
          tester,
        ) async {
          final rootKey = GlobalKey<NavigatorState>();
          final nestedKey = GlobalKey<NavigatorState>();
          final results = <int?>[];
          Future<int?> present({
            required BuildContext context,
            required WidgetBuilder builder,
          }) => switch (kind) {
            _Presentation.dialog => showDialog<int>(
              context: context,
              builder: builder,
              useRootNavigator: false,
              barrierDismissible: false,
            ),
            _Presentation.bottomSheet => showModalBottomSheet<int>(
              context: context,
              builder: builder,
              useRootNavigator: true,
              isDismissible: false,
              enableDrag: false,
            ),
          };

          await tester.pumpWidget(
            MaterialApp(
              navigatorKey: rootKey,
              home: Navigator(
                key: nestedKey,
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    body: _prompt(
                      kind,
                      presenter: custom ? present : null,
                      onResult: (_, result) => results.add(result),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final usesRoot = (kind == _Presentation.dialog) != custom;
          expect(rootKey.currentState!.canPop(), usesRoot);
          expect(nestedKey.currentState!.canPop(), !usesRoot);
          if (custom) {
            await tester.tapAt(const Offset(5, 5));
            await tester.pumpAndSettle();
            expect(results, isEmpty);
            expect(find.text('Choose'), findsOneWidget);
          }
          await tester.tap(find.text('Choose'));
          await tester.pumpAndSettle();
          expect(results, [42]);
        });
      }

      testWidgets('content build errors use Flutter framework handling', (
        tester,
      ) async {
        final error = StateError('Content build failed');
        await tester.pumpWidget(
          _host(
            _prompt(
              kind,
              content: _ThrowingContent(error),
              onError: (_, _) => fail('Build error reached presenter onError'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), same(error));
        await tester.pumpWidget(const SizedBox());
      });
    });
  }
}
