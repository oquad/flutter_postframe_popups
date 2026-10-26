import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Child-parent edges from a render object to its root, in paint order.
@internal
Iterable<(RenderObject, RenderObject)> renderAncestors(
  RenderObject child,
) sync* {
  for (var parent = child.parent; parent != null; parent = parent.parent) {
    yield (child, parent);
    child = parent;
  }
}
