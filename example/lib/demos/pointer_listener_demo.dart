import 'package:flutter/material.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';

import '../content/pointer_event_details.dart';

/// Inspects all routed pointer events without consuming gestures.
class PointerListenerDemo extends StatefulWidget {
  /// Creates the pointer observation demo.
  const PointerListenerDemo({super.key});

  @override
  State<PointerListenerDemo> createState() => _PointerListenerDemoState();
}

class _PointerListenerDemoState extends State<PointerListenerDemo> {
  PointerEvent? _event;

  @override
  Widget build(BuildContext context) => ObservedGestures(
    onPointerEvent: (BuildContext _, PointerEvent event) =>
        setState(() => _event = event),
    child: PointerEventDetails(event: _event),
  );
}
