import 'dart:async';

import 'package:flutter/material.dart';

import 'post_frame_callback.dart';

/// Presents a dialog and returns its result, or null on dismissal.
///
/// Additional optional named parameters are allowed, so Flutter's showDialog
/// and application-specific presenter functions satisfy this contract.
typedef CustomShowDialog<T> =
    FutureOr<T?> Function({
      required BuildContext context,
      required WidgetBuilder builder,
    });

/// Builds [child] immediately and presents [dialog] after the first frame.
///
/// [triggerVisibleArea] optionally waits for the target to enter the viewport.
/// Presentation runs once per mounted instance, not on ordinary rebuilds.
/// A null [customShowDialog] uses Flutter's `showDialog<T>`, which targets the
/// root Navigator. Supply a presenter to configure routing and barrier options.
///
/// Use a Builder or a custom widget inside [dialog] to obtain the dialog
/// route's context for dismissal. The presenter's context and [onResult]'s
/// context belong to this wrapper, not the dialog or descendants of [child].
///
/// [onResult] receives the result, including null on dismissal, only while the
/// wrapper remains mounted. Removing the wrapper does not close an open route
/// or cancel a started presenter. Errors still report after disposal.
///
/// [onError] handles presenter throws, errors from its returned Future, and
/// result-callback failures. Errors while building or interacting with the
/// dialog follow Flutter's normal error handling.
class PostFrameDialog<T> extends StatelessWidget {
  /// Creates a wrapper that presents [dialog] after its first frame.
  const PostFrameDialog({
    super.key,
    required this.child,
    required this.dialog,
    this.onResult,
    this.onError,
    this.triggerVisibleArea = 0,
    this.customShowDialog,
  }) : assert(triggerVisibleArea >= 0 && triggerVisibleArea <= 1);

  /// Underlying screen content, built immediately in this widget's location.
  final Widget child;

  /// Dialog content passed to the presenter through its builder.
  final Widget dialog;

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

  /// Overrides presentation; null uses Flutter's `showDialog<T>`.
  final CustomShowDialog<T>? customShowDialog;

  Widget _buildModal(BuildContext _) => dialog;

  Future<void> _show(BuildContext context) async {
    final CustomShowDialog<T> dialogPresenter =
        customShowDialog ?? showDialog<T>;

    final result = await dialogPresenter.call(
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
