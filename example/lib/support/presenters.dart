import 'package:flutter/material.dart';

/// Uses the nearest Navigator and requires an explicit dialog choice.
Future<String?> showCountryDialog({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showDialog<String>(
  context: context,
  builder: builder,
  useRootNavigator: false,
  barrierDismissible: false,
);

/// Applies application-specific sheet options outside the PostFrame wrapper.
Future<String?> showSortSheet({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showModalBottomSheet<String>(
  context: context,
  builder: builder,
  showDragHandle: true,
  useSafeArea: true,
);
