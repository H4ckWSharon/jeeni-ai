import 'package:flutter_test/flutter_test.dart';
import 'package:jeeni_ai/models/jeeni_mode.dart';

void main() {
  group('JeeniMode Model & Filter Tests', () {
    test('1. Exact 6 Jeeni product modes are defined', () {
      expect(JeeniMode.values.length, 6);
      final ids = JeeniMode.values.map((m) => m.id).toList();
      expect(ids, containsAll([
        'web_search',
        'deep_learning',
        'guide',
        'learning',
        'homework',
        'exam_prep',
      ]));
    });

    test('2. Mode labels match official product names', () {
      expect(JeeniMode.webSearch.label, 'Web Search');
      expect(JeeniMode.deepLearning.label, 'Deep Learning');
      expect(JeeniMode.guide.label, 'Guide');
      expect(JeeniMode.learning.label, 'Learning');
      expect(JeeniMode.homework.label, 'Homework');
      expect(JeeniMode.examPrep.label, 'Exam Prep');
    });

    test('3. Mode descriptions match requirements', () {
      expect(JeeniMode.webSearch.description, 'Search the web for current info');
      expect(JeeniMode.deepLearning.description, 'Deeply understand a topic');
      expect(JeeniMode.guide.description, 'Step-by-step guided help');
      expect(JeeniMode.learning.description, 'Learn concepts interactively');
      expect(JeeniMode.homework.description, 'Work through homework problems');
      expect(JeeniMode.examPrep.description, 'Prepare, practice and revise');
    });

    test('4. @ trigger filter returns all 6 modes', () {
      final allWithAt = JeeniMode.filter('@');
      expect(allWithAt.length, 6);

      final allEmpty = JeeniMode.filter('');
      expect(allEmpty.length, 6);
    });

    test('5. @web filters to Web Search', () {
      final res = JeeniMode.filter('@web');
      expect(res.length, 1);
      expect(res.first, JeeniMode.webSearch);
    });

    test('6. @deep filters to Deep Learning', () {
      final res = JeeniMode.filter('@deep');
      expect(res.length, 1);
      expect(res.first, JeeniMode.deepLearning);
    });

    test('7. @guide filters to Guide', () {
      final res = JeeniMode.filter('@guide');
      expect(res.length, 1);
      expect(res.first, JeeniMode.guide);
    });

    test('8. @learn filters to Learning modes', () {
      final res = JeeniMode.filter('@learn');
      expect(res, contains(JeeniMode.learning));
      expect(res, contains(JeeniMode.deepLearning));
    });

    test('9. @home filters to Homework', () {
      final res = JeeniMode.filter('@home');
      expect(res.length, 1);
      expect(res.first, JeeniMode.homework);
    });

    test('10. @exam filters to Exam Prep', () {
      final res = JeeniMode.filter('@exam');
      expect(res.length, 1);
      expect(res.first, JeeniMode.examPrep);
    });

    test('11. fromString resolves both id and label correctly', () {
      expect(JeeniMode.fromString('web_search'), JeeniMode.webSearch);
      expect(JeeniMode.fromString('Web Search'), JeeniMode.webSearch);
      expect(JeeniMode.fromString('deep_learning'), JeeniMode.deepLearning);
      expect(JeeniMode.fromString('Deep Learning'), JeeniMode.deepLearning);
      expect(JeeniMode.fromString('guide'), JeeniMode.guide);
      expect(JeeniMode.fromString('Guide'), JeeniMode.guide);
      expect(JeeniMode.fromString('learning'), JeeniMode.learning);
      expect(JeeniMode.fromString('Learning'), JeeniMode.learning);
      expect(JeeniMode.fromString('homework'), JeeniMode.homework);
      expect(JeeniMode.fromString('Homework'), JeeniMode.homework);
      expect(JeeniMode.fromString('exam_prep'), JeeniMode.examPrep);
      expect(JeeniMode.fromString('Exam Prep'), JeeniMode.examPrep);
    });

    test('12. fromString falls back to learning for unknown inputs', () {
      expect(JeeniMode.fromString(null), JeeniMode.learning);
      expect(JeeniMode.fromString('invalid_mode_xyz'), JeeniMode.learning);
    });
  });
}
