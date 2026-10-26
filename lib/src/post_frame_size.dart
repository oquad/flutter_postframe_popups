import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'internal/run_post_frame_action.dart';
import 'post_frame_types.dart';

/// Receives a new layout size after the frame containing that layout.
typedef PostFrameSizeCallback =
    FutureOr<void> Function(BuildContext context, Size size);

/// Builds around a stable measured child; size is null before its first layout.
typedef PostFrameSizeBuilder =
    Widget Function(BuildContext context, Size? size, Widget child);

/// Reports the child's first layout size and subsequent distinct size changes.
///
/// Provide [onMeasured], [builder], or both. The builder receives the measured
/// child, which must appear exactly once in its result. Only that child is
/// measured, excluding builder decorations, transforms, and paint overflow.
/// Notifications are coalesced to the final layout size in each frame.
///
/// Builder updates require a following frame. Identical sizes do not trigger
/// another update. Keep target constraints independent of the reported size:
/// resizing a target based on its own measurement can still create a loop.
/// For same-frame layout decisions, use LayoutBuilder or a custom layout.
class PostFrameSize extends StatefulWidget {
  /// Creates a size observer with an optional declarative builder.
  const PostFrameSize({
    super.key,
    required this.child,
    this.onMeasured,
    this.builder,
    this.onError,
  }) : assert(onMeasured != null || builder != null);

  /// Content whose RenderBox layout size is measured in logical pixels.
  final Widget child;

  /// Receives distinct sizes after layout; may be asynchronous.
  ///
  /// Started calls may overlap. Rebuilds use the latest callback and handler;
  /// an in-flight call keeps its original handler even after disposal.
  final PostFrameSizeCallback? onMeasured;

  /// Builds with null initially, then the latest completed measurement.
  ///
  /// Must include the supplied child exactly once. Builder failures follow
  /// Flutter's normal build-error handling, rather than [onError].
  final PostFrameSizeBuilder? builder;

  /// Handles synchronous and returned-future failures from [onMeasured].
  final PostFrameErrorHandler? onError;

  @override
  State<PostFrameSize> createState() => _PostFrameSizeState();
}

class _PostFrameSizeState extends State<PostFrameSize> {
  Size? _size;
  Size? _pending;
  bool _queued = false;

  @override
  Widget build(BuildContext context) {
    final child = _SizeReporter(onSize: _didLayout, child: widget.child);

    return widget.builder?.call(context, _size, child) ?? child;
  }

  void _didLayout(Size size) {
    _pending = size;
    if (_queued || size == _size) {
      return;
    }
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _publish(),
      debugLabel: 'PostFrameSize',
    );
  }

  void _publish() {
    _queued = false;
    if (!mounted || _pending == _size) {
      return;
    }
    final size = _pending!;
    _updateSize(size);
    _notify(size);
  }

  void _updateSize(Size size) {
    if (widget.builder == null) {
      _size = size;
    } else {
      setState(() => _size = size);
    }
  }

  void _notify(Size size) {
    final callback = widget.onMeasured;
    if (callback != null) {
      unawaited(
        runPostFrameAction(
          (context) => callback(context, size),
          context,
          widget.onError,
        ),
      );
    }
  }
}

class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, required super.child});

  final ValueChanged<Size> onSize;

  @override
  _RenderSizeReporter createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSizeReporter renderObject,
  ) {
    renderObject.onSize = onSize;
  }
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;

  @override
  void performLayout() {
    super.performLayout();
    onSize(size);
  }
}
