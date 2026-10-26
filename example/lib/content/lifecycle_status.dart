import 'package:flutter/material.dart';

/// Displays the current OS state and dims inactive example content.
class LifecycleStatus extends StatelessWidget {
  /// Creates the presentation independently of lifecycle subscriptions.
  const LifecycleStatus({super.key, required this.state, required this.child});

  /// Current state, possibly unknown before the first OS notification.
  final AppLifecycleState? state;

  /// Stable content to dim while inactive.
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [_label, _content]);

  Widget get _label => Text('App state: ${state?.name ?? 'unknown'}');

  Widget get _content => Opacity(
    opacity: state == AppLifecycleState.resumed ? 1 : 0.3,
    child: child,
  );
}
