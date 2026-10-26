import 'package:flutter/material.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';
import 'package:flutter_postframe_popups_example/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'example demonstrates popups, spotlight, and the focus callback recipe',
    (tester) async {
      await tester.pumpWidget(const PostFrameExample());
      await tester.pumpAndSettle();
      expect(find.text('Ready after the first frame'), findsOneWidget);

      await tester.tap(find.text('Dialog'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('France'));
      await tester.pumpAndSettle();
      expect(find.text('Selected France'), findsOneWidget);

      await tester.tap(find.text('Sheet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Newest'));
      await tester.pumpAndSettle();
      expect(find.text('Selected Newest'), findsOneWidget);

      await tester.tap(find.text('Focus'));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.focusNode!.hasFocus, isTrue);

      await tester.tap(find.text('Spotlight'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('postframe.spotlight.mask')),
        findsOneWidget,
      );
      final target = find.byType(PostFrameSpotlight);
      final bounds = tester.getRect(target);
      expect(bounds.size.isEmpty, isFalse);
      final mask = find.byKey(const ValueKey('postframe.spotlight.mask'));
      final clip = tester.widget<ClipPath>(mask);
      final path = clip.clipper!.getClip(tester.getSize(mask));
      expect(path.contains(bounds.center), isFalse);
      expect(path.contains(const Offset(20, 100)), isTrue);
      await tester.tap(find.text('Spotlight target'));
      await tester.pumpAndSettle();
      expect(find.text('Selected spotlight action'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('postframe.spotlight.mask')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'binding demos measure, release memory, observe pointers and OS state',
    (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(const PostFrameExample());
      await tester.pumpAndSettle();
      await _openDemo(tester, 'Measure');
      expect(find.text('Measured: Size(180.0, 72.0)'), findsOneWidget);

      await _openDemo(tester, 'Memory');
      expect(find.text('Cached previews: 4'), findsOneWidget);
      tester.binding.handleMemoryPressure();
      await tester.pump();
      expect(find.text('Cached previews: 0'), findsOneWidget);
      await tester.tap(find.text('Refill previews'));
      await tester.pump();
      expect(find.text('Cached previews: 4'), findsOneWidget);
      await tester.tap(find.text('Release previews'));
      await tester.pump();
      expect(find.text('Cached previews: 0'), findsOneWidget);

      await _openDemo(tester, 'Pointers');
      await tester.tapAt(const Offset(100, 150));
      await tester.pump();
      expect(find.text('Pointer: Offset(100.0, 150.0)'), findsOneWidget);

      await _openDemo(tester, 'Lifecycle');
      expect(find.text('App state: resumed'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.text('App state: inactive'), findsOneWidget);
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      expect(find.text('App state: resumed'), findsOneWidget);
    },
  );
}

Future<void> _openDemo(WidgetTester tester, String name) async {
  final destination = find.text(name);
  await tester.ensureVisible(destination);
  await tester.tap(destination);
  await tester.pumpAndSettle();
}
