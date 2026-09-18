import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student_profile.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import 'chat_screen.dart';

class StudentOnboardingScreen extends StatefulWidget {
  final bool isEditing;
  final StudentProfile? initialProfile;

  const StudentOnboardingScreen({
    super.key,
    this.isEditing = false,
    this.initialProfile,
  });

  @override
  State<StudentOnboardingScreen> createState() => _StudentOnboardingScreenState();
}

class _StudentOnboardingScreenState extends State<StudentOnboardingScreen> {
  int _currentStep = 0;
  bool _isSaving = false;

  // Controllers & Form values
  late TextEditingController _nameController;
  late TextEditingController _examGoalController;

  String _selectedClass = 'Class 10';
  String _selectedBoard = 'CBSE';
  String _selectedSyllabus = 'NCERT';
  String _selectedMedium = 'English';
  String _selectedLanguage = 'English';
  final Set<String> _selectedSubjects = {'Mathematics', 'Physics', 'Chemistry', 'Biology', 'English'};
  String _selectedGoal = 'Concept Clarity';
  String _selectedKnowledge = 'Intermediate';
  String _selectedStyle = 'Simple with analogies';
  String _selectedFormat = 'Step-by-step explanation';
  String _selectedExamples = 'Real-life applications';
  String _selectedRevision = 'Quick recap notes';
  final Set<String> _selectedInterests = {'Space & Astronomy', 'Robotics & AI'};

  // Options
  static const _classes = [
    'Class 5', 'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10', 'Class 11', 'Class 12'
  ];

  static const _boards = [
    'CBSE', 'Kerala State Board (SCERT)', 'ICSE', 'State Board'
  ];

  static const _syllabi = ['NCERT', 'SCERT', 'CBSE'];

  static const _languages = ['English', 'Malayalam', 'Manglish', 'Hindi'];

  static const _allSubjects = [
    'Mathematics', 'Physics', 'Chemistry', 'Biology', 'English',
    'Social Science', 'History', 'Geography', 'Computer Science'
  ];

  static const _goals = [
    'Concept Clarity', 'Top in Class', 'Board Exams', 'NEET', 'JEE'
  ];

  static const _knowledgeLevels = ['Beginner', 'Intermediate', 'Advanced'];

  static const _styles = [
    'Simple with analogies',
    'Step-by-step breakdown',
    'Socratic questioning',
    'Deep technical'
  ];

  static const _formats = [
    'Step-by-step explanation',
    'Detailed notes',
    'Short explanation',
    'Practice questions',
    'Quiz format'
  ];

  static const _exampleTypes = [
    'Real-life applications',
    'Story-based',
    'Mathematical derivations'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    final user = FirebaseAuth.instance.currentUser;
    final defaultName = user?.displayName ?? (user?.email?.split('@').first ?? 'Student');

    _nameController = TextEditingController(text: p?.displayName ?? defaultName);
    _examGoalController = TextEditingController(text: p?.examPrepGoal ?? '');

    if (p != null) {
      _selectedClass = p.classLevel;
      _selectedBoard = p.board;
      _selectedSyllabus = p.syllabus;
      _selectedMedium = p.medium;
      _selectedLanguage = p.preferredLanguage;
      _selectedSubjects.clear();
      _selectedSubjects.addAll(p.subjects);
      _selectedGoal = p.learningGoal;
      _selectedKnowledge = p.knowledgeLevel;
      _selectedStyle = p.explanationStyle;
      _selectedFormat = p.responseFormat;
      _selectedExamples = p.preferredExamples;
      _selectedRevision = p.revisionPreference;
      _selectedInterests.clear();
      _selectedInterests.addAll(p.interests);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _examGoalController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    final profile = StudentProfile(
      studentId: user.uid,
      displayName: _nameController.text.trim().isEmpty ? 'Student' : _nameController.text.trim(),
      classLevel: _selectedClass,
      board: _selectedBoard,
      syllabus: _selectedSyllabus,
      medium: _selectedMedium,
      preferredLanguage: _selectedLanguage,
      subjects: _selectedSubjects.toList(),
      learningGoal: _selectedGoal,
      knowledgeLevel: _selectedKnowledge,
      explanationStyle: _selectedStyle,
      responseFormat: _selectedFormat,
      preferredExamples: _selectedExamples,
      examPrepGoal: _examGoalController.text.trim().isNotEmpty ? _examGoalController.text.trim() : null,
      revisionPreference: _selectedRevision,
      interests: _selectedInterests.toList(),
      onboardingCompleted: true,
      personalizationEnabled: widget.initialProfile?.personalizationEnabled ?? true,
      createdAt: widget.initialProfile?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      // 1. Save to Firestore
      await DatabaseService.saveStudentProfile(user.uid, profile);

      // 2. Mirror to Backend Server
      await AIService.syncStudentProfile(user.uid, profile);

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (widget.isEditing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully! ✨'), backgroundColor: Color(0xFF10B981)),
        );
        Navigator.of(context).pop(profile);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070D1A),
        elevation: 0,
        title: Text(
          widget.isEditing ? 'Edit Student Profile' : 'Welcome to Jeeni AI 🎓',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: widget.isEditing
            ? IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.of(context).pop())
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: List.generate(4, (i) {
                  final active = i <= _currentStep;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF818CF8) : Colors.white12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStep(),
              ),
            ),

            // Bottom Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: () => setState(() => _currentStep--),
                      child: const Text('Back', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 15)),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF818CF8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isSaving
                        ? null
                        : () {
                            if (_currentStep < 3) {
                              setState(() => _currentStep++);
                            } else {
                              _completeOnboarding();
                            }
                          },
                    child: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            _currentStep < 3 ? 'Next →' : (widget.isEditing ? 'Save Changes' : 'Start Learning! 🚀'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Academic();
      case 1:
        return _buildStep2LanguageSubjects();
      case 2:
        return _buildStep3GoalsAndStyle();
      case 3:
      default:
        return _buildStep4Review();
    }
  }

  // ── Step 1: Academic Profile ──
  Widget _buildStep1Academic() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 1 of 4', style: TextStyle(color: Color(0xFF818CF8), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('Your Academic Profile', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Jeeni tailors its textbook answers and explanations to your exact curriculum.', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 14)),
        const SizedBox(height: 24),

        _buildTextField('Your Name / Nickname', _nameController, 'How should Jeeni address you?'),
        const SizedBox(height: 20),

        _buildSectionHeader('Class / Grade'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _classes.map((c) => _buildChip(c, _selectedClass == c, () => setState(() => _selectedClass = c))).toList(),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader('Education Board'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _boards.map((b) => _buildChip(b, _selectedBoard == b, () => setState(() => _selectedBoard = b))).toList(),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader('Syllabus'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _syllabi.map((s) => _buildChip(s, _selectedSyllabus == s, () => setState(() => _selectedSyllabus = s))).toList(),
        ),
      ],
    );
  }

  // ── Step 2: Language & Subjects ──
  Widget _buildStep2LanguageSubjects() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 2 of 4', style: TextStyle(color: Color(0xFF818CF8), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('Language & Subjects', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Pick your preferred language for explanations and subjects you study.', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 14)),
        const SizedBox(height: 24),

        _buildSectionHeader('Preferred Explanation Language'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _languages.map((l) => _buildChip(l, _selectedLanguage == l, () => setState(() => _selectedLanguage = l))).toList(),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader('Medium of Instruction'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['English', 'Malayalam'].map((m) => _buildChip(m, _selectedMedium == m, () => setState(() => _selectedMedium = m))).toList(),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader('Select Your Core Subjects (Select all that apply)'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allSubjects.map((sub) {
            final isSelected = _selectedSubjects.contains(sub);
            return _buildChip(
              sub,
              isSelected,
              () {
                setState(() {
                  if (isSelected) {
                    if (_selectedSubjects.length > 1) _selectedSubjects.remove(sub);
                  } else {
                    _selectedSubjects.add(sub);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Step 3: Goals & Learning Style ──
  Widget _buildStep3GoalsAndStyle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 3 of 4', style: TextStyle(color: Color(0xFF818CF8), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('Goals & Learning Style', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Help Jeeni understand how you learn best so it can teach at your pace.', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 14)),
        const SizedBox(height: 24),

        _buildSectionHeader('Primary Academic Goal'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _goals.map((g) => _buildChip(g, _selectedGoal == g, () => setState(() => _selectedGoal = g))).toList(),
        ),
        const SizedBox(height: 20),

        _buildTextField('Specific Target Exam (Optional)', _examGoalController, 'e.g. CBSE 10th Board 2026, NEET 2027'),
        const SizedBox(height: 20),

        _buildSectionHeader('Current Knowledge Level'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _knowledgeLevels.map((k) => _buildChip(k, _selectedKnowledge == k, () => setState(() => _selectedKnowledge = k))).toList(),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader('Preferred Explanation Style'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _styles.map((s) => _buildChip(s, _selectedStyle == s, () => setState(() => _selectedStyle = s))).toList(),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader('Preferred Response Format'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _formats.map((f) => _buildChip(f, _selectedFormat == f, () => setState(() => _selectedFormat = f))).toList(),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader('Preferred Examples'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _exampleTypes.map((e) => _buildChip(e, _selectedExamples == e, () => setState(() => _selectedExamples = e))).toList(),
        ),
      ],
    );
  }

  // ── Step 4: Summary & Review ──
  Widget _buildStep4Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 4 of 4', style: TextStyle(color: Color(0xFF818CF8), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('Review Your Profile', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Check your details before finishing. You can always change them later in Settings.', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 14)),
        const SizedBox(height: 24),

        _buildSummaryCard('👤 Student', _nameController.text.trim().isEmpty ? 'Student' : _nameController.text.trim(), onEdit: () => setState(() => _currentStep = 0)),
        _buildSummaryCard('🏫 Curriculum', '$_selectedClass • $_selectedBoard ($_selectedSyllabus)', onEdit: () => setState(() => _currentStep = 0)),
        _buildSummaryCard('🌐 Language', '$_selectedLanguage (Medium: $_selectedMedium)', onEdit: () => setState(() => _currentStep = 1)),
        _buildSummaryCard('📚 Subjects', _selectedSubjects.join(', '), onEdit: () => setState(() => _currentStep = 1)),
        _buildSummaryCard('🎯 Goal & Level', '$_selectedGoal • $_selectedKnowledge level', onEdit: () => setState(() => _currentStep = 2)),
        _buildSummaryCard('💡 Teaching Style', '$_selectedStyle • $_selectedFormat', onEdit: () => setState(() => _currentStep = 2)),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF818CF8), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Privacy Shield Active: Jeeni stores only learning-relevant academic preferences. No sensitive personal data is ever collected or shared.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── UI Helpers ──
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(label),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFF131D31),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF818CF8))),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF131D31),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF818CF8) : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFA1A1AA),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, {required VoidCallback onEdit}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFA1A1AA)),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}
