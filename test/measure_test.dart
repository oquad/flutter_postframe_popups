import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'builder gets null then exact child size without growing a loop',
    (tester) async {
      final sizes = <Size>[];
      var builds = 0;
      final targetKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: PostFrameSize(
              child: SizedBox(key: targetKey, width: 100.5, height: 60.25),
              onMeasured: (context, size) {
                expect(context.mounted, isTrue);
                expect(
                  tester.binding.schedulerPhase,
                  SchedulerPhase.postFrameCallbacks,
                );
                sizes.add(size);
              },
              builder: (context, size, child) {
                builds++;

                return Stack(
                  children: [
                    child,
                    Positioned(
                      top: 0,
                      child: Text(size == null ? 'pending' : '$size'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      expect(find.text('pending'), findsOneWidget);
      expect(sizes, [const Size(100.5, 60.25)]);
      await tester.pumpAndSettle();
      expect(builds, 2);
      expect(sizes, hasLength(1));
      expect(tester.getSize(find.byKey(targetKey)), sizes.single);
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets(
    'callback observes first layout, resize, zero size, and latest callback',
    (tester) async {
      final sizes = <Size>[];
      final latest = <Size>[];
      Widget screen(double width, PostFrameSizeCallback callback) => Center(
        child: PostFrameSize(
          onMeasured: callback,
          child: SizedBox(width: width, height: 20),
        ),
      );
      await tester.pumpWidget(screen(40, (_, size) => sizes.add(size)));
      await tester.pump();
      expect(sizes, [const Size(40, 20)]);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(screen(40, (_, size) => latest.add(size)));
      expect(latest, isEmpty);
      await tester.pumpWidget(screen(80, (_, size) => latest.add(size)));
      await tester.pumpWidget(screen(0, (_, size) => latest.add(size)));
      expect(latest, [const Size(80, 20), const Size(0, 20)]);
    },
  );

  testWidgets('coalesces multiple layouts to the final size of one frame', (
    tester,
  ) async {
    final sizes = <Size>[];
    await tester.pumpWidget(
      Center(
        child: _LayoutTwice(
          child: PostFrameSize(
            onMeasured: (_, size) => sizes.add(size),
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
      ),
    );
    expect(sizes, [const Size(60, 40)]);
  });

  testWidgets(
    'paint overflow and transforms do not change the layout measurement',
    (tester) async {
      final sizes = <Size>[];
      await tester.pumpWidget(
        Center(
          child: Transform.scale(
            scale: 2,
            child: PostFrameSize(
              onMeasured: (_, size) => sizes.add(size),
              child: const SizedBox(
                width: 40,
                height: 30,
                child: OverflowBox(
                  minWidth: 80,
                  maxWidth: 80,
                  minHeight: 60,
                  maxHeight: 60,
                  child: SizedBox(width: 80, height: 60),
                ),
              ),
            ),
          ),
        ),
      );
      expect(sizes, [const Size(40, 30)]);
    },
  );

  for (final asynchronous in [false, true]) {
    testWidgets('measurement handles callback failures: async=$asynchronous', (
      tester,
    ) async {
      final errors = <Object>[];
      final error = StateError('measurement');
      Future<void> failLater(BuildContext _, Size _) async {
        await Future<void>.value();
        throw error;
      }

      await tester.pumpWidget(
        Center(
          child: PostFrameSize(
            onMeasured: asynchronous ? failLater : (_, size) => throw error,
            onError: (error, _) => errors.add(error),
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
      );
      await tester.pump();
      expect(errors, [same(error)]);
    });
  }

  testWidgets('in-flight measurement retains its handler after disposal', (
    tester,
  ) async {
    final completer = Completer<void>();
    final errors = <Object>[];
    final error = StateError('late measurement');
    await tester.pumpWidget(
      PostFrameSize(
        onMeasured: (_, size) => completer.future,
        onError: (error, _) => errors.add(error),
        child: const SizedBox(),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    completer.completeError(error, StackTrace.current);
    await tester.pump();
    expect(errors, [same(error)]);
  });
}

class _LayoutTwice extends SingleChildRenderObjectWidget {
  const _LayoutTwice({required super.child});

  @override
  _RenderLayoutTwice createRenderObject(BuildContext context) =>
      _RenderLayoutTwice();
}

class _RenderLayoutTwice extends RenderProxyBox {
  @override
  void performLayout() {
    child!.layout(constraints.loosen(), parentUsesSize: true);
    child!.layout(
      const BoxConstraints.tightFor(width: 60, height: 40),
      parentUsesSize: true,
    );
    size = child!.size;
  }
}
