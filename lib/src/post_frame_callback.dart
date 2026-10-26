import 'dart:async';

import 'package:flutter/widgets.dart';

/// A post-frame callback that may complete synchronously or asynchronously.
typedef PostFrameCallbackFunction =
    FutureOr<void> Function(BuildContext context);

/// Handles a synchronous throw or an error from the returned future.
///
/// Returning normally marks the error as handled. This handler is synchronous.
typedef PostFrameErrorHandler =
    void Function(Object error, StackTrace stackTrace);

/// Schedules [callback] after layout, never inline or during build.
///
/// An injected scheduler must eventually invoke the callback at most once.
typedef PostFrameScheduler = void Function(VoidCallback callback);

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
    // Observe the complete returned future inside _run. No async-void callback
    // is passed to Flutter's synchronous scheduler.
    unawaited(_run(widget.callback, widget.onError));
  }

  @pragma('vm:notify-debugger-on-exception')
  Future<void> _run(
    PostFrameCallbackFunction callback,
    PostFrameErrorHandler? onError,
  ) async {
    try {
      await callback(context);
    } catch (error, stackTrace) {
      _handleError(error, stackTrace, onError);
    }
  }

  static void _handleError(
    Object error,
    StackTrace stackTrace,
    PostFrameErrorHandler? onError,
  ) {
    try {
      (onError ?? _reportActionError).call(error, stackTrace);
    } catch (handlerError, handlerStackTrace) {
      _reportActionError(error, stackTrace);
      _reportHandlerError(handlerError, handlerStackTrace);
    }
  }

  static void _reportActionError(Object error, StackTrace stackTrace) =>
      _report(error, stackTrace, 'while running a PostFrame callback');

  static void _reportHandlerError(Object error, StackTrace stackTrace) =>
      _report(error, stackTrace, 'while handling a PostFrame callback error');

  static void _report(Object error, StackTrace stackTrace, String description) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'flutter_postframe_popups',
        context: ErrorDescription(description),
      ),
    );
  }
}
