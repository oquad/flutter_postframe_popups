import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../post_frame_types.dart';

/// Runs a context-aware action with the package's shared async error policy.
@internal
@pragma('vm:notify-debugger-on-exception')
Future<void> runPostFrameAction(
  PostFrameCallbackFunction callback,
  BuildContext context,
  PostFrameErrorHandler? onError,
) async {
  try {
    await callback(context);
  } catch (error, stackTrace) {
    _handleError(error, stackTrace, onError);
  }
}

void _handleError(
  Object error,
  StackTrace stackTrace,
  PostFrameErrorHandler? onError,
) {
  try {
    (onError ?? _reportActionError).call(error, stackTrace);
  } catch (handlerError, handlerStackTrace) {
    _reportActionError(error, stackTrace);
    _report(
      handlerError,
      handlerStackTrace,
      'while handling a PostFrame callback error',
    );
  }
}

void _reportActionError(Object error, StackTrace stackTrace) =>
    _report(error, stackTrace, 'while running a PostFrame callback');

void _report(Object error, StackTrace stackTrace, String description) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'flutter_postframe_popups',
      context: ErrorDescription(description),
    ),
  );
}
