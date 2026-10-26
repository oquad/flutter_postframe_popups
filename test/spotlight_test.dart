import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';
import 'package:flutter_test/flutter_test.dart';

final _mask = find.byKey(const ValueKey('postframe.spotlight.mask'));

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(backgroundColor: Colors.white, body: child),
);

Widget _positioned(Widget child) =>
    Stack(children: [Positioned(left: 80, top: 60, child: child)]);

Widget _target({Key? key, double width = 100, double height = 60}) => SizedBox(
  key: key,
  width: width,
  height: height,
  child: const ColoredBox(color: Colors.green),
);

Path _maskPath(WidgetTester tester) {
  final widget = tester.widget<ClipPath>(_mask);

  return widget.clipper!.getClip(tester.getSize(_mask));
}

class _RecordingClipper extends CustomClipper<Path> {
  Size? measured;

  @override
  Path getClip(Size size) {
    measured = size;

    return Path()..addRect(Offset.zero & size);
  }

  @override
  bool shouldReclip(_RecordingClipper oldClipper) => true;
}

class _AnimatedClipper extends CustomClipper<Path> {
  _AnimatedClipper(this.fraction) : super(reclip: fraction);

  final ValueNotifier<double> fraction;

  @override
  Path getClip(Size size) => Path()
    ..addRect(Rect.fromLTWH(0, 0, size.width * fraction.value, size.height));

  @override
  bool shouldReclip(_AnimatedClipper oldClipper) =>
      fraction != oldClipper.fraction;
}

class _PartialClipper extends CustomClipper<Rect> {
  const _PartialClipper();

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width / 2, size.height);

  @override
  bool shouldReclip(_PartialClipper oldClipper) => false;
}

void main() {
  testWidgets('measures fractional layout dimensions in overlay coordinates', (
    tester,
  ) async {
    final clipper = _RecordingClipper();
    final key = GlobalKey();
    await tester.pumpWidget(
      _host(
        _positioned(
          PostFrameSpotlight(
            clipper: clipper,
            child: _target(key: key, width: 100.5, height: 60.25),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(clipper.measured, const Size(100.5, 60.25));
    final rect = tester.getRect(find.byKey(key));
    final path = _maskPath(tester);
    expect(path.contains(rect.center), isFalse);
    expect(path.contains(rect.topLeft + const Offset(0.1, 0.1)), isFalse);
    expect(path.contains(rect.topLeft - const Offset(1, 1)), isTrue);
  });

  testWidgets('oval and rounded rectangle presets create different corners', (
    tester,
  ) async {
    for (final oval in [true, false]) {
      await tester.pumpWidget(
        _host(
          _positioned(
            PostFrameSpotlight(
              key: ValueKey(oval),
              clipper: oval
                  ? const SpotlightOvalClipper()
                  : const SpotlightRRectClipper(
                      borderRadius: BorderRadius.zero,
                    ),
              child: _target(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final path = _maskPath(tester);
      expect(path.contains(const Offset(130, 90)), isFalse);
      expect(path.contains(const Offset(81, 61)), oval);
    }
  });

  testWidgets('signed asymmetric insets adjust local cutout bounds', (
    tester,
  ) async {
    final clipper = _RecordingClipper();
    await tester.pumpWidget(
      _host(
        _positioned(
          PostFrameSpotlight(
            clipper: clipper,
            maskInsets: const EdgeInsets.fromLTRB(-10, -5, 20, 10),
            child: _target(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(clipper.measured, const Size(90, 55));
    final path = _maskPath(tester);
    expect(path.contains(const Offset(71, 56)), isFalse);
    expect(path.contains(const Offset(161, 90)), isTrue);
  });

  testWidgets('directional insets resolve against inherited RTL direction', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Directionality(
          textDirection: TextDirection.rtl,
          child: _positioned(
            PostFrameSpotlight(
              clipper: const SpotlightRRectClipper(
                borderRadius: BorderRadius.zero,
              ),
              maskInsets: const EdgeInsetsDirectional.only(start: 10, end: 20),
              child: _target(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final path = _maskPath(tester);
    expect(path.contains(const Offset(95, 90)), isTrue);
    expect(path.contains(const Offset(165, 90)), isFalse);
  });

  testWidgets('OverflowBox uses its layout size with explicit expansion', (
    tester,
  ) async {
    final clipper = _RecordingClipper();
    await tester.pumpWidget(
      _host(
        _positioned(
          SizedBox(
            width: 100,
            height: 60,
            child: PostFrameSpotlight(
              clipper: clipper,
              maskInsets: const EdgeInsets.all(-10),
              child: OverflowBox(
                minWidth: 120,
                maxWidth: 120,
                minHeight: 80,
                maxHeight: 80,
                child: _target(width: 120, height: 80),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(clipper.measured, const Size(120, 80));
    expect(_maskPath(tester).contains(const Offset(71, 51)), isFalse);
  });

  testWidgets('ancestor scale and rotation transform the custom hole', (
    tester,
  ) async {
    final key = GlobalKey();
    final clipper = _RecordingClipper();
    await tester.pumpWidget(
      _host(
        _positioned(
          Transform.rotate(
            angle: math.pi / 6,
            alignment: Alignment.topLeft,
            child: Transform.scale(
              scale: 1.2,
              alignment: Alignment.topLeft,
              child: PostFrameSpotlight(
                clipper: clipper,
                child: _target(key: key),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(clipper.measured, const Size(100, 60));
    final target = tester.renderObject<RenderBox>(find.byKey(key));
    final path = _maskPath(tester);
    expect(path.contains(target.localToGlobal(const Offset(5, 5))), isFalse);
    expect(path.contains(target.localToGlobal(const Offset(-5, -5))), isTrue);
  });

  testWidgets('accepts Flutter ShapeBorderClipper with a star', (tester) async {
    await tester.pumpWidget(
      _host(
        _positioned(
          PostFrameSpotlight(
            clipper: const ShapeBorderClipper(shape: StarBorder()),
            child: _target(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final path = _maskPath(tester);
    expect(path.contains(const Offset(130, 90)), isFalse);
    expect(path.contains(const Offset(81, 61)), isTrue);
  });

  testWidgets('custom clipper reclip notifications update the hole', (
    tester,
  ) async {
    final fraction = ValueNotifier<double>(1);
    addTearDown(fraction.dispose);
    await tester.pumpWidget(
      _host(
        _positioned(
          PostFrameSpotlight(
            clipper: _AnimatedClipper(fraction),
            child: _target(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_maskPath(tester).contains(const Offset(160, 90)), isFalse);
    fraction.value = 0.5;
    await tester.pump();
    expect(_maskPath(tester).contains(const Offset(160, 90)), isTrue);
    expect(_maskPath(tester).contains(const Offset(100, 90)), isFalse);
  });

  testWidgets('opt-out passes taps through and shaded area dismisses once', (
    tester,
  ) async {
    var targetTaps = 0;
    var backgroundTaps = 0;
    var dismissals = 0;
    await tester.pumpWidget(
      _host(
        Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => backgroundTaps++,
              ),
            ),
            Positioned(
              left: 80,
              top: 60,
              child: PostFrameSpotlight(
                clipper: const SpotlightRRectClipper(
                  borderRadius: BorderRadius.zero,
                ),
                dismissOnCutoutTap: false,
                onDismissed: (_) {
                  dismissals++;
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => targetTaps++,
                  child: _target(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(130, 90));
    expect(targetTaps, 1);
    expect(_mask, findsOneWidget);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(dismissals, 1);
    expect(backgroundTaps, 0);
    expect(_mask, findsNothing);
  });

  for (final barrierDismissible in [true, false]) {
    testWidgets(
      'cutout tap dismisses and reaches child: barrier=$barrierDismissible',
      (tester) async {
        var taps = 0;
        var dismissals = 0;
        await tester.pumpWidget(
          _host(
            _positioned(
              PostFrameSpotlight(
                barrierDismissible: barrierDismissible,
                onDismissed: (_) => dismissals++,
                child: GestureDetector(onTap: () => taps++, child: _target()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(130, 90));
        await tester.pumpAndSettle();
        expect(taps, 1);
        expect(dismissals, 1);
        expect(_mask, findsNothing);
      },
    );
  }

  testWidgets('cutout tap works in expanded hole outside child bounds', (
    tester,
  ) async {
    var dismissals = 0;
    await tester.pumpWidget(
      _host(
        _positioned(
          PostFrameSpotlight(
            maskInsets: const EdgeInsets.all(-20),
            onDismissed: (_) => dismissals++,
            child: _target(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(70, 90));
    await tester.pumpAndSettle();
    expect(dismissals, 1);
    expect(_mask, findsNothing);
  });

  testWidgets('drag, long press, secondary button and cancellation keep mask', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(_positioned(PostFrameSpotlight(child: _target()))),
    );
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(100, 90), const Offset(50, 0));
    await tester.longPressAt(const Offset(130, 90));
    final secondary = await tester.startGesture(
      const Offset(130, 90),
      buttons: kSecondaryButton,
    );
    await secondary.up();
    final cancelled = await tester.startGesture(const Offset(130, 90));
    await cancelled.cancel();
    await tester.pumpAndSettle();
    expect(_mask, findsOneWidget);
    await tester.tapAt(const Offset(130, 90));
    await tester.pumpAndSettle();
    expect(_mask, findsNothing);
  });

  testWidgets('non-dismissible mask blocks outside hits', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: _positioned(
            PostFrameSpotlight(barrierDismissible: false, child: _target()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    expect(taps, 0);
    expect(_mask, findsOneWidget);
  });

  for (final hidden in [
    'below viewport',
    'partially clipped',
    'clip none',
    'offstage',
    'transparent',
    'zero size',
  ]) {
    testWidgets('reports invisible target: $hidden', (tester) async {
      final errors = <Object>[];
      final target = PostFrameSpotlight(
        onError: (error, _) => errors.add(error),
        child: _target(height: hidden == 'zero size' ? 0 : 60),
      );
      final content = switch (hidden) {
        'offstage' => Offstage(child: target),
        'transparent' => Opacity(opacity: 0, child: target),
        'zero size' => _positioned(target),
        _ => Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            height: 100,
            child: SingleChildScrollView(
              clipBehavior: hidden == 'clip none' ? Clip.none : Clip.hardEdge,
              child: Column(
                children: [
                  SizedBox(height: hidden == 'partially clipped' ? 80 : 140),
                  target,
                ],
              ),
            ),
          ),
        ),
      };
      await tester.pumpWidget(_host(content));
      await tester.pumpAndSettle();
      expect(errors, [isA<SpotlightTargetNotVisibleError>()]);
      expect(_mask, findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('rotated viewport rejects a partially clipped target', (
    tester,
  ) async {
    final errors = <Object>[];
    await tester.pumpWidget(
      _host(
        Stack(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 90),
                        Padding(
                          padding: const EdgeInsets.only(left: 40),
                          child: PostFrameSpotlight(
                            onError: (error, _) => errors.add(error),
                            child: _target(),
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
      ),
    );
    await tester.pumpAndSettle();
    expect(errors, [isA<SpotlightTargetNotVisibleError>()]);
    expect(_mask, findsNothing);
  });

  testWidgets('ancestor clip bounds reject a partially painted target', (
    tester,
  ) async {
    final errors = <Object>[];
    await tester.pumpWidget(
      _host(
        _positioned(
          ClipRect(
            clipper: const _PartialClipper(),
            child: PostFrameSpotlight(
              onError: (error, _) => errors.add(error),
              child: _target(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(errors, [isA<SpotlightTargetNotVisibleError>()]);
    expect(_mask, findsNothing);
  });

  testWidgets('cached offscreen lazy-list target reports a visibility error', (
    tester,
  ) async {
    final errors = <Object>[];
    await tester.pumpWidget(
      _host(
        SizedBox(
          height: 100,
          child: ListView.builder(
            itemExtent: 100,
            scrollCacheExtent: const ScrollCacheExtent.pixels(400),
            itemCount: 10,
            itemBuilder: (_, index) => index == 2
                ? PostFrameSpotlight(
                    onError: (error, _) => errors.add(error),
                    child: _target(),
                  )
                : const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(errors, [isA<SpotlightTargetNotVisibleError>()]);
    expect(_mask, findsNothing);
  });

  testWidgets('tracks visible scrolling then removes an invalid target once', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final errors = <Object>[];
    var dismissed = false;
    await tester.pumpWidget(
      _host(
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                PostFrameSpotlight(
                  clipper: const SpotlightRRectClipper(
                    borderRadius: BorderRadius.zero,
                  ),
                  onError: (error, _) => errors.add(error),
                  onDismissed: (_) {
                    dismissed = true;
                  },
                  child: _target(),
                ),
                const SizedBox(height: 800),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.jumpTo(20);
    await tester.pumpAndSettle();
    expect(_maskPath(tester).contains(const Offset(50, 40)), isFalse);
    expect(_maskPath(tester).contains(const Offset(50, 100)), isTrue);
    controller.jumpTo(200);
    await tester.pumpAndSettle();
    await tester.pump();
    expect(errors, [isA<SpotlightTargetNotVisibleError>()]);
    expect(_mask, findsNothing);
    expect(dismissed, isFalse);
  });

  testWidgets(
    'resize updates bounds; rebuild after dismissal does not replay',
    (tester) async {
      final clipper = _RecordingClipper();
      Widget screen(double width) => _host(
        _positioned(
          PostFrameSpotlight(
            clipper: clipper,
            child: _target(width: width),
          ),
        ),
      );
      await tester.pumpWidget(screen(100));
      await tester.pumpAndSettle();
      await tester.pumpWidget(screen(150));
      await tester.pumpAndSettle();
      expect(clipper.measured, const Size(150, 60));
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      await tester.pumpWidget(screen(160));
      await tester.pumpAndSettle();
      expect(_mask, findsNothing);
    },
  );

  testWidgets('disposal removes overlay without calling onDismissed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        _positioned(
          PostFrameSpotlight(
            onDismissed: (_) => fail('Disposal is not a user dismissal'),
            child: _target(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(_mask, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('async dismissal failure uses the common error handler', (
    tester,
  ) async {
    final completion = Completer<void>();
    final error = StateError('Dismissal failed');
    final errors = <Object>[];
    await tester.pumpWidget(
      _host(
        _positioned(
          PostFrameSpotlight(
            onDismissed: (_) => completion.future,
            onError: (caught, _) => errors.add(caught),
            child: _target(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    completion.completeError(error, StackTrace.current);
    await tester.pump();
    expect(errors, [same(error)]);
  });

  testWidgets('invalid insets report an argument error without showing mask', (
    tester,
  ) async {
    final errors = <Object>[];
    await tester.pumpWidget(
      _host(
        _positioned(
          PostFrameSpotlight(
            maskInsets: const EdgeInsets.all(100),
            onError: (error, _) => errors.add(error),
            child: _target(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(errors, [isArgumentError]);
    expect(_mask, findsNothing);
  });

  testWidgets(
    'missing error handler reports visibility failures through FlutterError',
    (tester) async {
      await tester.pumpWidget(
        _host(Offstage(child: PostFrameSpotlight(child: _target()))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isA<SpotlightTargetNotVisibleError>());
    },
  );

  testWidgets('painted mask dims outside and preserves the original child', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: _host(
          _positioned(
            PostFrameSpotlight(
              barrierColor: const Color(0xBF000000),
              child: _target(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(key),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = (await image.toByteData())!;
      final center = (90 * image.width + 130) * 4;
      final outside = (20 * image.width + 20) * 4;
      expect(bytes.getUint8(center), 76);
      expect(bytes.getUint8(center + 1), 175);
      expect(bytes.getUint8(center + 2), 80);
      expect(bytes.getUint8(outside), closeTo(64, 1));
      image.dispose();
    });
  });
  for (final root in [false, true]) {
    testWidgets('uses correct coordinates in nested overlays, root=$root', (
      tester,
    ) async {
      final key = GlobalKey();
      final entry = OverlayEntry(
        builder: (_) => Center(
          child: PostFrameSpotlight(
            overlayLocation: root
                ? OverlayChildLocation.rootOverlay
                : OverlayChildLocation.nearestOverlay,
            child: _target(key: key),
          ),
        ),
      );
      await tester.pumpWidget(
        _host(
          Stack(
            children: [
              Positioned(
                left: 40,
                top: 30,
                width: 220,
                height: 160,
                child: Overlay(initialEntries: [entry]),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final expected = root
          ? tester.getSize(find.byType(Scaffold))
          : const Size(220, 160);
      expect(tester.getSize(_mask), expected);
      final center =
          tester.getCenter(find.byKey(key)) - tester.getTopLeft(_mask);
      expect(_maskPath(tester).contains(center), isFalse);
      entry.remove();
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      entry.dispose();
    });
  }

  testWidgets('rejects compositing-only follower transforms through onError', (
    tester,
  ) async {
    final link = LayerLink();
    final errors = <Object>[];
    await tester.pumpWidget(
      _host(
        Stack(
          children: [
            CompositedTransformTarget(
              link: link,
              child: const SizedBox(width: 100, height: 60),
            ),
            CompositedTransformFollower(
              link: link,
              child: PostFrameSpotlight(
                onError: (error, _) => errors.add(error),
                child: _target(),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(errors, [isUnsupportedError]);
    expect(_mask, findsNothing);
  });
}
