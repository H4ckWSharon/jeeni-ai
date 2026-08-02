import 'package:flutter/material.dart';
import '../widgets/geometry/circle_area.dart';
import '../widgets/physics/newton_second_law.dart';
import '../widgets/algebra/graph_plotter.dart';
import '../widgets/trigonometry/unit_circle.dart';
import '../widgets/chemistry/atom_builder.dart';
import '../widgets/biology/heart_pump.dart';
import '../widgets/geography/earth_rotation.dart';
import '../widgets/universal/universal_concept_widget.dart';

class WidgetRegistry {
  static final Map<String, Widget Function(BuildContext)> _registry = {
    'circle_area':        (context) => const CircleAreaWidget(),
    'newton_second_law':  (context) => const NewtonSecondLawWidget(),
    'graph_plotter':      (context) => const GraphPlotterWidget(),
    'unit_circle':        (context) => const UnitCircleWidget(),
    'atom_builder':       (context) => const AtomBuilderWidget(),
    'heart_pump':         (context) => const HeartPumpWidget(),
    'earth_rotation':     (context) => const EarthRotationWidget(),
  };

  /// Builds the interactive learning widget corresponding to [id].
  /// Custom specialized widgets are returned for registered core topics.
  /// For all other educational topics, a Universal Concept Engine widget is generated dynamically.
  static Widget buildWidget(String id, BuildContext context) {
    final builder = _registry[id];
    if (builder != null) {
      return builder(context);
    }
    // Universal fallback for any concept in any domain!
    return UniversalConceptWidget(conceptId: id);
  }

  /// Checks whether a widget with the given [id] can be rendered.
  /// Returns `true` for all valid concept identifiers.
  static bool hasWidget(String id) {
    return id.trim().isNotEmpty;
  }
}

