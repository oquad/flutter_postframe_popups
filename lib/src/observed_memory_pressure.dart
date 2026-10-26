import 'dart:async';

import 'package:flutter/widgets.dart';

import 'internal/run_post_frame_action.dart';
import 'post_frame_types.dart';

/// Releases app-owned resources when Flutter receives OS memory pressure.
///
/// Subscribes while mounted and calls [onMemoryPressure] immediately on each
/// notification, without waiting for another frame. Notifications received
/// while that callback is running are coalesced into the current cleanup.
///
/// Flutter already clears its ordinary image cache. Use this widget to release
/// your own caches, undo histories, or other disposable data. It never guesses
/// which application state may be destroyed, and does not guarantee a warning
/// or enough execution time before the OS terminates an app.
class ObservedMemoryPressure extends StatefulWidget {
  /// Creates a declarative owner for an OS memory-pressure subscription.
  const ObservedMemoryPressure({
    super.key,
    required this.child,
    required this.onMemoryPressure,
    this.onError,
    @visibleForTesting this.binding,
  });

  /// Content built immediately and otherwise left unchanged.
  final Widget child;

  /// Performs app-specific cleanup; may complete asynchronously.
  ///
  /// Prefer promptly releasing references before awaiting other work. Future
  /// notifications use the latest callback; started work is not cancelled.
  final PostFrameCallbackFunction onMemoryPressure;

  /// Handles cleanup failures, including failures after widget disposal.
  final PostFrameErrorHandler? onError;

  /// Testing-only binding override, captured once when this State is created.
  @visibleForTesting
  final WidgetsBinding? binding;

  @override
  State<ObservedMemoryPressure> createState() => _ObservedMemoryPressureState();
}

class _ObservedMemoryPressureState extends State<ObservedMemoryPressure>
    with WidgetsBindingObserver {
  late final WidgetsBinding _binding;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _binding = widget.binding ?? WidgetsBinding.instance;
    _binding.addObserver(this);
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void didHaveMemoryPressure() {
    if (mounted && !_running) {
      unawaited(_release());
    }
  }

  Future<void> _release() async {
    _running = true;
    try {
      await runPostFrameAction(
        widget.onMemoryPressure,
        context,
        widget.onError,
      );
    } finally {
      _running = false;
    }
  }

  @override
  void dispose() {
    _binding.removeObserver(this);
    super.dispose();
  }
}
