import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'spotlight_geometry.dart';
import 'spotlight_tap_observer.dart';

/// A clipped barrier; the transparent cutout also passes pointer hits through.
@internal
class SpotlightMask extends StatelessWidget {
  /// Creates a barrier using measured target-local geometry.
  const SpotlightMask({
    super.key,
    required this.geometry,
    required this.clipper,
    required this.color,
    required this.onDismiss,
    required this.onCutoutTap,
    required this.label,
  });

  /// Target bounds and transform into the overlay coordinate system.
  final SpotlightGeometry geometry;

  /// Produces the cutout in its inset-adjusted local size.
  final CustomClipper<Path> clipper;

  /// Color painted outside the cutout.
  final Color color;

  /// Optional dismissal action; the mask still blocks outside hits when null.
  final VoidCallback? onDismiss;

  /// Observes cutout taps without consuming the underlying child's gestures.
  final VoidCallback? onCutoutTap;

  /// Accessible description of the mask's dismissal action.
  final String label;

  @override
  Widget build(BuildContext context) =>
      SizedBox.expand(child: _observeCutout(_MaskClipper(geometry, clipper)));

  Widget _observeCutout(CustomClipper<Path> maskClipper) {
    final mask = _buildMask(maskClipper);
    final onTap = onCutoutTap;
    if (onTap == null) {
      return mask;
    }

    return SpotlightTapObserver(
      clipper: maskClipper,
      onTap: onTap,
      child: mask,
    );
  }

  Widget _buildMask(CustomClipper<Path> maskClipper) => ClipPath(
    key: const ValueKey('postframe.spotlight.mask'),
    clipper: maskClipper,
    child: _MaskBarrier(color: color, onDismiss: onDismiss, label: label),
  );
}

class _MaskBarrier extends StatelessWidget {
  const _MaskBarrier({
    required this.color,
    required this.onDismiss,
    required this.label,
  });

  final Color color;
  final VoidCallback? onDismiss;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: onDismiss != null,
    onTap: onDismiss,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onDismiss,
      child: ColoredBox(color: color),
    ),
  );
}

class _MaskClipper extends CustomClipper<Path> {
  _MaskClipper(this.geometry, this.delegate) : super(reclip: delegate);

  final SpotlightGeometry geometry;
  final CustomClipper<Path> delegate;

  @override
  Path getClip(Size size) {
    final localHole = delegate
        .getClip(geometry.maskRect.size)
        .shift(geometry.maskRect.topLeft);
    final hole = localHole.transform(geometry.transform.storage);
    final outside = Path()..addRect(Offset.zero & size);

    // Boolean path operations normalize contours. Explicit parity preserves
    // their holes on web renderers that return the result with nonzero fill.
    return Path.combine(PathOperation.difference, outside, hole)
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(_MaskClipper oldClipper) =>
      delegate != oldClipper.delegate ||
      geometry.maskRect != oldClipper.geometry.maskRect ||
      geometry.transform != oldClipper.geometry.transform;
}
