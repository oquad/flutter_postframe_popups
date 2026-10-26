import 'package:flutter/material.dart';

/// Ordinary cache controls, independent of memory-pressure subscriptions.
class CacheControls extends StatelessWidget {
  /// Creates a preview count with manual refill and release actions.
  const CacheControls({
    super.key,
    required this.count,
    required this.onClear,
    required this.onRefill,
  });

  /// Current number of app-owned previews.
  final int count;

  /// Releases previews using the same cleanup as the OS notification.
  final VoidCallback onClear;

  /// Adds a few previews for another demonstration.
  final VoidCallback onRefill;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('Cached previews: $count'),
      TextButton(onPressed: onClear, child: const Text('Release previews')),
      TextButton(onPressed: onRefill, child: const Text('Refill previews')),
      const Text('OS memory pressure invokes the same cleanup.'),
    ],
  );
}
