import 'package:flutter/material.dart';

import '../support/feedback.dart';

/// Interactive target content, independent of spotlight rendering.
class SpotlightTarget extends StatelessWidget {
  /// Creates the spotlight target button.
  const SpotlightTarget({super.key});

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: () => showSelection(context, 'spotlight action'),
    icon: const Icon(Icons.touch_app),
    label: const Text('Spotlight target'),
  );
}
