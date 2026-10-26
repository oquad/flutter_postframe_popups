import 'package:flutter/material.dart';

/// Sort choices, independent of how the sheet is presented.
class SortSheet extends StatelessWidget {
  /// Creates the sort sheet content.
  const SortSheet({super.key});

  @override
  Widget build(BuildContext context) =>
      const SafeArea(top: false, child: _SortOptions());
}

class _SortOptions extends StatelessWidget {
  const _SortOptions();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final order in ['Newest', 'Oldest'])
        ListTile(
          title: Text(order),
          onTap: () => Navigator.of(context).pop(order),
        ),
    ],
  );
}
