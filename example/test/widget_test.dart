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
}
