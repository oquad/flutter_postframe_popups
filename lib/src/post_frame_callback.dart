import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'internal/run_post_frame_action.dart';
import 'internal/visibility_trigger.dart';
import 'internal/visible_fraction.dart';
import 'post_frame_types.dart';

export 'post_frame_types.dart';

void _scheduleAfterFrame(VoidCallback callback) {
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => callback(),
    debugLabel: 'PostFrameCallback',
  );
}

/// Runs [callback] once after the first frame meeting [triggerVisibleArea].
///
/// Builds [child] immediately. Rebuilds do not repeat the action. A new State
/// (for example after changing the key) schedules a new action. Updates before
/// execution use the latest callback and error handler; updates after execution
/// do not restart it. The scheduler is read once, during initState.
///
/// Disposal before execution skips the action. Already-started work is not
/// cancelled, and its errors are still reported after disposal. User callbacks
/// must check context.mounted after their own asynchronous gaps.
///
/// Only synchronous throws and errors from the returned future are handled.
/// Return or await asynchronous work instead of detaching it. This widget does
/// not create an error zone or wait for route transitions, images, or data.
class PostFrameCallback extends StatefulWidget {
  /// Creates a once-only callback with an optional visibility threshold.
  const PostFrameCallback({
    super.key,
    required this.callback,
    required this.child,
    this.onError,
    this.triggerVisibleArea = 0,
    @visibleForTesting this.scheduler,
  }) : assert(triggerVisibleArea >= 0 && triggerVisibleArea <= 1);

  /// Action executed once after the visibility threshold and first frame.
  final PostFrameCallbackFunction callback;

  /// Content built immediately in this widget's location.
  final Widget child;

  /// Overrides default FlutterError.reportError handling.
  ///
  /// If this handler throws, both the original error and the handler's error
  /// are reported through FlutterError.reportError.
  final PostFrameErrorHandler? onError;

  /// Required fraction of the target's layout area visible before execution.
  ///
  /// Zero preserves first-frame execution regardless of visibility. Values in
  /// (0, 1] wait until that fraction is on screen: 0.5 means half, 1 means all.
  /// Positive thresholds require a nonempty, painted target. Visibility uses
  /// viewport and ancestor clip geometry, not sibling-occlusion pixel tests.
  /// A lazy child cannot trigger before it is built. Waiting does not poll,
  /// scroll automatically, or replay an already-started callback.
  final double triggerVisibleArea;

  /// Testing-only override; null uses Flutter's post-frame scheduler.
  ///
  /// Production callers should use Flutter's default frame scheduling.
  @visibleForTesting
  final PostFrameScheduler? scheduler;

  @override
  State<PostFrameCallback> createState() => _PostFrameCallbackState();
}

class _PostFrameCallbackState extends State<PostFrameCallback> {
  bool _started = false;
  bool _armed = false;
  late final PostFrameScheduler _schedule;

  @override
  void initState() {
    super.initState();
    _schedule = widget.scheduler ?? _scheduleAfterFrame;
    _schedule(_arm);
  }

  @override
  Widget build(BuildContext context) => VisibilityTrigger(
    threshold: _started ? 0 : widget.triggerVisibleArea,
    onVisible: _startIfArmed,
    child: widget.child,
  );

  @override
  void didUpdateWidget(PostFrameCallback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_started &&
        oldWidget.triggerVisibleArea > 0 &&
        widget.triggerVisibleArea == 0) {
      _schedule(_arm);
    }
  }

  void _arm() {
    if (!mounted) {
      return;
    }
    _armed = true;
    if (widget.triggerVisibleArea == 0 || _visibleEnough) {
      _start();
    }
  }

  bool get _visibleEnough =>
      visibleFraction(context.findRenderObject()! as RenderBox) +
          precisionErrorTolerance >=
      widget.triggerVisibleArea;

  bool _startIfArmed() {
    if (!_armed || !mounted) {
      return false;
    }
    _start();

    return true;
  }

  void _start() {
    if (!mounted || _started) {
      return;
    }
    _started = true;
    // Observe the complete returned future in the shared runner. No async-void
    // callback is passed to Flutter's synchronous scheduler.
    unawaited(runPostFrameAction(widget.callback, context, widget.onError));
  }
}
