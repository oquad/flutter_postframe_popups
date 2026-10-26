import 'package:flutter/material.dart';

/// Country picker content, independent of PostFrame presentation.
class CountryDialog extends StatelessWidget {
  /// Creates the country picker.
  const CountryDialog({super.key});

  @override
  Widget build(BuildContext context) => SimpleDialog(
    title: const Text('Choose a country'),
    children: [
      for (final country in ['Belgium', 'France', 'Italy'])
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(country),
          child: Text(country),
        ),
    ],
  );
}
