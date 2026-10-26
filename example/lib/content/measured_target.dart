import 'package:flutter/material.dart';

/// Stable example content whose layout is independent of its measurement.
class MeasuredTarget extends StatelessWidget {
  /// Creates a small panel with known layout constraints.
  const MeasuredTarget({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 180,
    height: 72,
    child: Card(child: Center(child: Text('Measured content'))),
  );
}
