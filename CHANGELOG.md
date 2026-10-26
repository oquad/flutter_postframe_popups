## 0.3.0

* Add PostFrameSize with initial/changed layout sizes, per-frame coalescing, and an optional stable-child builder.
* Add ObservedMemoryPressure for immediate app-owned cleanup, coalescing concurrent notifications.
* Add ObservedGestures for passive global Flutter pointer observation.
* Add ObservedAppLifecycle with OS transitions and an optional state-aware builder.
* Refactor Spotlight to compose PostFrameSize and remove its separate measurement key.
* Share context-aware async error handling across callbacks and observers; unregister subscriptions on disposal.
* Add focused native/Chrome tests, small demos, and binding design references. Keep the example linked to the local package.

## 0.1.0

* Dismiss spotlights on cutout taps by default while preserving child taps; add dismissOnCutoutTap to retain the previous behavior.

* Preserve transparent spotlight holes on Chrome with an explicit even-odd mask fill rule; run spotlight regressions in Chrome as well as the native test renderer.

* Add PostFrameSpotlight with exact layout measurement, overlay ownership, and scroll/resize tracking.
* Add oval and rounded-rectangle presets, signed mask insets, and native CustomClipper<Path> support.
* Reject hidden or clipped targets with SpotlightTargetNotVisibleError; plan PostFrameScrollTo sequencing separately.
* Add spotlight demo, geometry/visibility docs, interaction tests, and a pixel-rendering check.

## 0.0.2

* Reduce README to minimal usage snippets and essential behavior.
* Split example usage from modal content, presenters, feedback, and application scaffolding.
* Move development instructions to CONTRIBUTING.md.

## 0.0.1

* Publish under flutter_postframe_popups.

* Add PostFrameCallback with context-aware sync/async `callback` handling.
* Add const PostFrameDialog<T> and PostFrameBottomSheet<T> wrappers that build their screen child immediately and present separate modal content once after the first frame.
* Customize presentation through CustomShowDialog<T> and CustomShowBottomSheet<T>, with nullable typed results and async result handlers.
* Share disposal checks and error reporting across callbacks and presenters.
* Include a focus recipe using PostFrameCallback and Flutter's built-in autofocus guidance.
* Add strict analyzer rules, free readability metrics, public API documentation, and a repeatable release check.
