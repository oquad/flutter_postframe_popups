import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'visible_fraction.dart';

/// A once-only visibility trigger that preserves the child's layout and state.
@internal
class VisibilityTrigger extends SingleChildRenderObjectWidget {
  /// Creates a geometric visibility gate; zero disables all observation.
  const VisibilityTrigger({
    super.key,
    required this.threshold,
    required this.onVisible,
    required super.child,
  });

  /// Required visible area fraction in the inclusive range zero to one.
  final double threshold;

  /// Attempts execution after composition; true stops further observation.
  final bool Function() onVisible;

  @override
  RenderProxyBox createRenderObject(BuildContext context) =>
      _RenderVisibilityTrigger(threshold, onVisible);

  @override
  void updateRenderObject(BuildContext context, RenderProxyBox renderObject) {
    (renderObject as _RenderVisibilityTrigger).configure(threshold, onVisible);
  }
}

class _RenderVisibilityTrigger extends RenderProxyBox {
  _RenderVisibilityTrigger(this.threshold, this.onVisible);

  double threshold;
  bool Function() onVisible;
  VoidCallback? _cancelComposition;
  bool _queued = false;
  bool _triggered = false;

  void configure(double value, bool Function() callback) {
    onVisible = callback;
    if (threshold == value) {
      return;
    }
    threshold = value;
    _stop();
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (threshold > 0 && !_triggered) {
      _stop();
      _cancelComposition = context.addCompositionCallback(_composed);
    }
    super.paint(context, offset);
  }

  void _composed(Layer layer) {
    if (_queued || _triggered || !layer.attached) {
      return;
    }
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback(
      _check,
      debugLabel: 'PostFrameVisibility',
    );
  }

  bool get _eligible =>
      attached &&
      !_triggered &&
      threshold > 0 &&
      visibleFraction(this) + precisionErrorTolerance >= threshold;

  void _check(Duration _) {
    _queued = false;
    if (!_eligible || !onVisible()) {
      return;
    }
    _triggered = true;
    _stop();
  }

  void _stop() {
    _cancelComposition?.call();
    _cancelComposition = null;
  }

  @override
  void detach() {
    _stop();
    super.detach();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}
