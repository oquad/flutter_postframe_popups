import 'dart:async';

import 'package:flutter/widgets.dart';

import 'post_frame_size.dart';
import 'post_frame_types.dart';
import 'spotlight/spotlight_clippers.dart';
import 'spotlight/spotlight_geometry.dart';
import 'spotlight/spotlight_mask.dart';
import 'spotlight/spotlight_target_not_visible_error.dart';

/// Highlights [child] once after layout using an overlay with a shaped cutout.
///
/// Uses [PostFrameSize] for the child's layout bounds, not the union of descendant
/// painting. Positive [maskInsets] shrink the hole; negative values expand it
/// for OverflowBox, shadows, or other intentional overflow. Insets and radii
/// use target-local logical pixels before ancestor transforms are applied.
///
/// The full target rectangle must be within its Overlay and ancestor viewport
/// and clip bounds. Otherwise [SpotlightTargetNotVisibleError] is delivered to
/// [onError], or FlutterError.reportError. Nothing is scrolled automatically.
/// An unbuilt lazy-list item cannot run a post-frame callback.
///
/// The overlay follows layout/scroll transform and size changes. If an update
/// makes the target invalid, it removes the mask and reports the failure once.
/// Visibility is geometric: sibling occlusion and custom paint-only clipping
/// cannot be proven. CompositedTransformFollower ancestors are unsupported by
/// Flutter's OverlayPortal layout builder.
///
/// The cutout passes pointer events through. Taps inside the cutout or on the
/// shaded area dismiss it by default. Disposal removes the owned overlay.
/// There is no focus trap, route, scrolling, or automatic replay on rebuilds.
class PostFrameSpotlight extends StatefulWidget {
  /// Creates a spotlight with a rounded-rectangle cutout by default.
  const PostFrameSpotlight({
    super.key,
    required this.child,
    this.clipper = const SpotlightRRectClipper(),
    this.maskInsets = EdgeInsets.zero,
    this.barrierColor = const Color(0xB3000000),
    this.barrierDismissible = true,
    this.dismissOnCutoutTap = true,
    this.barrierLabel = 'Dismiss spotlight',
    this.overlayLocation = OverlayChildLocation.nearestOverlay,
    this.onDismissed,
    this.onError,
  });

  /// The target; laid out and painted normally beneath the overlay.
  final Widget child;

  /// Cutout shape in an origin-based rectangle of the inset-adjusted size.
  ///
  /// Accepts the preset clippers, ShapeBorderClipper, or `CustomClipper<Path>`.
  /// Delegate reclip notifications update the mask without rebuilding the child.
  final CustomClipper<Path> clipper;

  /// Positive values shrink the mask; negative values expand it for overflow.
  final EdgeInsetsGeometry maskInsets;

  /// The dimming color outside the transparent cutout.
  final Color barrierColor;

  /// Whether tapping the shaded area dismisses the overlay.
  final bool barrierDismissible;

  /// Whether tapping inside the cutout also dismisses the spotlight.
  ///
  /// Defaults to true. The underlying child still receives the tap. Set false
  /// to keep the spotlight visible while interacting with the highlighted area.
  /// Drags, long presses, and secondary mouse buttons do not dismiss it.
  /// Independent of [barrierDismissible].
  final bool dismissOnCutoutTap;

  /// Accessible label for the shaded area; provide a localized label as needed.
  final String barrierLabel;

  /// Overlay ownership and coordinate space, matching OverlayPortal.
  final OverlayChildLocation overlayLocation;

  /// Runs after user dismissal while this wrapper is still mounted.
  ///
  /// May be async. Does not run for disposal or a visibility failure.
  final PostFrameCallbackFunction? onDismissed;

  /// Handles geometry and dismissal-callback failures instead of FlutterError.
  ///
  /// Custom clipper paint errors follow Flutter's normal rendering error path.
  final PostFrameErrorHandler? onError;

  @override
  State<PostFrameSpotlight> createState() => _PostFrameSpotlightState();
}

class _PostFrameSpotlightState extends State<PostFrameSpotlight> {
  final _portal = OverlayPortalController();
  late final BuildContext _targetContext;
  bool _started = false;
  Completer<void>? _session;

  @override
  Widget build(BuildContext context) => PostFrameSize(
    onMeasured: _show,
    onError: widget.onError,
    child: OverlayPortal.overlayChildLayoutBuilder(
      controller: _portal,
      overlayLocation: widget.overlayLocation,
      overlayChildBuilder: _buildOverlay,
      child: widget.child,
    ),
  );

  Future<void> _show(BuildContext context, Size size) async {
    if (_started) {
      return;
    }
    _started = true;
    _targetContext = context;
    _measure(size);
    await _present(context);
  }

  Future<void> _present(BuildContext context) async {
    final onDismissed = widget.onDismissed;
    final session = Completer<void>();
    _session = session;
    _portal.show();
    await session.future;
    if (context.mounted) {
      await onDismissed?.call(context);
    }
  }

  RenderBox get _overlay =>
      Overlay.of(
            context,
            rootOverlay:
                widget.overlayLocation == OverlayChildLocation.rootOverlay,
          ).context.findRenderObject()!
          as RenderBox;

  SpotlightGeometry _measure(Size size, [OverlayChildLayoutInfo? layoutInfo]) =>
      SpotlightGeometry.measure(
        _targetContext.findRenderObject()! as RenderBox,
        _overlay,
        widget.maskInsets.resolve(Directionality.of(context)),
        size: size,
        layoutInfo: layoutInfo,
      );

  Widget _maskFor(OverlayChildLayoutInfo info) => SpotlightMask(
    geometry: _measure(info.childSize, info),
    clipper: widget.clipper,
    color: widget.barrierColor,
    label: widget.barrierLabel,
    onDismiss: widget.barrierDismissible ? _dismiss : null,
    onCutoutTap: widget.dismissOnCutoutTap ? _dismiss : null,
  );

  Widget _buildOverlay(BuildContext _, OverlayChildLayoutInfo info) {
    final session = _session;
    if (session == null || session.isCompleted) {
      return const SizedBox.shrink();
    }
    try {
      return _maskFor(info);
    } catch (error, stackTrace) {
      _fail(error, stackTrace);

      return const SizedBox.shrink();
    }
  }

  void _dismiss() {
    if (_session?.isCompleted ?? true) {
      return;
    }
    _portal.hide();
    _session?.complete();
  }

  void _fail(Object error, StackTrace stackTrace) {
    final session = _session!;
    if (session.isCompleted) {
      return;
    }
    session.completeError(error, stackTrace);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _portal.hide();
      }
    });
  }

  @override
  void dispose() {
    final session = _session;
    if (session != null && !session.isCompleted) {
      session.complete();
    }
    super.dispose();
  }
}
