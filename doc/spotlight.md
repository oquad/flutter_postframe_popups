# Spotlight geometry

PostFrameSpotlight builds its child normally, then measures that child's first
RenderBox after layout. The overlay belongs to OverlayPortal and disappears
when the wrapper is removed. The rounded-rectangle clipper is the default;
SpotlightOvalClipper supplies a true ellipse.

## Bounds and overflow

The baseline is the child's layout size, not a union of descendant paint bounds.
An OverflowBox can paint content larger than its own layout box. Place the
spotlight at the layout boundary you want to measure, then set maskInsets to
account for intentional overflow.

Positive insets shrink the hole. Negative insets expand it. Asymmetric and
EdgeInsetsDirectional values are supported; directional values use the nearest
Directionality. Insets and rounded-rectangle radii use target-local logical
pixels. The full local path is then transformed into the selected Overlay, so
ancestor scale and rotation apply to the cutout too.

The overlay follows layout size and scroll transforms. It does not continuously
request frames. It updates on frames Flutter is already producing.

## Custom shapes

Supply CustomClipper<Path>. Its getClip receives the inset-adjusted size at an
origin of zero. PostFrame shifts that path into the local target rectangle,
transforms it into overlay coordinates, and subtracts it from the barrier.
CustomClipper reclip notifications are supported.

Flutter's ShapeBorderClipper works with CircleBorder, StadiumBorder, StarBorder,
or other ShapeBorder implementations. Custom clipper paint failures use
Flutter's rendering error path, like an ordinary ClipPath.

## Visibility policy

The full layout rectangle must be visible, even when insets shrink the hole.
Offscreen and partially clipped targets raise SpotlightTargetNotVisibleError.
The error goes to onError, or FlutterError.reportError when no handler is set.
There is no automatic scroll, wait, or retry. Errors detected while a visible
spotlight moves offscreen remove the mask and report once, without invoking
onDismissed.

Validation checks the overlay rectangle, scroll viewport rectangles, ancestor
paint participation, and available ancestor clip bounds. ClipRect delegates
are measured directly; other clipping uses Flutter's approximate clip bounds.
This is a geometry check, not a pixel-visibility proof. An unrelated opaque
sibling, a rounded clip's corners, and arbitrary custom painting may obscure
pixels without changing those bounds.

CompositedTransformFollower ancestors are rejected with UnsupportedError because
their transform is established during compositing, after overlay layout.
An unbuilt lazy-list item has no mounted spotlight and cannot run a callback.
A built, cached offscreen target is rejected normally.

## Interaction and lifetime

The mask consumes pointer events outside the hole. Inside the hole, events pass
through to the original child; that child keeps its normal state and layout.
The shaded area has an accessible dismissal label. This is a visual overlay,
not a modal route or focus trap.

Tapping inside the cutout dismisses by default while still activating the
underlying child. Set dismissOnCutoutTap to false to keep the spotlight open
while interacting with the highlighted area. Drags, long presses, cancelled
pointers, and secondary mouse buttons do not count as cutout taps. Insets apply
to the interactive hole too, including expanded areas outside the child.

Tapping the shaded area also dismisses by default. barrierDismissible controls
that action independently of dismissOnCutoutTap. The parent can always remove the wrapper. onDismissed runs only
for user dismissal while mounted and may return a Future. Its errors use the
same PostFrameCallback error handling as the other package widgets.

Presentation runs once per State. Changes to visual configuration update an
active mask; rebuilds do not reopen a dismissed mask. The dismissal callback
and error handler are captured when presentation starts. Remount or use a fresh
key to start again.

See [the scrolling roadmap](roadmap.md) for planned PostFrameScrollTo composition.
