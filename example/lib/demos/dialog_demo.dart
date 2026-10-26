import 'package:flutter/material.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';

import '../content/country_dialog.dart';
import '../support/feedback.dart';
import '../support/presenters.dart';

/// Presents initial dialog content while retaining the screen underneath.
class DialogDemo extends StatelessWidget {
  /// Creates the dialog usage demo.
  const DialogDemo({super.key});

  @override
  Widget build(BuildContext context) => PostFrameDialog<String>(
    dialog: const CountryDialog(),
    customShowDialog: showCountryDialog,
    onResult: showSelection,
    child: const Center(child: Text('Country settings')),
  );
}
