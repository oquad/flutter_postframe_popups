import 'dart:typed_data';

/// Small app-owned cache, independent of framework binding subscriptions.
class PreviewCache {
  /// Starts with a few disposable previews for the memory-pressure demo.
  PreviewCache() {
    refill();
  }

  final _previews = <Uint8List>[];

  /// Number of cached previews.
  int get length => _previews.length;

  /// Creates four small, disposable buffers without retaining earlier ones.
  void refill() {
    clear();
    _previews.addAll(List.generate(4, (_) => Uint8List(64 * 1024)));
  }

  /// Releases references so their buffers may be collected.
  void clear() => _previews.clear();
}
