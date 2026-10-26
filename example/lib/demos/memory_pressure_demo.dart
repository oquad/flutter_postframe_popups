import 'package:flutter/material.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';

import '../content/cache_controls.dart';
import '../content/preview_cache.dart';

/// Releases app-owned buffers on memory pressure or a manual cleanup action.
class MemoryPressureDemo extends StatefulWidget {
  /// Creates the memory-pressure demo.
  const MemoryPressureDemo({super.key});

  @override
  State<MemoryPressureDemo> createState() => _MemoryPressureDemoState();
}

class _MemoryPressureDemoState extends State<MemoryPressureDemo> {
  final _cache = PreviewCache();

  void _release(BuildContext _) => setState(_cache.clear);

  @override
  Widget build(BuildContext context) => ObservedMemoryPressure(
    onMemoryPressure: _release,
    child: Center(
      child: CacheControls(
        count: _cache.length,
        onClear: () => _release(context),
        onRefill: () => setState(_cache.refill),
      ),
    ),
  );
}
