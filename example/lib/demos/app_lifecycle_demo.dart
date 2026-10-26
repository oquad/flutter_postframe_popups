import 'package:flutter/material.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';

import '../content/lifecycle_status.dart';

/// Reflects OS lifecycle state while preserving the content widget.
class AppLifecycleDemo extends StatelessWidget {
  /// Creates the lifecycle demo.
  const AppLifecycleDemo({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: ObservedAppLifecycle(
      builder: (_, state, child) => LifecycleStatus(state: state, child: child),
      child: const Text('Lifecycle content'),
    ),
  );
}
