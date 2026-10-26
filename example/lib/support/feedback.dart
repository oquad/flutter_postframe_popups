import 'package:flutter/material.dart';

/// Reports that the callback ran after the screen's initial layout.
void showReadyMessage(BuildContext context) =>
    _showMessage(context, 'Ready after the first frame');

/// Displays a completed selection; dismissal needs no feedback.
void showSelection(BuildContext context, String? value) {
  if (value == null) {
    return;
  }
  _showMessage(context, 'Selected $value');
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
