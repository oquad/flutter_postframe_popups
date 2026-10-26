import 'dart:async';

import 'package:flutter/widgets.dart';

import 'internal/run_post_frame_action.dart';
import 'post_frame_types.dart';

export 'post_frame_types.dart';

void _scheduleAfterFrame(VoidCallback callback) {
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => callback(),
    debugLabel: 'PostFrameCallback',
  );
}

/// Runs [callback] once after this widget's first frame.
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
  /// Creates a widget that schedules its action after its first frame.
  const PostFrameCallback({
    super.key,
    required this.callback,
    required this.child,
    this.onError,
    @visibleForTesting this.scheduler,
  });

  /// Action executed once after this widget's first frame.
  final PostFrameCallbackFunction callback;

  /// Content built immediately in this widget's location.
  final Widget child;

  /// Overrides default FlutterError.reportError handling.
  ///
  /// If this handler throws, both the original error and the handler's error
  /// are reported through FlutterError.reportError.
  final PostFrameErrorHandler? onError;

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

  @override
  void initState() {
    super.initState();
    (widget.scheduler ?? _scheduleAfterFrame).call(_start);
  }

  @override
  Widget build(BuildContext context) => widget.child;

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
