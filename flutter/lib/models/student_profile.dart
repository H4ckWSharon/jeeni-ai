class StudentProfile {
  final String studentId;
  final String displayName;
  final String classLevel;
  final String board;
  final String syllabus;
  final String medium;
  final String preferredLanguage;
  final List<String> subjects;
  final String learningGoal;
  final String knowledgeLevel;
  final String explanationStyle;
  final String responseFormat;
  final String preferredExamples;
  final String? examPrepGoal;
  final String revisionPreference;
  final List<String> interests;
  final bool onboardingCompleted;
  final bool personalizationEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudentProfile({
    required this.studentId,
    this.displayName = 'Student',
    this.classLevel = 'Class 10',
    this.board = 'CBSE',
    this.syllabus = 'NCERT',
    this.medium = 'English',
    this.preferredLanguage = 'English',
    this.subjects = const ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'English'],
    this.learningGoal = 'Concept Clarity',
    this.knowledgeLevel = 'Intermediate',
    this.explanationStyle = 'Simple with analogies',
    this.responseFormat = 'Step-by-step explanation',
    this.preferredExamples = 'Real-life applications',
    this.examPrepGoal,
    this.revisionPreference = 'Quick recap notes',
    this.interests = const [],
    this.onboardingCompleted = false,
    this.personalizationEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'display_name': displayName,
      'class': classLevel,
      'board': board,
      'syllabus': syllabus,
      'medium': medium,
      'preferred_language': preferredLanguage,
      'subjects': subjects,
      'learning_goal': learningGoal,
      'knowledge_level': knowledgeLevel,
      'explanation_style': explanationStyle,
      'response_format': responseFormat,
      'preferred_examples': preferredExamples,
      'exam_prep_goal': examPrepGoal,
      'revision_preference': revisionPreference,
      'interests': interests,
      'onboarding_completed': onboardingCompleted,
      'personalization_enabled': personalizationEnabled,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory StudentProfile.fromMap(Map<String, dynamic> map, {String? studentId}) {
    return StudentProfile(
      studentId: (map['student_id'] ?? studentId ?? '') as String,
      displayName: (map['display_name'] ?? 'Student') as String,
      classLevel: (map['class'] ?? 'Class 10') as String,
      board: (map['board'] ?? 'CBSE') as String,
      syllabus: (map['syllabus'] ?? 'NCERT') as String,
      medium: (map['medium'] ?? 'English') as String,
      preferredLanguage: (map['preferred_language'] ?? 'English') as String,
      subjects: List<String>.from(map['subjects'] ?? ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'English']),
      learningGoal: (map['learning_goal'] ?? 'Concept Clarity') as String,
      knowledgeLevel: (map['knowledge_level'] ?? 'Intermediate') as String,
      explanationStyle: (map['explanation_style'] ?? 'Simple with analogies') as String,
      responseFormat: (map['response_format'] ?? 'Step-by-step explanation') as String,
      preferredExamples: (map['preferred_examples'] ?? 'Real-life applications') as String,
      examPrepGoal: map['exam_prep_goal'] as String?,
      revisionPreference: (map['revision_preference'] ?? 'Quick recap notes') as String,
      interests: List<String>.from(map['interests'] ?? []),
      onboardingCompleted: (map['onboarding_completed'] ?? false) as bool,
      personalizationEnabled: (map['personalization_enabled'] ?? true) as bool,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : DateTime.now(),
    );
  }

  StudentProfile copyWith({
    String? displayName,
    String? classLevel,
    String? board,
    String? syllabus,
    String? medium,
    String? preferredLanguage,
    List<String>? subjects,
    String? learningGoal,
    String? knowledgeLevel,
    String? explanationStyle,
    String? responseFormat,
    String? preferredExamples,
    String? examPrepGoal,
    String? revisionPreference,
    List<String>? interests,
    bool? onboardingCompleted,
    bool? personalizationEnabled,
  }) {
    return StudentProfile(
      studentId: studentId,
      displayName: displayName ?? this.displayName,
      classLevel: classLevel ?? this.classLevel,
      board: board ?? this.board,
      syllabus: syllabus ?? this.syllabus,
      medium: medium ?? this.medium,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      subjects: subjects ?? this.subjects,
      learningGoal: learningGoal ?? this.learningGoal,
      knowledgeLevel: knowledgeLevel ?? this.knowledgeLevel,
      explanationStyle: explanationStyle ?? this.explanationStyle,
      responseFormat: responseFormat ?? this.responseFormat,
      preferredExamples: preferredExamples ?? this.preferredExamples,
      examPrepGoal: examPrepGoal ?? this.examPrepGoal,
      revisionPreference: revisionPreference ?? this.revisionPreference,
      interests: interests ?? this.interests,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      personalizationEnabled: personalizationEnabled ?? this.personalizationEnabled,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
