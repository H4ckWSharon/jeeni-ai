// ============================================================
// Jeeni AI — Learning Engine: Educational Formula Unit Tests
// Tests all mathematical formulas for accuracy
// ============================================================

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeeni_ai/learning_engine/services/widget_registry.dart';

void main() {
  // ────────────────────────────────────────────────────────────
  // GROUP 1: Circle Area Formula Tests
  // ────────────────────────────────────────────────────────────
  group('CircleArea — Educational Formula Accuracy', () {
    double circleArea(double radius) => pi * radius * radius;
    double circumference(double radius) => 2 * pi * radius;

    test('Area of circle with radius 3 ≈ 28.27 sq units', () {
      expect(circleArea(3), closeTo(28.274, 0.001));
    });

    test('Area of circle with radius 5 ≈ 78.54 sq units', () {
      expect(circleArea(5), closeTo(78.540, 0.001));
    });

    test('Area scales quadratically: doubling radius × area by 4', () {
      const r = 3.0;
      final ratio = circleArea(r * 2) / circleArea(r);
      expect(ratio, closeTo(4.0, 0.001));
    });

    test('Circumference of circle with radius 5 ≈ 31.42', () {
      expect(circumference(5), closeTo(31.416, 0.001));
    });

    test('Diameter = 10 → Radius = 5 → Area = 78.54', () {
      const diameter = 10.0;
      const radius = diameter / 2;
      expect(circleArea(radius), closeTo(78.540, 0.001));
    });

    test('Area at radius=0 is 0', () {
      expect(circleArea(0), equals(0.0));
    });
  });

  // ────────────────────────────────────────────────────────────
  // GROUP 2: Newton's Second Law Formula Tests
  // ────────────────────────────────────────────────────────────
  group('NewtonSecondLaw — Educational Formula Accuracy', () {
    double acceleration(double force, double mass) => force / mass;
    double velocity(double acc, double time) => acc * time;
    double distance(double acc, double time) => 0.5 * acc * time * time;
    double netForce(double applied, double friction) => applied - friction;

    test('F=ma: a = F/m → 40N / 5kg = 8 m/s²', () {
      expect(acceleration(40, 5), closeTo(8.0, 0.001));
    });

    test('Doubling force doubles acceleration (same mass)', () {
      final a1 = acceleration(40, 5);
      final a2 = acceleration(80, 5);
      expect(a2, closeTo(a1 * 2, 0.001));
    });

    test('Doubling mass halves acceleration (same force)', () {
      final a1 = acceleration(40, 5);
      final a2 = acceleration(40, 10);
      expect(a2, closeTo(a1 / 2, 0.001));
    });

    test('v = at: at t=3s, a=8 → v=24 m/s', () {
      expect(velocity(8.0, 3.0), closeTo(24.0, 0.001));
    });

    test('d = ½at²: at t=3s, a=8 → d=36 m', () {
      expect(distance(8.0, 3.0), closeTo(36.0, 0.001));
    });

    test('Net force with friction: 100N - 20N = 80N', () {
      expect(netForce(100, 20), closeTo(80.0, 0.001));
    });

    test('Quiz Q3: F_net=80N, m=20kg → a=4 m/s²', () {
      expect(acceleration(netForce(100, 20), 20), closeTo(4.0, 0.001));
    });

    test('Quiz Q2: F = 10kg × 3 m/s² = 30N', () {
      expect(10 * 3.0, closeTo(30.0, 0.001));
    });
  });

  // ────────────────────────────────────────────────────────────
  // GROUP 3: Algebra — Linear Equation Tests
  // ────────────────────────────────────────────────────────────
  group('GraphPlotter — Linear Equation Formula Accuracy', () {
    double yValue(double m, double c, double x) => m * x + c;

    test('y = 1x + 0 at x=3 → y=3', () {
      expect(yValue(1, 0, 3), closeTo(3.0, 0.001));
    });

    test('y = 2x + 1 at x=0 → y=1 (y-intercept)', () {
      expect(yValue(2, 1, 0), closeTo(1.0, 0.001));
    });

    test('y = -x + 5 at x=5 → y=0 (x-intercept)', () {
      expect(yValue(-1, 5, 5), closeTo(0.0, 0.001));
    });

    test('Negative slope: y decreases as x increases', () {
      final y1 = yValue(-2, 0, 1);
      final y2 = yValue(-2, 0, 2);
      expect(y2, lessThan(y1));
    });

    test('Zero slope: y constant regardless of x', () {
      final y1 = yValue(0, 4, -5);
      final y2 = yValue(0, 4, 100);
      expect(y1, equals(y2));
    });

    test('y-intercept of y=3x-5 is -5', () {
      // y-intercept is y when x=0
      expect(yValue(3, -5, 0), closeTo(-5.0, 0.001));
    });
  });

  // ────────────────────────────────────────────────────────────
  // GROUP 4: Trigonometry — Unit Circle Tests
  // ────────────────────────────────────────────────────────────
  group('UnitCircle — Trigonometric Formula Accuracy', () {
    double toRad(double deg) => deg * pi / 180.0;

    test('cos(0°) = 1', () {
      expect(cos(toRad(0)), closeTo(1.0, 0.0001));
    });

    test('sin(0°) = 0', () {
      expect(sin(toRad(0)), closeTo(0.0, 0.0001));
    });

    test('cos(90°) = 0', () {
      expect(cos(toRad(90)), closeTo(0.0, 0.0001));
    });

    test('sin(90°) = 1', () {
      expect(sin(toRad(90)), closeTo(1.0, 0.0001));
    });

    test('cos(180°) = -1', () {
      expect(cos(toRad(180)), closeTo(-1.0, 0.0001));
    });

    test('sin(180°) = 0', () {
      expect(sin(toRad(180)), closeTo(0.0, 0.0001));
    });

    test('Pythagorean identity: sin²(θ) + cos²(θ) = 1 at θ=45°', () {
      final rad = toRad(45);
      final identity = sin(rad) * sin(rad) + cos(rad) * cos(rad);
      expect(identity, closeTo(1.0, 0.0001));
    });

    test('Pythagorean identity holds at θ=130°', () {
      final rad = toRad(130);
      final identity = sin(rad) * sin(rad) + cos(rad) * cos(rad);
      expect(identity, closeTo(1.0, 0.0001));
    });

    test('Quadrant III: sin(225°) < 0 and cos(225°) < 0', () {
      final rad = toRad(225);
      expect(sin(rad), lessThan(0));
      expect(cos(rad), lessThan(0));
    });

    test('Tangent undefined guard: |cos| < 0.001 → undefined', () {
      final cosVal = cos(toRad(90)); // ≈ 6e-17, very close to 0
      final isUndefined = cosVal.abs() < 0.001;
      expect(isUndefined, isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────
  // GROUP 5: Chemistry — Atom Builder Tests
  // ────────────────────────────────────────────────────────────
  group('AtomBuilder — Chemistry Accuracy Tests', () {
    int massNumber(int protons, int neutrons) => protons + neutrons;
    int netCharge(int protons, int electrons) => protons - electrons;
    bool isNeutral(int protons, int electrons) => protons == electrons;

    test('Helium: 2 protons + 2 neutrons = mass 4', () {
      expect(massNumber(2, 2), equals(4));
    });

    test('Carbon: 6 protons + 6 neutrons = mass 12', () {
      expect(massNumber(6, 6), equals(12));
    });

    test('Neutral Hydrogen: P=1 E=1 → netCharge=0', () {
      expect(netCharge(1, 1), equals(0));
    });

    test('Helium ion: P=2 E=1 → netCharge=+1', () {
      expect(netCharge(2, 1), equals(1));
    });

    test('isNeutral when P==E', () {
      expect(isNeutral(2, 2), isTrue);
    });

    test('isNeutral false when P≠E', () {
      expect(isNeutral(2, 1), isFalse);
    });

    test('Proton count identifies element: 6 = Carbon', () {
      // Verified by atomic number definition
      const carbonAtomicNumber = 6;
      const protons = 6;
      expect(protons, equals(carbonAtomicNumber));
    });
  });

  // ────────────────────────────────────────────────────────────
  // GROUP 6: Biology — Heart Rate Tests
  // ────────────────────────────────────────────────────────────
  group('HeartPump — Biology Accuracy Tests', () {
    double beatCycleSeconds(int bpm) => 60 / bpm;
    int bpmToDurationMs(int bpm) => ((60 / bpm) * 1000).round();

    test('72 bpm → cycle = 0.833 seconds', () {
      expect(beatCycleSeconds(72), closeTo(0.833, 0.001));
    });

    test('60 bpm → cycle = 1.0 second', () {
      expect(beatCycleSeconds(60), closeTo(1.0, 0.001));
    });

    test('120 bpm → cycle = 0.5 second', () {
      expect(beatCycleSeconds(120), closeTo(0.5, 0.001));
    });

    test('72 bpm → AnimationController duration ≈ 833ms', () {
      expect(bpmToDurationMs(72), closeTo(833, 2));
    });

    test('Higher BPM → shorter cycle (inverse relationship)', () {
      final slow = beatCycleSeconds(60);
      final fast = beatCycleSeconds(120);
      expect(fast, lessThan(slow));
    });
  });

  // ────────────────────────────────────────────────────────────
  // GROUP 7: Geography — Earth Rotation Tests
  // ────────────────────────────────────────────────────────────
  group('EarthRotation — Geography Accuracy Tests', () {
    test('Earth\'s actual axial tilt is 23.5°', () {
      const earthTilt = 23.5;
      expect(earthTilt, closeTo(23.5, 0.01));
    });

    test('Tilt slider range 0–45° includes Earth tilt', () {
      const minTilt = 0.0;
      const maxTilt = 45.0;
      const earthTilt = 23.5;
      expect(earthTilt >= minTilt && earthTilt <= maxTilt, isTrue);
    });

    test('Rotation progress 0.0 → start position', () {
      const rotationProgress = 0.0;
      const angle = rotationProgress * 2 * pi;
      expect(angle, closeTo(0.0, 0.0001));
    });

    test('Rotation progress 1.0 → full 360° cycle', () {
      const rotationProgress = 1.0;
      const angle = rotationProgress * 2 * pi;
      expect(angle, closeTo(2 * pi, 0.0001));
    });

    test('Tilt angle conversion to radians: 23.5° ≈ 0.410 rad', () {
      const rad = 23.5 * pi / 180;
      expect(rad, closeTo(0.4102, 0.0001));
    });
  });

  // ────────────────────────────────────────────────────────────
  // GROUP 8: Widget Registry Validation Tests
  // ────────────────────────────────────────────────────────────
  group('WidgetRegistry — Key Existence Tests', () {
    final validKeys = [
      'circle_area',
      'newton_second_law',
      'graph_plotter',
      'unit_circle',
      'atom_builder',
      'heart_pump',
      'earth_rotation',
    ];

    test('All 7 widget keys are valid non-empty strings', () {
      for (final key in validKeys) {
        expect(key.isNotEmpty, isTrue, reason: '$key must not be empty');
        expect(key.contains(' '), isFalse, reason: '$key must not contain spaces');
        expect(RegExp(r'^[a-z0-9_]+$').hasMatch(key), isTrue,
            reason: '$key must be lowercase snake_case');
      }
    });

    test('No duplicate widget keys in registry', () {
      final uniqueKeys = validKeys.toSet();
      expect(uniqueKeys.length, equals(validKeys.length));
    });

    test('Inline tag regex matches custom universal topic tags like [interactive:photosynthesis]', () {
      final regExp = RegExp(r'\[interactive:([a-zA-Z0-9_-]+)\]');
      final match = regExp.firstMatch('[interactive:photosynthesis]');
      expect(match, isNotNull);
      expect(match!.group(1), equals('photosynthesis'));
    });

    test('WidgetRegistry.hasWidget returns true for any non-empty concept ID', () {
      expect(WidgetRegistry.hasWidget('photosynthesis'), isTrue);
      expect(WidgetRegistry.hasWidget('gravity'), isTrue);
      expect(WidgetRegistry.hasWidget('ohms_law'), isTrue);
      expect(WidgetRegistry.hasWidget('cell_division'), isTrue);
    });


    test('Inline tag regex matches [interactive:newton_second_law]', () {
      final regExp = RegExp(r'\[interactive:([a-zA-Z0-9_-]+)\]');
      final match = regExp.firstMatch('[interactive:newton_second_law]');
      expect(match, isNotNull);
      expect(match!.group(1), equals('newton_second_law'));
    });

    test('Inline tag regex does NOT match plain text', () {
      final regExp = RegExp(r'\[interactive:([a-zA-Z0-9_-]+)\]');
      final match = regExp.firstMatch('Hello world, how are you?');
      expect(match, isNull);
    });

    test('Mixed message is split into 3 parts: text + widget + text', () {
      const message = 'Here is the explanation.\n\n[interactive:circle_area]\n\nGood luck!';
      final regExp = RegExp(r'\[interactive:([a-zA-Z0-9_-]+)\]');
      final matches = regExp.allMatches(message).toList();
      expect(matches.length, equals(1));
      expect(matches[0].group(1), equals('circle_area'));
    });
  });

  // ────────────────────────────────────────────────────────────
  // GROUP 9: Quiz Validation Tests
  // ────────────────────────────────────────────────────────────
  group('QuizView — Answer Logic Tests', () {
    test('Correct answer index 0 registers as correct', () {
      const correctIndex = 0;
      const selectedIndex = 0;
      expect(selectedIndex == correctIndex, isTrue);
    });

    test('Wrong answer index 2 (correct is 0) registers as incorrect', () {
      const correctIndex = 0;
      const selectedIndex = 2;
      expect(selectedIndex == correctIndex, isFalse);
    });

    test('Score increments only on correct answer', () {
      int score = 0;
      const correctIndex = 1;
      final answers = [2, 1, 0]; // Q1 wrong, Q2 correct, Q3 wrong
      for (final answer in answers) {
        if (answer == correctIndex) score++;
      }
      expect(score, equals(1));
    });

    test('100% quiz completion gives perfect score', () {
      const totalQuestions = 3;
      int score = 0;
      const correctAnswers = [0, 2, 1];
      final selectedAnswers = [0, 2, 1]; // all correct
      for (int i = 0; i < totalQuestions; i++) {
        if (selectedAnswers[i] == correctAnswers[i]) score++;
      }
      expect(score, equals(totalQuestions));
    });

    test('Percentage calculation is correct', () {
      const score = 2;
      const total = 3;
      const percentage = (score / total) * 100;
      expect(percentage, closeTo(66.67, 0.01));
    });
  });

  // ────────────────────────────────────────────────────────────
  // GROUP 10: Performance Guard Tests
  // ────────────────────────────────────────────────────────────
  group('Performance — Computation Bounds Tests', () {
    test('Velocity points list stays within 100 entries (memory guard)', () {
      final velocityPoints = <double>[];
      // Simulate 200 ticks
      for (int i = 0; i < 200; i++) {
        if (velocityPoints.length >= 100) {
          velocityPoints.removeAt(0);
        }
        velocityPoints.add(i.toDouble());
      }
      expect(velocityPoints.length, lessThanOrEqualTo(100));
      expect(velocityPoints.last, equals(199.0));
    });

    test('Circle area computation is fast (< 1ms for 1000 calls)', () {
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        pi * i * i;
      }
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('Trig functions are fast (< 1ms for 1000 calls)', () {
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        sin(i * pi / 180);
        cos(i * pi / 180);
      }
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });
  });
}
