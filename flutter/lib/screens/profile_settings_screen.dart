import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student_profile.dart';
import '../models/student_memory.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import 'student_onboarding_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final int initialTab;
  const ProfileSettingsScreen({super.key, this.initialTab = 0});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StudentProfile? _profile;
  bool _isLoading = true;
  bool _personalizationEnabled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final profile = await DatabaseService.getStudentProfile(user.uid);
      if (mounted) {
        setState(() {
          _profile = profile;
          _personalizationEnabled = profile?.personalizationEnabled ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[ProfileSettings] Failed to load profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePersonalization(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _personalizationEnabled = value);

    try {
      await DatabaseService.togglePersonalization(user.uid, value);
      await AIService.toggleBackendPersonalization(user.uid, value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value
                ? 'Personalization enabled: Jeeni will adapt to your learning style ✨'
                : 'Personalization paused: Jeeni will use standard curriculum answers 🛡️'),
            backgroundColor: value ? const Color(0xFF10B981) : const Color(0xFF64748B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('[ProfileSettings] Toggle personalization error: $e');
    }
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.of(context).push<StudentProfile>(
      MaterialPageRoute(
        builder: (_) => StudentOnboardingScreen(
          isEditing: true,
          initialProfile: _profile,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _profile = updated;
        _personalizationEnabled = updated.personalizationEnabled;
      });
    }
  }

  void _showAddMemoryDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final contentController = TextEditingController();
    String selectedCategory = 'Learning Preference';
    final categories = ['Learning Preference', 'Language', 'Study Goal', 'Subject Focus', 'Exam Prep'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF131D31),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF1E293B)),
          ),
          title: const Row(
            children: [
              Icon(Icons.add_circle_outline, color: Color(0xFF818CF8), size: 20),
              SizedBox(width: 8),
              Text(
                'Remember Something',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tell Jeeni what to remember (e.g. "I prefer Malayalam explanations", "I want more practical physics examples").',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: const TextStyle(color: Color(0xFF818CF8), fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
                ),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedCategory = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g., Remember that I am preparing for NEET and need high-yield biology summaries.',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF818CF8))),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final text = contentController.text.trim();
                if (text.isEmpty) return;

                final memId = 'mem_${DateTime.now().millisecondsSinceEpoch}';
                final memory = StudentMemory(
                  memoryId: memId,
                  studentId: user.uid,
                  category: selectedCategory,
                  content: text,
                  source: 'explicit',
                  confidence: 1.0,
                  isExplicit: true,
                  isActive: true,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                // Save to Firestore
                await DatabaseService.saveMemory(user.uid, memory);
                // Sync to backend
                await AIService.syncMemory(user.uid, content: text, category: selectedCategory);

                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Memory saved! Jeeni will use this to adapt future responses.'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              child: const Text('Remember'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearAllMemories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131D31),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFEF4444)),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Clear All Memories?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This will permanently delete all your stored learning preferences and personalized notes. Your core educational profile (Class, Board) will remain intact.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.clearAllMemories(user.uid);
      await AIService.clearBackendMemories(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All student memories cleared.'),
            backgroundColor: Color(0xFF334155),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'Student Profile & Memory',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF818CF8),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.school_outlined, size: 20), text: 'Profile'),
            Tab(icon: Icon(Icons.psychology_outlined, size: 20), text: 'AI Memory'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF818CF8)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildMemoryTab(),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════
  // TAB 1: PROFILE OVERVIEW & EDIT
  // ═══════════════════════════════════════════════════
  Widget _buildProfileTab() {
    final p = _profile;
    if (p == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, size: 48, color: Color(0xFF64748B)),
            const SizedBox(height: 12),
            const Text('No profile configured yet', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _openEditProfile,
              child: const Text('Complete Onboarding'),
            ),
          ],
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // ── Main Student Header Card ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF4338CA).withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
                ),
                child: Center(
                  child: Text(
                    p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : 'S',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.displayName,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p.classLevel}  ·  ${p.board}',
                      style: const TextStyle(color: Color(0xFF818CF8), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.syllabus} Syllabus  ·  ${p.medium} Medium',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
                tooltip: 'Edit Profile',
                onPressed: _openEditProfile,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Academic Configuration ──
        _buildSectionTitle('Curriculum & Language'),
        _buildInfoTile('Class / Grade', p.classLevel, Icons.school),
        _buildInfoTile('Education Board', p.board, Icons.account_balance),
        _buildInfoTile('Syllabus', p.syllabus, Icons.menu_book),
        _buildInfoTile('Medium of Instruction', p.medium, Icons.record_voice_over),
        _buildInfoTile('Preferred Response Language', p.preferredLanguage, Icons.language),

        const SizedBox(height: 16),

        // ── Active Subjects ──
        _buildSectionTitle('Active Subjects'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: p.subjects.map((s) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Text(s, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 12)),
          )).toList(),
        ),

        const SizedBox(height: 20),

        // ── Learning Goals & Preferences ──
        _buildSectionTitle('Learning & Explanation Preferences'),
        _buildInfoTile('Primary Learning Goal', p.learningGoal, Icons.flag),
        _buildInfoTile('Current Knowledge Level', p.knowledgeLevel, Icons.analytics_outlined),
        _buildInfoTile('Explanation Style', p.explanationStyle, Icons.psychology),
        _buildInfoTile('Preferred Response Format', p.responseFormat, Icons.view_headline),
        _buildInfoTile('Example Preference', p.preferredExamples, Icons.lightbulb_outline),
        _buildInfoTile('Revision Preference', p.revisionPreference, Icons.repeat),
        if (p.examPrepGoal != null && p.examPrepGoal!.isNotEmpty)
          _buildInfoTile('Target Exam', p.examPrepGoal!, Icons.military_tech_outlined),

        const SizedBox(height: 24),

        // ── Edit Profile Button ──
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit Learning Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: _openEditProfile,
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // TAB 2: AI MEMORY & PRIVACY
  // ═══════════════════════════════════════════════════
  Widget _buildMemoryTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Sign in to view memory controls', style: TextStyle(color: Colors.white)));
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // ── Personalization Master Toggle Card ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131D31),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _personalizationEnabled ? const Color(0xFF4F46E5).withOpacity(0.5) : const Color(0xFF334155),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _personalizationEnabled ? const Color(0xFF4F46E5).withOpacity(0.2) : const Color(0xFF1E293B),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _personalizationEnabled ? Icons.auto_awesome : Icons.pause_circle_outline,
                  color: _personalizationEnabled ? const Color(0xFF818CF8) : const Color(0xFF64748B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _personalizationEnabled ? 'Personalization Active' : 'Personalization Paused',
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _personalizationEnabled
                          ? 'Jeeni adapts explanations, language & examples to your profile.'
                          : 'Standard curriculum answers only. Stored memories are ignored.',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _personalizationEnabled,
                onChanged: _togglePersonalization,
                activeThumbColor: const Color(0xFF818CF8),
                activeTrackColor: const Color(0xFF4F46E5).withOpacity(0.5),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Action Bar: Add Memory & Clear All ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Stored Learning Memories'),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF818CF8), size: 22),
                  tooltip: 'Add explicit preference',
                  onPressed: _showAddMemoryDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFEF4444), size: 22),
                  tooltip: 'Clear all memories',
                  onPressed: _confirmClearAllMemories,
                ),
              ],
            ),
          ],
        ),

        // ── Stream of Memories from Firestore ──
        StreamBuilder<List<StudentMemory>>(
          stream: DatabaseService.getMemoriesStream(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF818CF8))),
              );
            }

            final memories = snapshot.data ?? [];
            if (memories.isEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF131D31),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 36, color: Color(0xFF64748B)),
                    const SizedBox(height: 10),
                    const Text('No learning memories saved yet', style: TextStyle(color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text(
                      'You can say "Remember that I prefer Malayalam" or tap "+ Add Preference" above.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: const Color(0xFF818CF8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add First Memory'),
                      onPressed: _showAddMemoryDialog,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: memories.map((m) => _buildMemoryCard(user.uid, m)).toList(),
            );
          },
        ),

        const SizedBox(height: 24),

        // ── Privacy & Data Minimization Guardrails Notice ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Student Privacy & Safety Guardrails',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '• Jeeni only saves educational preferences (language, style, exam focus, repeated mistakes).\n'
                '• We NEVER record or infer health, disability, politics, religion, or sensitive personal data.\n'
                '• All learning memories are strictly isolated to your authenticated account.\n'
                '• You can view, edit, delete individual memories, or clear all data at any time.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildMemoryCard(String studentId, StudentMemory memory) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.bookmark_border_rounded, color: Color(0xFF818CF8), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        memory.category,
                        style: const TextStyle(color: Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      memory.source == 'explicit' ? 'User specified' : 'Interaction observation',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  memory.content,
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
            tooltip: 'Delete memory',
            onPressed: () async {
              await DatabaseService.deleteMemory(studentId, memory.memoryId);
              await AIService.deleteBackendMemory(studentId, memory.memoryId);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF818CF8), size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
