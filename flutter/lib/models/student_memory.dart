class StudentMemory {
  final String memoryId;
  final String studentId;
  final String category;
  final String content;
  final String source;
  final String? evidenceReference;
  final double confidence;
  final bool isExplicit;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudentMemory({
    required this.memoryId,
    required this.studentId,
    required this.category,
    required this.content,
    this.source = 'explicit',
    this.evidenceReference,
    this.confidence = 1.0,
    this.isExplicit = true,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'memory_id': memoryId,
      'student_id': studentId,
      'category': category,
      'content': content,
      'source': source,
      'evidence_reference': evidenceReference,
      'confidence': confidence,
      'is_explicit': isExplicit,
      'is_active': isActive,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory StudentMemory.fromMap(Map<String, dynamic> map) {
    return StudentMemory(
      memoryId: (map['memory_id'] ?? map['id'] ?? '') as String,
      studentId: (map['student_id'] ?? '') as String,
      category: (map['category'] ?? 'Learning Preference') as String,
      content: (map['content'] ?? '') as String,
      source: (map['source'] ?? 'explicit') as String,
      evidenceReference: map['evidence_reference'] as String?,
      confidence: (map['confidence'] != null ? (map['confidence'] as num).toDouble() : 1.0),
      isExplicit: (map['is_explicit'] ?? true) as bool,
      isActive: (map['is_active'] ?? true) as bool,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : DateTime.now(),
    );
  }
}
