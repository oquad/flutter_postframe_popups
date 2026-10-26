import 'package:flutter/material.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';

import '../content/sort_sheet.dart';
import '../support/feedback.dart';
import '../support/presenters.dart';

/// Presents an initial sheet without mixing in its content or route options.
class BottomSheetDemo extends StatelessWidget {
  /// Creates the bottom-sheet usage demo.
  const BottomSheetDemo({super.key});

  @override
  Widget build(BuildContext context) => PostFrameBottomSheet<String>(
    bottomSheet: const SortSheet(),
    customShowBottomSheet: showSortSheet,
    onResult: showSelection,
    child: const Center(child: Text('Items')),
  );
}
