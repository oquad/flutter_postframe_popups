import 'package:flutter/material.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';

/// Shows global pointer-down coordinates without consuming gestures.
class PointerListenerDemo extends StatefulWidget {
  /// Creates the pointer observation demo.
  const PointerListenerDemo({super.key});

  @override
  State<PointerListenerDemo> createState() => _PointerListenerDemoState();
}

class _PointerListenerDemoState extends State<PointerListenerDemo> {
  Offset? _position;

  void _record(BuildContext _, PointerEvent event) {
    if (event is PointerDownEvent) {
      setState(() => _position = event.position);
    }
  }

  @override
  Widget build(BuildContext context) => ObservedGestures(
    onPointerEvent: _record,
    child: Center(
      child: Text(_position == null ? 'Tap anywhere' : 'Pointer: $_position'),
    ),
  );
}
