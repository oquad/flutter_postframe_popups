import 'package:flutter/material.dart';

/// A fixed-height target whose visible area is easy to see while scrolling.
class VisibilityTarget extends StatelessWidget {
  /// Creates a labeled target independent of presentation callbacks.
  const VisibilityTarget({super.key, required this.label});

  /// Explains which callback will run and its visibility threshold.
  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 120,
    child: Card(child: Center(child: Text(label))),
  );
}
