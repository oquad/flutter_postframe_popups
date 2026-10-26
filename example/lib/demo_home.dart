import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'demos/app_lifecycle_demo.dart';
import 'demos/bottom_sheet_demo.dart';
import 'demos/callback_demo.dart';
import 'demos/dialog_demo.dart';
import 'demos/focus_demo.dart';
import 'demos/measure_demo.dart';
import 'demos/memory_pressure_demo.dart';
import 'demos/pointer_listener_demo.dart';
import 'demos/spotlight_demo.dart';
import 'demos/visibility_demo.dart';

/// Navigation shell for the independent usage demos.
class DemoHome extends StatefulWidget {
  /// Creates the example navigation shell.
  const DemoHome({super.key});

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PostFrame')),
    body: _DemoBody(selected: _selected),
    bottomNavigationBar: _DemoNavigation(
      selected: _selected,
      onSelected: (index) => setState(() => _selected = index),
    ),
  );
}

class _DemoBody extends StatelessWidget {
  const _DemoBody({required this.selected});

  final int selected;

  static const _demos = [
    CallbackDemo(),
    DialogDemo(),
    BottomSheetDemo(),
    FocusDemo(),
    SpotlightDemo(),
    MeasureDemo(),
    MemoryPressureDemo(),
    PointerListenerDemo(),
    AppLifecycleDemo(),
    VisibilityDemo(),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: KeyedSubtree(key: ValueKey(selected), child: _demos[selected]),
    ),
  );
}

class _DemoNavigation extends StatelessWidget {
  const _DemoNavigation({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.schedule), label: 'Callback'),
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline),
      label: 'Dialog',
    ),
    NavigationDestination(
      icon: Icon(Icons.vertical_align_bottom),
      label: 'Sheet',
    ),
    NavigationDestination(icon: Icon(Icons.keyboard), label: 'Focus'),
    NavigationDestination(icon: Icon(Icons.highlight), label: 'Spotlight'),
    NavigationDestination(icon: Icon(Icons.straighten), label: 'Measure'),
    NavigationDestination(icon: Icon(Icons.memory), label: 'Memory'),
    NavigationDestination(icon: Icon(Icons.touch_app), label: 'Pointers'),
    NavigationDestination(icon: Icon(Icons.sync), label: 'Lifecycle'),
    NavigationDestination(
      icon: Icon(Icons.visibility_outlined),
      label: 'Visibility',
    ),
  ];

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SizedBox(width: _width(context), child: _navigation),
  );

  double _width(BuildContext context) =>
      math.max(MediaQuery.sizeOf(context).width, _destinations.length * 104);

  Widget get _navigation => NavigationBar(
    selectedIndex: selected,
    onDestinationSelected: onSelected,
    destinations: _destinations,
  );
}
