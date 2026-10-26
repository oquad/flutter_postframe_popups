import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Presents a raw event as labeled diagnostic fields without parsing strings.
class PointerEventDetails extends StatelessWidget {
  /// Creates a scrollable event inspector, or an empty-state prompt.
  const PointerEventDetails({super.key, required this.event});

  /// The latest observed event; null before input reaches the router.
  final PointerEvent? event;

  @override
  Widget build(BuildContext context) {
    final current = event;

    return current == null
        ? const Center(child: Text('Tap anywhere'))
        : _EventCard(event: current);
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final PointerEvent event;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: _card,
      ),
    ),
  );

  Widget get _card => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: _EventContent(event: event),
    ),
  );
}

class _EventContent extends StatelessWidget {
  const _EventContent({required this.event});

  final PointerEvent event;

  Iterable<DiagnosticsNode> get _properties {
    final builder = DiagnosticPropertiesBuilder();
    event.debugFillProperties(builder);

    return builder.properties.where(
      (node) => !node.isFiltered(DiagnosticLevel.fine),
    );
  }

  Widget _heading(BuildContext context) => Text(
    event.runtimeType.toString(),
    style: Theme.of(context).textTheme.titleLarge,
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(context),
      const Divider(height: 24),
      for (final node in _properties) _EventField(node: node),
    ],
  );
}

class _EventField extends StatelessWidget {
  const _EventField({required this.node});

  final DiagnosticsNode node;

  Widget get _label => SizedBox(
    width: 112,
    child: Text(
      node.name ?? 'Details',
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
  );

  Widget get _value => Expanded(
    child: SelectableText(
      node.toDescription(),
      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_label, const SizedBox(width: 12), _value],
    ),
  );
}
