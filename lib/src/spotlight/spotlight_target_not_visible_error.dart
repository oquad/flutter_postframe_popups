import 'package:flutter/foundation.dart';

/// The spotlight's laid-out target is hidden, clipped, or outside its viewport.
///
/// Delivered through PostFrameSpotlight.onError, or FlutterError.reportError
/// when no handler is provided. No scrolling is performed automatically.
class SpotlightTargetNotVisibleError extends FlutterError {
  /// Creates a visibility failure describing the unpainted or clipped target.
  SpotlightTargetNotVisibleError(String reason)
    : super.fromParts([
        ErrorSummary(
          'PostFrameSpotlight requires a fully visible, laid-out child.',
        ),
        ErrorDescription(reason),
        ErrorHint(
          'Scroll or reveal the target before mounting the spotlight. '
          'PostFrameScrollTo composition is planned, not implemented.',
        ),
      ]);
}
