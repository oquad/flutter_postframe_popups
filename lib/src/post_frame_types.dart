import 'dart:async';

import 'package:flutter/widgets.dart';

/// A context-aware callback that may complete synchronously or asynchronously.
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
