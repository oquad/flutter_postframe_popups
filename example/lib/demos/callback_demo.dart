import 'package:flutter/material.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';

import '../support/feedback.dart';

/// Runs a screen action after the first layout, without a lifecycle override.
class CallbackDemo extends StatelessWidget {
  /// Creates the callback usage demo.
  const CallbackDemo({super.key});

  @override
  Widget build(BuildContext context) => PostFrameCallback(
    callback: showReadyMessage,
    child: const Center(child: Text('Home')),
  );
}
