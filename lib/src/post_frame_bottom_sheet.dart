import 'dart:async';

import 'package:flutter/material.dart';

import 'post_frame_callback.dart';

/// Presents a modal bottom sheet and returns its result, or null on dismissal.
///
/// Functions may expose additional optional named parameters. Flutter's
/// `showModalBottomSheet<T>` and application-specific presenters satisfy this
/// contract. Return a synchronous result or a Future in tests.
typedef CustomShowBottomSheet<T> =
    FutureOr<T?> Function({
      required BuildContext context,
      required WidgetBuilder builder,
    });

/// Builds [child] immediately and presents [bottomSheet] after the first frame.
///
/// [triggerVisibleArea] optionally waits for the target to enter the viewport.
/// Presentation runs once per mounted instance, not on ordinary rebuilds.
/// A null [customShowBottomSheet] uses Flutter's `showModalBottomSheet<T>`,
/// which targets the nearest Navigator. Supply a presenter to configure route,
/// barrier, dragging, sizing, keyboard handling, or navigation behavior.
///
/// Use a Builder or a custom widget inside [bottomSheet] to obtain the sheet
/// route's context for dismissal. The presenter's context and [onResult]'s
/// context belong to this wrapper, not the sheet or descendants of [child].
///
/// [onResult] receives the result, including null on dismissal, only while the
/// wrapper remains mounted. Removing the wrapper does not close an open route
/// or cancel a started presenter. Errors still report after disposal.
///
/// [onError] handles presenter throws, errors from its returned Future, and
/// result-callback failures. Errors while building or interacting with the
/// sheet follow Flutter's normal error handling.
class PostFrameBottomSheet<T> extends StatelessWidget {
  /// Creates a wrapper that presents [bottomSheet] after its first frame.
  const PostFrameBottomSheet({
    super.key,
    required this.child,
    required this.bottomSheet,
    this.onResult,
    this.onError,
    this.triggerVisibleArea = 0,
    this.customShowBottomSheet,
  }) : assert(triggerVisibleArea >= 0 && triggerVisibleArea <= 1);

  /// Underlying screen content, built immediately in this widget's location.
  final Widget child;

  /// Sheet content passed to the presenter through its builder.
  final Widget bottomSheet;

  /// Receives the nullable result while this wrapper remains mounted.
  ///
  /// May return a Future. Check context.mounted after your own async gaps.
  final FutureOr<void> Function(BuildContext context, T? result)? onResult;

  /// Handles presenter and result-callback failures instead of FlutterError.
  final PostFrameErrorHandler? onError;

  /// Fraction of [child]'s layout area required on screen before presenting.
  ///
  /// Zero preserves first-frame presentation; 0.5 waits for half and 1 for
  /// complete visibility. Uses [PostFrameCallback.triggerVisibleArea]'s
  /// geometric clip policy and still presents only once per mount.
  final double triggerVisibleArea;

  /// Overrides presentation; null uses Flutter's `showModalBottomSheet<T>`.
  final CustomShowBottomSheet<T>? customShowBottomSheet;

  Widget _buildModal(BuildContext _) => bottomSheet;

  Future<void> _show(BuildContext context) async {
    final CustomShowBottomSheet<T> sheetPresenter =
        customShowBottomSheet ?? showModalBottomSheet<T>;

    final result = await sheetPresenter.call(
      context: context,
      builder: _buildModal,
    );
    if (context.mounted) {
      await onResult?.call(context, result);
    }
  }

  @override
  Widget build(BuildContext context) => PostFrameCallback(
    callback: _show,
    onError: onError,
    triggerVisibleArea: triggerVisibleArea,
    child: child,
  );
}
