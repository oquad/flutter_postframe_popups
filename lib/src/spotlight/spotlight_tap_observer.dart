import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Observes pointer taps through a mask without joining the gesture arena.
@internal
class SpotlightTapObserver extends StatefulWidget {
  /// Creates a passive observer for the transparent portion of [clipper].
  const SpotlightTapObserver({
    super.key,
    required this.clipper,
    required this.onTap,
    required this.child,
  });

  /// The opaque mask path; points outside it belong to the cutout.
  final CustomClipper<Path> clipper;

  /// Runs after a primary-pointer tap starts and ends in the cutout.
  final VoidCallback onTap;

  /// The clipped mask, which continues blocking shaded-area hits normally.
  final Widget child;

  @override
  State<SpotlightTapObserver> createState() => _SpotlightTapObserverState();
}

class _SpotlightTapObserverState extends State<SpotlightTapObserver> {
  final _pointers = <int, (Offset, Timer)>{};

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _down,
    onPointerMove: _move,
    onPointerUp: _up,
    onPointerCancel: _cancel,
    child: widget.child,
  );

  bool _inCutout(Offset position) {
    final box = context.findRenderObject()! as RenderBox;

    return !widget.clipper.getClip(box.size).contains(position);
  }

  void _down(PointerDownEvent event) {
    if (event.buttons == kPrimaryButton && _inCutout(event.localPosition)) {
      _pointers[event.pointer] = (
        event.position,
        Timer(kLongPressTimeout, () => _discard(event.pointer)),
      );
    }
  }

  void _move(PointerMoveEvent event) {
    final start = _pointers[event.pointer];
    if (start != null &&
        (event.position - start.$1).distance >
            computeHitSlop(event.kind, null)) {
      _discard(event.pointer);
    }
  }

  void _up(PointerUpEvent event) {
    final start = _discard(event.pointer);
    if (start != null && _inCutout(event.localPosition)) {
      widget.onTap();
    }
  }

  void _cancel(PointerCancelEvent event) => _discard(event.pointer);

  (Offset, Timer)? _discard(int pointer) {
    final start = _pointers.remove(pointer);
    start?.$2.cancel();

    return start;
  }

  @override
  void dispose() {
    for (final start in _pointers.values) {
      start.$2.cancel();
    }
    super.dispose();
  }
}
