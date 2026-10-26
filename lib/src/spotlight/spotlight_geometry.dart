import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../internal/render_ancestors.dart';
import '../internal/render_clip_bounds.dart';
import 'spotlight_target_not_visible_error.dart';

/// Measured target geometry and its cutout in a chosen Overlay's coordinates.
@internal
class SpotlightGeometry {
  /// Stores a validated local mask rectangle and its paint transform.
  const SpotlightGeometry({required this.maskRect, required this.transform});

  /// Validates a reported layout size, visibility, and resolved mask insets.
  factory SpotlightGeometry.measure(
    RenderBox target,
    RenderBox overlay,
    EdgeInsets insets, {
    required Size size,
    OverlayChildLayoutInfo? layoutInfo,
  }) {
    final transform = _validatedTransform(target, overlay, size, layoutInfo);
    final localRect = Offset.zero & size;

    return SpotlightGeometry(
      maskRect: _maskRect(insets, localRect),
      transform: transform,
    );
  }

  /// The inset-adjusted rectangle in the target's local coordinate system.
  final Rect maskRect;

  /// Maps target-local coordinates into the selected Overlay.
  final Matrix4 transform;
}

Matrix4 _validatedTransform(
  RenderBox target,
  RenderBox overlay,
  Size size,
  OverlayChildLayoutInfo? info,
) {
  _requireLaidOut(target, size);
  _requirePaintedProxy(target);
  final transform = _paintTransform(target, overlay, info);
  _requireVisibleTarget(target, overlay, Offset.zero & size, transform);

  return transform;
}

Matrix4 _paintTransform(
  RenderBox target,
  RenderBox overlay,
  OverlayChildLayoutInfo? info,
) => info?.childPaintTransform ?? target.getTransformTo(overlay);

void _requireVisibleTarget(
  RenderBox target,
  RenderBox overlay,
  Rect localRect,
  Matrix4 transform,
) {
  final bounds = MatrixUtils.transformRect(transform, localRect);
  _requireValidBounds(bounds, transform);
  _requireContained(bounds, Offset.zero & overlay.size);
  _requireVisibleAncestors(target, localRect);
}

void _requireLaidOut(RenderBox target, Size size) {
  if (!target.attached || !target.hasSize || size.isEmpty) {
    throw SpotlightTargetNotVisibleError(
      'The target has no positive layout size.',
    );
  }
}

void _requirePaintedProxy(RenderBox target) {
  RenderBox current = target;
  while (current is RenderProxyBox && current.child != null) {
    final child = current.child!;
    _requirePainted(current, child);
    current = child;
  }
}

void _requirePainted(RenderObject parent, RenderObject child) {
  if (parent is RenderFollowerLayer) {
    throw UnsupportedError(
      'PostFrameSpotlight requires layout-time transforms; '
      'CompositedTransformFollower establishes its transform during compositing.',
    );
  }
  if (!parent.paintsChild(child)) {
    throw SpotlightTargetNotVisibleError(
      'An ancestor does not paint the target.',
    );
  }
}

void _requireValidBounds(Rect bounds, Matrix4 transform) {
  if (!bounds.isFinite || bounds.isEmpty || transform.determinant() == 0) {
    throw SpotlightTargetNotVisibleError(
      'The paint transform has no finite area.',
    );
  }
}

void _requireContained(Rect bounds, Rect visible) {
  final tolerance = visible.inflate(precisionErrorTolerance);
  if (!tolerance.contains(bounds.topLeft) ||
      !tolerance.contains(bounds.bottomRight)) {
    throw SpotlightTargetNotVisibleError(
      'Target $bounds is clipped by $visible.',
    );
  }
}

void _requireVisibleAncestors(RenderBox target, Rect localRect) {
  for (final (child, parent) in renderAncestors(target)) {
    _requirePainted(parent, child);
    _requireWithinClip(
      target,
      parent,
      localRect,
      renderClipBounds(parent, child),
    );
  }
}

void _requireWithinClip(
  RenderBox target,
  RenderObject ancestor,
  Rect localRect,
  Rect? clip,
) {
  if (clip == null) {
    return;
  }
  final bounds = MatrixUtils.transformRect(
    target.getTransformTo(ancestor),
    localRect,
  );
  _requireContained(bounds, clip);
}

void _requireValidMask(Rect maskRect) {
  if (!maskRect.isFinite || maskRect.isEmpty) {
    throw ArgumentError(
      'maskInsets must leave a finite, positive cutout size.',
    );
  }
}

Rect _maskRect(EdgeInsets insets, Rect localRect) {
  final maskRect = insets.deflateRect(localRect);
  _requireValidMask(maskRect);

  return maskRect;
}
