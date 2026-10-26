import 'package:flutter/material.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';

/// When [Focus.autofocus] is not enough.
///
/// [Focus.autofocus] selects the initial target when nothing else in its scope
/// is focused. It respects an existing focused control.
///
/// [PostFrameCallback] explicitly requests focus for focusNode post-frame.
/// It can move focus away from an already focused node.
class FocusDemo extends StatefulWidget {
  /// Creates the explicit focus-request recipe.
  const FocusDemo({super.key});

  @override
  State<FocusDemo> createState() => _FocusDemoState();
}

class _FocusDemoState extends State<FocusDemo> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PostFrameCallback(
    callback: (_) => _focusNode.requestFocus(),
    child: TextField(focusNode: _focusNode),
  );
}
