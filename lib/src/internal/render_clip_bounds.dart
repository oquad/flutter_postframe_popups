import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Ancestor clip bounds, including the logical extent of scroll viewports.
@internal
Rect? renderClipBounds(RenderObject parent, RenderObject child) {
  final clip = _paintClip(parent, child);
  final viewport = _viewportRect(parent);
  if (viewport == null) {
    return clip;
  }

  return clip?.intersect(viewport) ?? viewport;
}

Rect? _viewportRect(RenderObject object) {
  if (object is! RenderBox) {
    return null;
  }

  return identical(RenderAbstractViewport.maybeOf(object), object)
      ? Offset.zero & object.size
      : null;
}

Rect? _paintClip(RenderObject parent, RenderObject child) {
  if (parent is RenderClipRect && parent.clipBehavior != Clip.none) {
    return parent.clipper?.getClip(parent.size) ?? Offset.zero & parent.size;
  }

  return parent.describeApproximatePaintClip(child);
}
