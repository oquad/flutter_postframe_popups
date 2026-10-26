# Binding widgets in 0.3.0

All four widgets build their child immediately and own their subscription or
measurement lifetime. PostFrameSize delivers measurements after a completed
frame; the Observed widgets receive system and input events immediately.
OS memory/lifecycle events and pointer routing must not wait for a frame that might never arrive while
the application is paused.

## Measurement

PostFrameSpotlight composes PostFrameSize for its initial size instead of
maintaining a separate measuring key or scheduler. Spotlight only adds overlay
ownership, transform/visibility validation, and mask presentation. Later overlay
layouts use OverlayPortal's current geometry, including scroll transforms.

PostFrameSize uses a RenderProxyBox to read actual layout size, including
the initial layout and later resizes. It coalesces multiple layouts in one
frame, compares sizes, and delivers the final value after that frame. It
neither polls nor schedules frames just to check for changes. Callback-only
use does not rebuild the wrapper. The optional builder sees null initially,
then updates on a following frame with the stable measured child.

Return that child exactly once. Decorations around it are not measured;
neither are transforms, shadows, or OverflowBox paint overflow. The widget
does not require an application-owned GlobalKey. Zero layout sizes are valid.

Equality checks prevent redundant rebuilds, but cannot solve cyclic layout:
do not change the target's constraints based on its own reported size. For
same-frame parent-constraint decisions use LayoutBuilder. For arrangements
depending on sibling sizes use a custom layout delegate. Do not promise
arbitrary self-measurement with zero additional frames.

References: [RenderProxyBox](https://api.flutter.dev/flutter/rendering/RenderProxyBox-class.html),
[post-frame scheduling](https://api.flutter.dev/flutter/scheduler/SchedulerBinding/addPostFrameCallback.html),
[layout notifications and their timing](https://api.flutter.dev/flutter/widgets/LayoutChangedNotification-class.html).
SizeChangedLayoutNotifier omits initial layout and notifies during layout,
so it is not used as a substitute for safe builder updates here.
Existing packages also address this space, including
[measure_size](https://pub.dev/packages/measure_size); this release focuses on
the package's existing context-aware callbacks and lifecycle ownership.

## Memory pressure

ObservedMemoryPressure owns a WidgetsBindingObserver. Its callback runs
immediately on a system notification, even without a subsequent frame.
Concurrent notifications coalesce while cleanup is running; a later
notification may start another cleanup. Cleanup should promptly release
references before awaiting work. It does not force garbage collection.

Flutter's PaintingBinding already clears its ordinary image cache. Apps may
release custom previews, caches, or bounded histories via closures over Bloc,
Riverpod, repositories, or ordinary objects without adding those dependencies
here. Each mounted wrapper is independent; mount once for app-wide cleanup
or use separate wrappers for independently owned resources. No automatic
global-state purge, cleanup ordering across wrappers, or pre-termination
warning is promised. Never depend on an async cleanup completing before exit.

References: [memory notifications](https://api.flutter.dev/flutter/widgets/WidgetsBindingObserver/didHaveMemoryPressure.html),
[Flutter image-cache handling](https://api.flutter.dev/flutter/painting/PaintingBinding/handleMemoryPressure.html).

## Pointer observation

ObservedGestures adds a global PointerRouter route while mounted and
removes that exact route on disposal. It has no Listener wrapper, hit-test
entry, recognizer, or gesture-arena participation. Buttons, scrolling, and
text selection retain their ordinary behavior. Listener itself is a valid
subtree tool; global observation is needed here to see events outside the
widget's hit-test subtree.

The original PointerEvent is passed through, including viewId and its global
coordinates. Each wrapper receives all Flutter-routed events, including hover
and signals; mounted wrappers in hidden routes still listen. Place one near
the app root. Native views or other engines may consume events before Flutter
sees them, so this is not an OS-wide interception or complete replay API.

Callbacks run immediately and may overlap if async. Keep them short and do
sampling/batching in the consumer. The widget has no event buffer, network
sender, recording system, or gesture-cancellation capability.

Reference: [global pointer routes](https://api.flutter.dev/flutter/gestures/PointerRouter/addGlobalRoute.html).

## App lifecycle

ObservedAppLifecycle owns Flutter's AppLifecycleListener. The optional builder
starts with the binding's current state, possibly null before initialization.
Callbacks receive distinct transitions and no synthetic initial callback.
State changes are processed immediately; a paused app may not render the
builder's updated UI until it resumes. Callback-only use adds no rebuild.

Do not assume that every lifecycle event or an exit warning will arrive.
Inactive is different from hidden and paused; use the states appropriate for
your platform and workload. Reacting to inactive can reduce sensitive content
exposure, but a Dart rebuild alone cannot guarantee protection of the OS app
switcher snapshot. Platform security configuration may be necessary.

Lifecycle callback futures are not serialized: a slow pause callback must not
overwrite newer resumed state in your playback/sync layer. Return/await work
to route errors through onError. Removing the wrapper removes the listener,
but cannot cancel already-started asynchronous work.

References: [AppLifecycleListener](https://api.flutter.dev/flutter/widgets/AppLifecycleListener-class.html),
[state meanings and skipped notifications](https://api.flutter.dev/flutter/dart-ui/AppLifecycleState.html).

## Error and testing policy

Callbacks share the existing PostFrameCallback runner: synchronous and
returned-future failures go to onError, or FlutterError.reportError. If an
error handler throws, both failures are reported. In-flight work captures its
handler at invocation and can still report after disposal. User callbacks
must check context.mounted after their own awaits. Builder failures use
Flutter's ordinary build-error handling. No GuardZone is created.

The memory/lifecycle widgets accept testing-only binding overrides and the
pointer widget accepts a testing-only PointerRouter. Both constructor formals
and fields carry visibleForTesting. Overrides are captured once per State;
use a new key to switch infrastructure. Normal rebuilds use updated callbacks.
