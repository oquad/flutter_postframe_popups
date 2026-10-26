# Visible-area triggers

PostFrameCallback, PostFrameDialog, and PostFrameBottomSheet share the
triggerVisibleArea parameter, a fraction from zero to one. Invalid values,
including NaN, are rejected by constructor assertions.

Zero preserves the previous behavior: schedule from initState and execute after
the first frame, regardless of visibility. It does not invoke a callback or
open a route inside initState/build. Positive fractions wait for the target's
visible area to reach that fraction. One means fully visible; 0.5 means half.
Targets with zero area cannot satisfy a positive threshold. A target larger
than its viewport may never reach one; choose a smaller threshold if appropriate.

## Geometry

The target is the wrapper's child layout box, rather than its descendants'
paint overflow. Wrap a particular scrollable item to track that item, rather
than wrapping the entire scrollable viewport.

Rectangular clips are intersected as polygons in each ancestor's coordinate
system. This handles nested viewports, translations, scales, rotations, and
view-edge clipping without treating a rotated bounding box as fully visible.
Root view clipping uses logical pixels and respects the view's pixel ratio.

Scroll viewport extents count as bounds even when Clip.none permits painted
overflow. Offstage and fully transparent ancestors do not satisfy a positive
threshold. Other custom/rounded clips use Flutter's approximate clip bounds;
partial opacity, arbitrary canvas clips, and occlusion by unrelated siblings
are not pixel-tested. This is a geometric visibility policy.

## Timing and ownership

Composition callbacks observe changes even when ancestors retain cached
repaint boundaries. Notifications execute after that frame, with no periodic
timer, visibility polling, or request for frames just to wait for visibility.
No runtime dependency or global visibility controller is added.

The callback runs once per State. Scrolling out and back, rebuilding, or changing
thresholds after execution does not replay it. Before execution, the latest
threshold, callback, and error handler apply. Lowering a waiting threshold to
zero schedules first-frame behavior. A new key or remount starts a new lifetime.
Removing the wrapper cancels observation and skips pending execution. Started
asynchronous work retains the existing error policy after disposal.

A lazy child has no State before it is built, so no callback can run before
that point. Cached items may initialize while offscreen; positive thresholds
wait for them to enter the viewport. There is no auto-scroll or dwell-time
requirement. Dialog and sheet route/result behavior is otherwise unchanged.

## References

- [Layer composition callbacks](https://api.flutter.dev/flutter/rendering/Layer/addCompositionCallback.html)
- [Post-frame callback timing](https://api.flutter.dev/flutter/scheduler/SchedulerBinding/addPostFrameCallback.html)
- [Approximate ancestor clip bounds](https://api.flutter.dev/flutter/rendering/RenderObject/describeApproximatePaintClip.html)
