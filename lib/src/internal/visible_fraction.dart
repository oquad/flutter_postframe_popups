import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'render_ancestors.dart';
import 'render_clip_bounds.dart';

/// The geometrically visible fraction of a target's transformed layout box.
///
/// Rectangular clipping is exact, including affine transforms and rotations.
/// Other ancestor clips use Flutter's approximate bounds. Sibling occlusion
/// and partial opacity are not pixel-tested.
@internal
double visibleFraction(RenderBox target) {
  if (!_validTarget(target)) {
    return 0;
  }
  final corners = _corners(target.size);
  final visible = _visiblePolygon(target, corners);
  final whole = _transform(corners, target.getTransformTo(null));

  return _fraction(visible, whole);
}

bool _validTarget(RenderBox target) =>
    target.attached &&
    target.hasSize &&
    !target.size.isEmpty &&
    _proxyPainted(target);

bool _proxyPainted(RenderBox target) {
  RenderBox current = target;
  while (current is RenderProxyBox && current.child != null) {
    final child = current.child!;
    if (!current.paintsChild(child)) {
      return false;
    }
    current = child;
  }

  return true;
}

List<Offset> _corners(Size size) => [
  Offset.zero,
  Offset(size.width, 0),
  Offset(size.width, size.height),
  Offset(0, size.height),
];

List<Offset> _visiblePolygon(RenderBox target, List<Offset> corners) {
  var polygon = corners;
  for (final (child, parent) in renderAncestors(target)) {
    polygon = _atParent(polygon, child, parent);
  }

  return polygon;
}

List<Offset> _atParent(
  List<Offset> polygon,
  RenderObject child,
  RenderObject parent,
) {
  if (!parent.paintsChild(child)) {
    return [];
  }
  // getTransformTo(null) uses logical view pixels, excluding the root DPR.
  if (parent is RenderView) {
    return _clipRect(polygon, Offset.zero & parent.size);
  }

  return _transformAndClip(polygon, child, parent);
}

List<Offset> _transformAndClip(
  List<Offset> polygon,
  RenderObject child,
  RenderObject parent,
) {
  final transformed = _transform(polygon, child.getTransformTo(parent));
  final clip = renderClipBounds(parent, child);

  return clip == null ? transformed : _clipRect(transformed, clip);
}

List<Offset> _transform(List<Offset> points, Matrix4 transform) {
  final result = points
      .map((point) => MatrixUtils.transformPoint(transform, point))
      .toList();

  return result.any((point) => !point.isFinite) ? [] : result;
}

double _fraction(List<Offset> visible, List<Offset> whole) {
  final area = _area(whole);
  if (!area.isFinite || area <= 0) {
    return 0;
  }

  return (_area(visible) / area).clamp(0, 1);
}

double _area(List<Offset> points) {
  var area = 0.0;
  if (points.length < 3) {
    return area;
  }
  var previous = points.last;
  for (final point in points) {
    area += _cross(previous, point);
    previous = point;
  }

  return area.abs() / 2;
}

double _cross(Offset from, Offset to) => from.dx * to.dy - to.dx * from.dy;

List<Offset> _clipRect(List<Offset> points, Rect rect) {
  var clipped = points;
  for (final edge in _edges(rect)) {
    clipped = edge.clip(clipped);
  }

  return clipped;
}

List<_ClipEdge> _edges(Rect rect) => [
  _ClipEdge(Axis.horizontal, rect.left, keepGreater: true),
  _ClipEdge(Axis.horizontal, rect.right, keepGreater: false),
  _ClipEdge(Axis.vertical, rect.top, keepGreater: true),
  _ClipEdge(Axis.vertical, rect.bottom, keepGreater: false),
];

class _ClipEdge {
  const _ClipEdge(this.axis, this.bound, {required this.keepGreater});

  final Axis axis;
  final double bound;
  final bool keepGreater;

  double _coordinate(Offset point) =>
      axis == Axis.horizontal ? point.dx : point.dy;

  bool _inside(Offset point) =>
      keepGreater ? _coordinate(point) >= bound : _coordinate(point) <= bound;

  Offset _intersection(Offset from, Offset to) {
    final start = _coordinate(from);
    final fraction = (bound - start) / (_coordinate(to) - start);

    return Offset.lerp(from, to, fraction)!;
  }

  List<Offset> clip(List<Offset> points) {
    if (points.isEmpty) {
      return points;
    }
    final result = <Offset>[];
    var previous = points.last;
    for (final point in points) {
      _append(result, previous, point);
      previous = point;
    }

    return result;
  }

  void _append(List<Offset> result, Offset previous, Offset point) {
    final inside = _inside(point);
    if (inside != _inside(previous)) {
      result.add(_intersection(previous, point));
    }
    if (inside) {
      result.add(point);
    }
  }
}
