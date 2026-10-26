import 'dart:async';

import 'package:flutter/widgets.dart';

import 'internal/run_post_frame_action.dart';
import 'post_frame_types.dart';

/// Receives an OS application lifecycle transition with a mounted context.
typedef ObservedLifecycleCallback =
    FutureOr<void> Function(BuildContext context, AppLifecycleState state);

/// Builds around a stable child with the latest known OS lifecycle state.
typedef ObservedLifecycleBuilder =
    Widget Function(
      BuildContext context,
      AppLifecycleState? state,
      Widget child,
    );

/// Owns an AppLifecycleListener and exposes OS state declaratively.
///
/// Provide [onStateChanged], [builder], or both. Subscribes immediately while
/// mounted; transitions are never delayed until a rendered frame, which may
/// not arrive while paused. The builder starts with the binding's current
/// state (possibly null). The callback receives changes, not an initial replay.
///
/// States may be skipped and notifications cannot be guaranteed at shutdown.
/// Use inactive as well as hidden/paused for sensitive UI, but do not rely on a
/// Dart rebuild alone to secure the OS task-switcher snapshot. Callback futures
/// may overlap: pause/resume work must handle rapid transitions in the app.
class ObservedAppLifecycle extends StatefulWidget {
  /// Creates a lifecycle subscription and optional state-aware builder.
  const ObservedAppLifecycle({
    super.key,
    required this.child,
    this.onStateChanged,
    this.builder,
    this.onError,
    @visibleForTesting this.binding,
  }) : assert(onStateChanged != null || builder != null);

  /// Stable content supplied to [builder], or built directly if it is absent.
  final Widget child;

  /// Receives each distinct lifecycle transition; may be asynchronous.
  ///
  /// New transitions use the latest callback and error handler. Started work
  /// keeps its original handler, including failures after disposal.
  final ObservedLifecycleCallback? onStateChanged;

  /// Builds with the current lifecycle state and the supplied child.
  ///
  /// Builder failures follow Flutter's normal build-error handling.
  final ObservedLifecycleBuilder? builder;

  /// Handles synchronous and returned-future callback failures.
  final PostFrameErrorHandler? onError;

  /// Testing-only binding override, captured once when this State is created.
  @visibleForTesting
  final WidgetsBinding? binding;

  @override
  State<ObservedAppLifecycle> createState() => _ObservedAppLifecycleState();
}

class _ObservedAppLifecycleState extends State<ObservedAppLifecycle> {
  late final AppLifecycleListener _listener;
  AppLifecycleState? _state;

  @override
  void initState() {
    super.initState();
    final binding = widget.binding ?? WidgetsBinding.instance;
    _state = binding.lifecycleState;
    _listener = AppLifecycleListener(binding: binding, onStateChange: _changed);
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder?.call(context, _state, widget.child) ?? widget.child;

  void _changed(AppLifecycleState state) {
    if (!mounted) {
      return;
    }
    if (widget.builder == null) {
      _state = state;
    } else {
      setState(() => _state = state);
    }
    _notify(state);
  }

  void _notify(AppLifecycleState state) {
    final callback = widget.onStateChanged;
    if (callback != null) {
      unawaited(
        runPostFrameAction(
          (context) => callback(context, state),
          context,
          widget.onError,
        ),
      );
    }
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }
}
