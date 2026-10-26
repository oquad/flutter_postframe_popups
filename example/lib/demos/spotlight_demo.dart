import 'package:flutter/material.dart';
import 'package:flutter_postframe_popups/flutter_postframe_popups.dart';

import '../content/spotlight_target.dart';

/// Highlights a measured child using an oval hole with room for overflow.
class SpotlightDemo extends StatelessWidget {
  /// Creates the spotlight usage demo.
  const SpotlightDemo({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: PostFrameSpotlight(
      clipper: SpotlightRRectClipper(
        borderRadius: BorderRadius.all(Radius.circular(32)),
      ),
      maskInsets: EdgeInsets.all(-16),
      child: SpotlightTarget(),
    ),
  );
}
