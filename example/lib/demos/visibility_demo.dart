import 'package:flutter/material.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';

import '../content/country_dialog.dart';
import '../content/sort_sheet.dart';
import '../content/visibility_target.dart';
import '../support/feedback.dart';

/// Mounts three offscreen targets and waits for their visible-area thresholds.
class VisibilityDemo extends StatelessWidget {
  /// Creates the scroll-to-reveal demonstration.
  const VisibilityDemo({super.key});

  Widget get _callback => PostFrameCallback(
    triggerVisibleArea: 0.5,
    callback: showReadyMessage,
    child: const VisibilityTarget(label: 'Callback at 50%'),
  );

  Widget get _dialog => PostFrameDialog<String>(
    triggerVisibleArea: 1,
    dialog: const CountryDialog(),
    onResult: showSelection,
    child: const VisibilityTarget(label: 'Dialog at 100%'),
  );

  Widget get _sheet => PostFrameBottomSheet<String>(
    triggerVisibleArea: 0.75,
    bottomSheet: const SortSheet(),
    onResult: showSelection,
    child: const VisibilityTarget(label: 'Sheet at 75%'),
  );

  List<Widget> _targets(BuildContext context) => [
    const Text('Scroll down to reveal each target. Each action runs once.'),
    SizedBox(height: MediaQuery.sizeOf(context).height),
    _callback,
    const SizedBox(height: 400),
    _dialog,
    const SizedBox(height: 400),
    _sheet,
    const SizedBox(height: 200),
  ];

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _targets(context),
    ),
  );
}
