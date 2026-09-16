import 'package:flutter_test/flutter_test.dart';
import 'package:jeeni_ai/models/student_profile.dart';
import 'package:jeeni_ai/models/student_memory.dart';

void main() {
  group('StudentProfile Tests', () {
    test('Default values and serialization to/from Map', () {
      final now = DateTime.now();
      final profile = StudentProfile(
        studentId: 'student_123',
        displayName: 'Rahul K',
        classLevel: 'Class 10',
        board: 'Kerala State Board (SCERT)',
        syllabus: 'SCERT',
        medium: 'Malayalam',
        preferredLanguage: 'Malayalam',
        subjects: ['Mathematics', 'Physics', 'Biology'],
        learningGoal: 'Concept Clarity',
        knowledgeLevel: 'Intermediate',
        explanationStyle: 'Simple with analogies',
        responseFormat: 'Step-by-step explanation',
        preferredExamples: 'Real-life applications',
        revisionPreference: 'Quick recap notes',
        onboardingCompleted: true,
        personalizationEnabled: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = profile.toMap();
      expect(map['student_id'], 'student_123');
      expect(map['display_name'], 'Rahul K');
      expect(map['class'], 'Class 10');
      expect(map['board'], 'Kerala State Board (SCERT)');
      expect(map['syllabus'], 'SCERT');
      expect(map['medium'], 'Malayalam');
      expect(map['preferred_language'], 'Malayalam');
      expect(map['onboarding_completed'], true);
      expect(map['personalization_enabled'], true);

      final restored = StudentProfile.fromMap(map);
      expect(restored.studentId, 'student_123');
      expect(restored.displayName, 'Rahul K');
      expect(restored.classLevel, 'Class 10');
      expect(restored.board, 'Kerala State Board (SCERT)');
      expect(restored.syllabus, 'SCERT');
      expect(restored.subjects, contains('Physics'));
      expect(restored.onboardingCompleted, true);
      expect(restored.personalizationEnabled, true);
    });

    test('StudentProfile copyWith works correctly', () {
      final now = DateTime.now();
      final original = StudentProfile(
        studentId: 'student_456',
        displayName: 'Ananya',
        classLevel: 'Class 9',
        board: 'CBSE',
        syllabus: 'NCERT',
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        classLevel: 'Class 10',
        personalizationEnabled: false,
      );

      expect(updated.displayName, 'Ananya');
      expect(updated.classLevel, 'Class 10');
      expect(updated.personalizationEnabled, false);
      expect(original.classLevel, 'Class 9');
      expect(original.personalizationEnabled, true);
    });
  });

  group('StudentMemory Tests', () {
    test('Memory serialization and properties', () {
      final now = DateTime.now();
      final memory = StudentMemory(
        memoryId: 'mem_999',
        studentId: 'student_123',
        category: 'Language Preference',
        content: 'Prefers explanations in Malayalam with English technical terms',
        source: 'explicit',
        confidence: 1.0,
        isExplicit: true,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = memory.toMap();
      expect(map['memory_id'], 'mem_999');
      expect(map['student_id'], 'student_123');
      expect(map['category'], 'Language Preference');
      expect(map['content'], contains('Malayalam'));
      expect(map['is_explicit'], true);

      final restored = StudentMemory.fromMap(map);
      expect(restored.memoryId, 'mem_999');
      expect(restored.studentId, 'student_123');
      expect(restored.content, memory.content);
      expect(restored.confidence, 1.0);
    });
  });
}
