import 'package:flutter/widgets.dart';

/// An elliptical spotlight cutout filling the supplied size.
class SpotlightOvalClipper extends CustomClipper<Path> {
  /// Creates an oval cutout; equal width and height produce a circle.
  const SpotlightOvalClipper();

  @override
  Path getClip(Size size) => Path()..addOval(Offset.zero & size);

  @override
  bool shouldReclip(SpotlightOvalClipper oldClipper) => false;
}

/// A rounded-rectangle spotlight cutout filling the supplied size.
class SpotlightRRectClipper extends CustomClipper<Path> {
  /// Creates a rounded rectangle with a default corner radius of 12.
  const SpotlightRRectClipper({
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  /// Corner radii in the target's local logical pixels, before transforms.
  final BorderRadius borderRadius;

  @override
  Path getClip(Size size) =>
      Path()..addRRect(borderRadius.toRRect(Offset.zero & size));

  @override
  bool shouldReclip(SpotlightRRectClipper oldClipper) =>
      borderRadius != oldClipper.borderRadius;
}
