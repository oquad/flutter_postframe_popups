import 'package:flutter/widgets.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('runs once on the supplied scheduler', (tester) async {
    VoidCallback? pending;
    var calls = 0;
    await tester.pumpWidget(
      PostFrameCallback(
        scheduler: (callback) => pending = callback,
        callback: (_) {
          calls++;
        },
        child: const SizedBox.shrink(),
      ),
    );
    expect(calls, 0);
    pending!();
    await tester.pump();
    expect(calls, 1);
  });
}
