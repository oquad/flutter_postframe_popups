import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scrollHost(Widget child, ScrollController controller) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 200,
        height: 200,
        child: SingleChildScrollView(
          controller: controller,
          child: Column(
            children: [
              const SizedBox(height: 250),
              SizedBox(width: 100, height: 100, child: child),
              const SizedBox(height: 300),
            ],
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('zero triggers after initial frame even for offscreen content', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var calls = 0;
    await tester.pumpWidget(
      _scrollHost(
        PostFrameCallback(
          callback: (_) {
            expect(
              tester.binding.schedulerPhase,
              SchedulerPhase.postFrameCallbacks,
            );
            calls++;
          },
          child: const Text('Offscreen'),
        ),
        controller,
      ),
    );
    expect(calls, 1);
  });

  for (final threshold in [0.5, 1.0]) {
    testWidgets('waits for $threshold area then fires only once', (
      tester,
    ) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var calls = 0;
      await tester.pumpWidget(
        _scrollHost(
          PostFrameCallback(
            triggerVisibleArea: threshold,
            callback: (_) {
              expect(
                tester.binding.schedulerPhase,
                SchedulerPhase.postFrameCallbacks,
              );
              calls++;
            },
            child: const ColoredBox(color: Colors.teal),
          ),
          controller,
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
      controller.jumpTo(99);
      await tester.pumpAndSettle();
      expect(calls, 0);
      controller.jumpTo(threshold == 0.5 ? 100 : 149);
      await tester.pumpAndSettle();
      expect(calls, threshold == 0.5 ? 1 : 0);
      controller.jumpTo(150);
      await tester.pumpAndSettle();
      expect(calls, 1);
      controller.jumpTo(0);
      await tester.pumpAndSettle();
      controller.jumpTo(150);
      await tester.pumpAndSettle();
      expect(calls, 1);
    });
  }

  testWidgets('fully visible target starts in its first composed frame', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      Center(
        child: PostFrameCallback(
          triggerVisibleArea: 1,
          callback: (_) => calls++,
          child: const SizedBox(width: 80, height: 60),
        ),
      ),
    );
    expect(calls, 1);
  });

  testWidgets('cached lazy-list item waits until painted in the viewport', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var built = false;
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 200,
              height: 200,
              child: ListView.builder(
                controller: controller,
                itemCount: 10,
                itemExtent: 100,
                scrollCacheExtent: const ScrollCacheExtent.pixels(400),
                itemBuilder: (_, index) {
                  if (index != 3) {
                    return const SizedBox();
                  }
                  built = true;

                  return PostFrameCallback(
                    triggerVisibleArea: 0.5,
                    callback: (_) => calls++,
                    child: const Text('Cached target'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(built, isTrue);
    expect(calls, 0);
    controller.jumpTo(150);
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('intersects nested scroll viewports', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var calls = 0;
    await tester.pumpWidget(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 200,
          height: 100,
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                const SizedBox(height: 50),
                SizedBox(
                  height: 100,
                  child: SingleChildScrollView(
                    child: SizedBox(
                      height: 100,
                      child: PostFrameCallback(
                        triggerVisibleArea: 0.75,
                        callback: (_) => calls++,
                        child: const SizedBox(width: 100, height: 100),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 200),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 0);
    controller.jumpTo(25);
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets(
    'rotated viewport uses clipped polygon area, not its bounding box',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var calls = 0;
      await tester.pumpWidget(
        Stack(
          alignment: Alignment.topLeft,
          children: [
            Positioned(
              left: 200,
              top: 80,
              child: Transform.rotate(
                angle: math.pi / 4,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 200,
                  height: 120,
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Column(
                      textDirection: TextDirection.ltr,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 90),
                        Padding(
                          padding: const EdgeInsets.only(left: 40),
                          child: PostFrameCallback(
                            triggerVisibleArea: 0.6,
                            callback: (_) => calls++,
                            child: const SizedBox(width: 100, height: 60),
                          ),
                        ),
                        const SizedBox(height: 200),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 0);
      controller.jumpTo(6);
      await tester.pumpAndSettle();
      expect(calls, 1);
    },
  );

  testWidgets('screen clipping uses logical pixels at non-unit device ratios', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1200, 1200);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    var calls = 0;
    var left = -50.0;
    late StateSetter rebuild;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (_, setState) {
          rebuild = setState;

          return Stack(
            alignment: Alignment.topLeft,
            children: [
              Positioned(
                left: left,
                top: 50,
                child: PostFrameCallback(
                  triggerVisibleArea: 0.75,
                  callback: (_) => calls++,
                  child: const SizedBox(width: 100, height: 100),
                ),
              ),
            ],
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 0);
    rebuild(() => left = -25);
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets(
    'retained repaint boundaries are observed without repainting the child',
    (tester) async {
      var calls = 0;
      var paints = 0;
      var top = 700.0;
      late StateSetter rebuild;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (_, setState) {
            rebuild = setState;

            return Stack(
              alignment: Alignment.topLeft,
              children: [
                Positioned(
                  left: 40,
                  top: top,
                  child: RepaintBoundary(
                    child: _PaintCounter(
                      onPaint: () => paints++,
                      child: PostFrameCallback(
                        triggerVisibleArea: 1,
                        callback: (_) => calls++,
                        child: const SizedBox(width: 100, height: 100),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      final initialPaints = paints;
      expect(initialPaints, greaterThan(0));
      expect(calls, 0);
      rebuild(() => top = 200);
      await tester.pumpAndSettle();
      expect(paints, initialPaints);
      expect(calls, 1);
    },
  );

  for (final hidden in ['opacity', 'offstage', 'zero size']) {
    testWidgets('positive threshold waits for $hidden target', (tester) async {
      var calls = 0;
      var show = false;
      late StateSetter rebuild;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (_, setState) {
            rebuild = setState;
            final target = PostFrameCallback(
              triggerVisibleArea: 1,
              callback: (_) => calls++,
              child: SizedBox(
                width: hidden == 'zero size' && !show ? 0 : 100,
                height: 100,
              ),
            );

            return Center(
              child: switch (hidden) {
                'opacity' => Opacity(opacity: show ? 1 : 0, child: target),
                'offstage' => Offstage(offstage: !show, child: target),
                _ => target,
              },
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 0);
      rebuild(() => show = true);
      await tester.pumpAndSettle();
      expect(calls, 1);
    });
  }

  testWidgets('threshold and callback updates take effect before execution', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var calls = 0;
    Widget screen(double threshold, int increment) => _scrollHost(
      PostFrameCallback(
        triggerVisibleArea: threshold,
        callback: (_) => calls += increment,
        child: const Text('Target'),
      ),
      controller,
    );
    await tester.pumpWidget(screen(1, 1));
    controller.jumpTo(100);
    await tester.pumpAndSettle();
    expect(calls, 0);
    await tester.pumpWidget(screen(0.5, 10));
    await tester.pumpAndSettle();
    expect(calls, 10);
    await tester.pumpWidget(screen(0, 100));
    await tester.pumpAndSettle();
    expect(calls, 10);
  });

  testWidgets(
    'changing waiting threshold to zero runs offscreen after the frame',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var calls = 0;
      Widget screen(double threshold) => _scrollHost(
        PostFrameCallback(
          triggerVisibleArea: threshold,
          callback: (_) => calls++,
          child: const Text('Target'),
        ),
        controller,
      );
      await tester.pumpWidget(screen(1));
      expect(calls, 0);
      await tester.pumpWidget(screen(0));
      expect(calls, 1);
    },
  );

  testWidgets('injected scheduler still controls a visibility-gated callback', (
    tester,
  ) async {
    VoidCallback? scheduled;
    var calls = 0;
    await tester.pumpWidget(
      Center(
        child: PostFrameCallback(
          scheduler: (callback) => scheduled = callback,
          triggerVisibleArea: 1,
          callback: (_) => calls++,
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );
    expect(calls, 0);
    scheduled!();
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('waiting subscription is removed on disposal', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var calls = 0;
    await tester.pumpWidget(
      _scrollHost(
        PostFrameCallback(
          triggerVisibleArea: 1,
          callback: (_) => calls++,
          child: const Text('Target'),
        ),
        controller,
      ),
    );
    await tester.pumpWidget(_scrollHost(const SizedBox(), controller));
    controller.jumpTo(150);
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('errors after visibility use the handler captured at execution', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final completion = Completer<void>();
    final errors = <Object>[];
    final error = StateError('visible callback');
    await tester.pumpWidget(
      _scrollHost(
        PostFrameCallback(
          triggerVisibleArea: 1,
          callback: (_) => completion.future,
          onError: (error, _) => errors.add(error),
          child: const Text('Target'),
        ),
        controller,
      ),
    );
    controller.jumpTo(150);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    completion.completeError(error, StackTrace.current);
    await tester.pump();
    expect(errors, [same(error)]);
  });

  for (final sheet in [false, true]) {
    testWidgets(
      'real ${sheet ? 'sheet' : 'dialog'} waits for full visibility',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        final results = <String?>[];
        final content = Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).pop('done'),
            child: const Text('Visible modal'),
          ),
        );
        final target = sheet
            ? PostFrameBottomSheet<String>(
                triggerVisibleArea: 1,
                bottomSheet: SizedBox(height: 100, child: content),
                onResult: (_, result) => results.add(result),
                child: const Text('Target'),
              )
            : PostFrameDialog<String>(
                triggerVisibleArea: 1,
                dialog: Dialog(child: content),
                onResult: (_, result) => results.add(result),
                child: const Text('Target'),
              );
        await tester.pumpWidget(_scrollHost(target, controller));
        await tester.pumpAndSettle();
        expect(find.text('Visible modal'), findsNothing);
        controller.jumpTo(100);
        await tester.pumpAndSettle();
        expect(find.text('Visible modal'), findsNothing);
        controller.jumpTo(150);
        await tester.pumpAndSettle();
        expect(find.text('Visible modal'), findsOneWidget);
        await tester.tap(find.text('Visible modal'));
        await tester.pumpAndSettle();
        expect(results, ['done']);
        controller.jumpTo(0);
        await tester.pumpAndSettle();
        controller.jumpTo(150);
        await tester.pumpAndSettle();
        expect(find.text('Visible modal'), findsNothing);
      },
    );
  }
}

class _PaintCounter extends SingleChildRenderObjectWidget {
  const _PaintCounter({required this.onPaint, required super.child});

  final VoidCallback onPaint;

  @override
  _RenderPaintCounter createRenderObject(BuildContext context) =>
      _RenderPaintCounter(onPaint);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPaintCounter renderObject,
  ) {
    renderObject.onPaint = onPaint;
  }
}

class _RenderPaintCounter extends RenderProxyBox {
  _RenderPaintCounter(this.onPaint);

  VoidCallback onPaint;

  @override
  void paint(PaintingContext context, Offset offset) {
    onPaint();
    super.paint(context, offset);
  }
}
