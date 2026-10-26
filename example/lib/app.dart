import 'package:flutter/material.dart';

import 'demo_home.dart';

/// Application scaffolding, separate from the package usage demos.
class PostFrameExample extends StatelessWidget {
  /// Creates the example application.
  const PostFrameExample({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PostFrame example',
    theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
    home: const DemoHome(),
  );
}
