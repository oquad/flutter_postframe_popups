import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'internal/run_post_frame_action.dart';
import 'post_frame_types.dart';

/// Observes a raw event routed through Flutter without consuming it.
typedef ObservedGestureCallback =
    FutureOr<void> Function(BuildContext context, PointerEvent event);

/// Observes Flutter's global pointer router for this widget's mounted lifetime.
///
/// The subscription starts immediately, independently of child hit testing.
/// It adds no hit-test entries, joins no gesture arenas, and cannot cancel
/// events. Events outside this subtree are included: normally mount one
/// listener near the app root. Each mounted instance receives its own copy.
///
/// Only events reaching Flutter's pointer router are observable. Touches
/// consumed entirely by native platform views or other engines are outside
/// this contract. Coordinates retain the event's global Flutter view space;
/// use PointerEvent.viewId in multi-view applications.
class ObservedGestures extends StatefulWidget {
  /// Creates a passive global pointer subscription.
  const ObservedGestures({
    super.key,
    required this.child,
    required this.onPointerEvent,
    this.onError,
    @visibleForTesting this.pointerRouter,
  });

  /// Content built immediately, without a hit-testing wrapper.
  final Widget child;

  /// Receives each routed event immediately; may return an observed future.
  ///
  /// High-frequency callbacks should stay short. Calls may overlap; sample or
  /// batch in your analytics layer rather than starting work for every move.
  /// This widget does not store events, throttle, or send analytics anywhere.
  final ObservedGestureCallback onPointerEvent;

  /// Handles synchronous and returned-future callback failures.
  final PostFrameErrorHandler? onError;

  /// Testing-only router override, captured once when this State is created.
  @visibleForTesting
  final PointerRouter? pointerRouter;

  @override
  State<ObservedGestures> createState() => _ObservedGesturesState();
}

class _ObservedGesturesState extends State<ObservedGestures> {
  late final PointerRouter _router;

  @override
  void initState() {
    super.initState();
    _router = widget.pointerRouter ?? GestureBinding.instance.pointerRouter;
    _router.addGlobalRoute(_event);
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _event(PointerEvent event) {
    if (!mounted) {
      return;
    }
    final callback = widget.onPointerEvent;
    unawaited(
      runPostFrameAction(
        (context) => callback(context, event),
        context,
        widget.onError,
      ),
    );
  }

  @override
  void dispose() {
    _router.removeGlobalRoute(_event);
    super.dispose();
  }
}
