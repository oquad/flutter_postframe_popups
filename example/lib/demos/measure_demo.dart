import 'package:flutter/material.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';

import '../content/measured_target.dart';

/// Displays the completed layout size beside a stable target.
class MeasureDemo extends StatelessWidget {
  /// Creates the measurement demo.
  const MeasureDemo({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: PostFrameSize(builder: _withSize, child: MeasuredTarget()),
  );
}

Widget _withSize(BuildContext _, Size? size, Widget child) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [child, Text(size == null ? 'Measuring' : 'Measured: $size')],
);
