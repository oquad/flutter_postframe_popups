Show a popup, highlight a button for a tutorial, or run a callback after the child's first frame is drawn.
Your screen's `child` builds immediately.

![PostFrame widgets demo](demo.webp)

Imports, app scaffolding, and supporting widgets are omitted below.

### Callback

```dart
PostFrameCallback(
  callback: showReadyMessage,
  child: const Text('Home'),
)
```

[Callback demo](example/lib/demos/callback_demo.dart) ·
[Feedback callbacks](example/lib/support/feedback.dart)

### Dialog

```dart
PostFrameDialog<String>(
  dialog: const CountryDialog(),
  onResult: showSelection,
  child: const Text('Country settings'),
)
```

[Dialog demo](example/lib/demos/dialog_demo.dart) ·
[Dialog content](example/lib/content/country_dialog.dart)

### Bottom sheet

```dart
PostFrameBottomSheet<String>(
  bottomSheet: const SortSheet(),
  onResult: showSelection,
  child: const Text('Items'),
)
```

[Sheet demo](example/lib/demos/bottom_sheet_demo.dart) ·
[Sheet content](example/lib/content/sort_sheet.dart)

### Spotlight

```dart
PostFrameSpotlight(
  clipper: const SpotlightOvalClipper(),
  maskInsets: const EdgeInsets.all(-8),
  child: const SpotlightTarget(),
)
```

The default shape is `SpotlightRRectClipper`. Positive insets shrink the hole;
negative values expand it for `OverflowBox` or other painted overflow. Bounds
come from the child's exact layout size, before those insets and ancestor
transforms are applied.

Use any `CustomClipper<Path>`, including Flutter's built-in shape clipper:

```dart
clipper: const ShapeBorderClipper(shape: StarBorder()),
```

The hole passes taps through; tapping the hole or shade dismisses the spotlight.
Set `dismissOnCutoutTap: false` to keep it open when the child is tapped.
`barrierDismissible` controls shade taps independently. Offscreen or
partially clipped targets raise `SpotlightTargetNotVisibleError` through the
shared `onError` policy. Automatic scrolling is not implemented.

[Spotlight demo](example/lib/demos/spotlight_demo.dart) ·
[Geometry and visibility](doc/spotlight.md) ·
[PostFrameScrollTo plan](doc/roadmap.md)

### Measure

```dart
PostFrameSize(
  builder: (context, size, child) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [child, Text(size?.toString() ?? 'Measuring')],
  ),
  child: const Text('Measured content'),
)
```

Measures the stable child after layout, starting with `null` in the builder.
Only distinct sizes update it. Optional `onMeasured(context, size)` supports
sync/async callbacks. Keep the target's constraints independent of its measured
size; a post-frame builder necessarily updates on a following frame.

[Measure demo](example/lib/demos/measure_demo.dart)

### Memory pressure

```dart
ObservedMemoryPressure(
  onMemoryPressure: releaseCachedPreviews,
  child: const Text('Preview library'),
)
```

Release app-owned caches or histories in your callback. Flutter already clears
its ordinary image cache. Overlapping notifications coalesce while cleanup is
running. No state-management dependency or automatic deletion of app state.

[Memory demo](example/lib/demos/memory_pressure_demo.dart) ·
[App-owned cache](example/lib/content/preview_cache.dart)

### Global pointer events

```dart
ObservedGestures(
  onPointerEvent: recordPointer,
  child: const Text('Analytics workspace'),
)
```

Observes Flutter-routed events across the app without consuming gestures.
Mount once near the app root. Events consumed entirely by native views are
outside this contract; the widget does not store or transmit events.

[Pointer demo](example/lib/demos/pointer_listener_demo.dart)

### App lifecycle

```dart
ObservedAppLifecycle(
  onStateChanged: updatePlayback,
  child: const Text('Player'),
)
```

Optional `builder(context, state, child)` exposes the current OS lifecycle
state declaratively. Callbacks receive transitions without an initial replay.
Handle inactive/hidden states when appropriate; shutdown notifications are
not guaranteed.

[Lifecycle demo](example/lib/demos/app_lifecycle_demo.dart)

Memory, pointer, and lifecycle subscriptions react immediately while mounted;
they do not wait for a rendered frame. All use the shared `onError` policy.
See [binding behavior and design references](doc/bindings.md).

### Presentation options

Use `customShowDialog` or `customShowBottomSheet` to configure Flutter's native
presentation function. The presenter receives `context` and `builder`:

```dart
customShowDialog: ({required context, required builder}) => showDialog<String>(
  context: context,
  builder: builder,
  useRootNavigator: false,
  barrierDismissible: false,
),
```

[Custom presenters](example/lib/support/presenters.dart)

### Behavior

- Callback, dialog, sheet, and spotlight presentation run once per mount.
  Measurement follows distinct sizes; OS and pointer subscriptions stay active
  until disposal. Rebuilds update callbacks without duplicating subscriptions.
- `onResult(context, value)` receives the typed result, including null on dismissal,
  while the wrapper remains mounted.
- `callback` and `onResult` may be async. Return or await work whose errors should
  reach `onError(error, stackTrace)`. Without a handler, errors go to
  `FlutterError.reportError`.
- Removing a wrapper does not cancel started work or dismiss an open modal.
- Default presentation uses the root Navigator for dialogs and the nearest
  Navigator for sheets. Modal content needs its own route context to dismiss it.

Development checks live in [CONTRIBUTING.md](CONTRIBUTING.md).
