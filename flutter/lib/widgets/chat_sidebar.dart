import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/temp_chat_screen.dart';
import '../screens/history_screen.dart';
import '../screens/auth/auth_gate.dart';
import '../services/database_service.dart';

class ChatSidebar extends StatefulWidget {
  final String? activeChatId;
  final VoidCallback onNewChat;
  final void Function(String chatId) onChatSelected;
  final VoidCallback onSettingsTap;

  const ChatSidebar({
    super.key,
    required this.activeChatId,
    required this.onNewChat,
    required this.onChatSelected,
    required this.onSettingsTap,
  });

  @override
  State<ChatSidebar> createState() => _ChatSidebarState();
}

class _ChatSidebarState extends State<ChatSidebar> {
  // Styles & Colors (Black and White Theme)
  static const _bg = Color(0xFF111111);
  static const _card = Color(0xFF171717);
  static const _cardHover = Color(0xFF1A1A1A);
  static const _border = Color(0xFF232323);
  static const _accent = Colors.white; // Only black & white
  static const _textMain = Colors.white;
  static const _textSecondary = Color(0xFFA1A1AA);

  // Filters & Tabs
  final List<String> _filters = ['All', 'Subjects', 'Projects', 'Favorites'];
  int _selectedFilterIndex = 0;

  // Selected sub-filters
  String _selectedSubject = 'All';
  String? _selectedProjectId; // null = all

  // Search state
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Multi-selection state
  bool _isMultiSelectMode = false;
  final Set<String> _selectedChatIds = {};

  // Subject categories list
  final List<String> _subjects = [
    'All',
    'Programming',
    'Cyber Security',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'History',
    'General',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(int ms) {
    if (ms == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    if (dt.isAfter(todayStart)) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final min = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$min $ampm';
    } else if (dt.isAfter(yesterdayStart)) {
      return 'Yesterday';
    } else {
      return '${dt.day}/${dt.month}';
    }
  }

  // Delete confirmations
  void _confirmDeleteChats({required List<String> chatIds, required String userId}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171717),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2B2B2B)),
        ),
        title: const Text(
          'Delete Conversation?',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          chatIds.length == 1
              ? 'This conversation will be permanently deleted.'
              : 'These ${chatIds.length} conversations will be permanently deleted.',
          style: const TextStyle(color: _textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              for (var id in chatIds) {
                await DatabaseService.deleteChat(userId, id);
              }
              setState(() {
                _selectedChatIds.clear();
                _isMultiSelectMode = false;
              });
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _renameChatDialog(String chatId, String currentTitle, String userId) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171717),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2B2B2B)),
        ),
        title: const Text('Rename Conversation', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          cursorColor: _accent,
          decoration: InputDecoration(
            hintText: 'Enter new name...',
            hintStyle: const TextStyle(color: _textSecondary),
            filled: true,
            fillColor: const Color(0xFF202020),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2B2B2B))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _accent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                await DatabaseService.renameChat(userId, chatId, newTitle);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _createProjectDialog(String userId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171717),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2B2B2B)),
        ),
        title: const Text('Create Project', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          cursorColor: _accent,
          decoration: InputDecoration(
            hintText: 'Project name...',
            hintStyle: const TextStyle(color: _textSecondary),
            filled: true,
            fillColor: const Color(0xFF202020),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2B2B2B))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _accent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await DatabaseService.createProject(userId, name);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _projectActionsMenu(String projectId, String currentName, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF171717),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 12), decoration: BoxDecoration(color: const Color(0xFF2B2B2B), borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.white),
              title: const Text('Rename Project', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(ctx).pop();
                _renameProjectDialog(projectId, currentName, userId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('Delete Project', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmDeleteProject(projectId, currentName, userId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _renameProjectDialog(String projectId, String currentName, String userId) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171717),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF2B2B2B))),
        title: const Text('Rename Project', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          cursorColor: _accent,
          decoration: InputDecoration(
            hintText: 'Enter new name...',
            hintStyle: const TextStyle(color: _textSecondary),
            filled: true,
            fillColor: const Color(0xFF202020),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2B2B2B))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _accent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await DatabaseService.renameProject(userId, projectId, newName);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProject(String projectId, String projectName, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171717),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF2B2B2B))),
        title: const Text('Delete Project?', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text('Delete "$projectName"? Chats associated with this project will be kept but moved to no project.', style: const TextStyle(color: _textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await DatabaseService.deleteProject(userId, projectId);
              if (_selectedProjectId == projectId) {
                setState(() {
                  _selectedProjectId = null;
                });
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _moveChatToProjectSheet(String chatId, String? currentProjectId, String userId, List<Map<String, dynamic>> projects) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF171717),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 12), decoration: BoxDecoration(color: const Color(0xFF2B2B2B), borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Move to Project', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            if (currentProjectId != null)
              ListTile(
                leading: const Icon(Icons.label_off_outlined, color: Colors.white),
                title: const Text('Remove from Project', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await DatabaseService.moveChatToProject(userId, chatId, null);
                },
              ),
            ...projects.map((p) {
              final isCurrent = p['id'] == currentProjectId;
              return ListTile(
                leading: Icon(Icons.folder_outlined, color: isCurrent ? _accent : Colors.white),
                title: Text(p['name'] ?? '', style: TextStyle(color: isCurrent ? _accent : Colors.white)),
                trailing: isCurrent ? const Icon(Icons.check_rounded, color: _accent) : null,
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await DatabaseService.moveChatToProject(userId, chatId, p['id']);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showChatOptionsSheet(Map<String, dynamic> chat, String userId, List<Map<String, dynamic>> projects) {
    final chatId = chat['id'] ?? '';
    final title = chat['title'] ?? '';
    final isStarred = chat['isStarred'] == true;
    final isPinned = chat['isPinned'] == true;
    final currentProjectId = chat['projectId'];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF171717),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 12), decoration: BoxDecoration(color: const Color(0xFF2B2B2B), borderRadius: BorderRadius.circular(2))),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
                title: const Text('Open Chat', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  widget.onChatSelected(chatId);
                },
              ),
              ListTile(
                leading: Icon(isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined, color: Colors.white),
                title: Text(isPinned ? 'Unpin' : 'Pin', style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await DatabaseService.togglePinChat(userId, chatId, !isPinned);
                },
              ),
              ListTile(
                leading: Icon(isStarred ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.white),
                title: Text(isStarred ? 'Remove Favorite' : 'Mark Favorite', style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await DatabaseService.toggleStarChat(userId, chatId, !isStarred);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.white),
                title: const Text('Rename', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _renameChatDialog(chatId, title, userId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Colors.white),
                title: const Text('Duplicate', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await DatabaseService.duplicateChat(userId, chatId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined, color: Colors.white),
                title: const Text('Move to Project', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _moveChatToProjectSheet(chatId, currentProjectId, userId, projects);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDeleteChats(chatIds: [chatId], userId: userId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Container(color: _bg, child: const Center(child: Text('Please log in.', style: TextStyle(color: Colors.white))));
    }

    return Container(
      color: _bg,
      child: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: DatabaseService.getChatsStream(user.uid),
          builder: (context, chatSnapshot) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: DatabaseService.getProjectsStream(user.uid),
              builder: (context, projSnapshot) {
                final chatsList = chatSnapshot.data ?? [];
                final projects = projSnapshot.data ?? [];

                // Search filter
                var filtered = chatsList;
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((c) {
                    final title = (c['title'] ?? '').toString().toLowerCase();
                    final lastMsg = (c['lastMessage'] ?? '').toString().toLowerCase();
                    return title.contains(_searchQuery.toLowerCase()) || lastMsg.contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                // Tabs filter
                if (_selectedFilterIndex == 1) {
                  // Subjects
                  if (_selectedSubject != 'All') {
                    filtered = filtered.where((c) => c['subject'] == _selectedSubject).toList();
                  }
                } else if (_selectedFilterIndex == 2) {
                  // Projects
                  if (_selectedProjectId != null) {
                    filtered = filtered.where((c) => c['projectId'] == _selectedProjectId).toList();
                  } else {
                    filtered = filtered.where((c) => c['projectId'] != null).toList();
                  }
                } else if (_selectedFilterIndex == 3) {
                  // Favorites
                  filtered = filtered.where((c) => c['isStarred'] == true).toList();
                }

                // Split pinned vs non-pinned
                final pinnedChats = <Map<String, dynamic>>[];
                final otherChats = <Map<String, dynamic>>[];
                for (var c in filtered) {
                  if (c['isPinned'] == true) {
                    pinnedChats.add(c);
                  } else {
                    otherChats.add(c);
                  }
                }

                return Column(
                  children: [
                    _buildHeader(),
                    if (_showSearchBar) _buildSearchBarRow(),
                    _buildFilterTabsRow(),
                    if (_selectedFilterIndex == 1) _buildSubjectsSubRow(),
                    if (_selectedFilterIndex == 2) _buildProjectsSubRow(user.uid, projects),
                    
                    // Conversation list
                    Expanded(
                      child: chatSnapshot.connectionState == ConnectionState.waiting
                          ? const Center(child: CircularProgressIndicator(color: _accent))
                          : filtered.isEmpty
                              ? _buildEmptyState()
                              : ListView(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  children: [
                                    if (pinnedChats.isNotEmpty) ...[
                                      _buildSectionHeader('Pinned'),
                                      ...pinnedChats.map((c) => _buildChatItemRow(c, user.uid, projects)),
                                    ],
                                    if (otherChats.isNotEmpty) ...[
                                      _buildSectionHeader('Recent Conversations'),
                                      ...otherChats.map((c) => _buildChatItemRow(c, user.uid, projects)),
                                    ],
                                  ],
                                ),
                    ),

                    if (_isMultiSelectMode) _buildMultiSelectActionBar(user.uid),

                    const Divider(color: _border, height: 1),
                    _buildBottomControls(context, user.email ?? 'Sharon'),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 48, // Compact height
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'JEENI',
            style: TextStyle(
              fontSize: 16, // Larger font size (from 15 to 16)
              fontWeight: FontWeight.bold, // Bold brand text
              color: Colors.white,
              letterSpacing: 2,
              fontFamily: 'serif',
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(_showSearchBar ? Icons.close_rounded : Icons.search_rounded, color: Colors.white, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() {
                  _showSearchBar = !_showSearchBar;
                  if (!_showSearchBar) {
                    _searchQuery = '';
                    _searchController.clear();
                  }
                }),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(_isMultiSelectMode ? Icons.check_circle_rounded : Icons.checklist_rtl_rounded,
                    color: _isMultiSelectMode ? _accent : Colors.white70, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() {
                  _isMultiSelectMode = !_isMultiSelectMode;
                  _selectedChatIds.clear();
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBarRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        cursorColor: _accent,
        decoration: InputDecoration(
          hintText: 'Search chats...',
          hintStyle: const TextStyle(color: _textSecondary),
          prefixIcon: const Icon(Icons.search_rounded, color: _textSecondary, size: 16),
          filled: true,
          fillColor: _card,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: _accent)),
        ),
      ),
    );
  }

  Widget _buildFilterTabsRow() {
    return Container(
      height: 28,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (ctx, i) {
          final isSelected = _selectedFilterIndex == i;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedFilterIndex = i;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14), // Comfortable padding
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? _cardHover : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? Colors.white : _border),
              ),
              child: Text(
                _filters[i],
                style: TextStyle(
                  color: isSelected ? Colors.white : _textSecondary,
                  fontSize: 13, // Larger, clearer size (from 11 to 13)
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubjectsSubRow() {
    return Container(
      height: 26,
      margin: const EdgeInsets.only(bottom: 4, top: 2),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _subjects.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (ctx, i) {
          final sub = _subjects[i];
          final isSelected = _selectedSubject == sub;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedSubject = sub;
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? _card : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: isSelected ? _accent : Colors.transparent),
              ),
              child: Text(
                sub,
                style: TextStyle(
                  color: isSelected ? _accent : _textSecondary,
                  fontSize: 12, // Larger size (from 10 to 12)
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProjectsSubRow(String userId, List<Map<String, dynamic>> projects) {
    return Container(
      height: 26,
      margin: const EdgeInsets.only(bottom: 4, top: 2),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          GestureDetector(
            onTap: () => setState(() {
              _selectedProjectId = null;
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _selectedProjectId == null ? _card : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _selectedProjectId == null ? _accent : Colors.transparent),
              ),
              child: Text(
                'All Projects',
                style: TextStyle(
                  color: _selectedProjectId == null ? _accent : _textSecondary,
                  fontSize: 12, // Larger size (from 10 to 12)
                  fontWeight: _selectedProjectId == null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          ...projects.map((p) {
            final pId = p['id'] ?? '';
            final name = p['name'] ?? '';
            final isSelected = _selectedProjectId == pId;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedProjectId = pId;
              }),
              onLongPress: () {
                _projectActionsMenu(pId, name, userId);
              },
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? _card : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isSelected ? _accent : Colors.transparent),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? _accent : _textSecondary,
                    fontSize: 12, // Larger size (from 10 to 12)
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: () => _createProjectDialog(userId),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, size: 10, color: _accent),
                  SizedBox(width: 2),
                  Text('New', style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 10, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChatItemRow(Map<String, dynamic> chat, String userId, List<Map<String, dynamic>> projects) {
    final chatId = chat['id'] ?? '';
    final title = chat['title'] ?? 'No Title';
    final isStarred = chat['isStarred'] == true;
    final isPinned = chat['isPinned'] == true;
    final lastUpdated = chat['lastUpdated'] ?? 0;
    final timeStr = _formatTime(lastUpdated);
    final isActive = widget.activeChatId == chatId;

    if (_isMultiSelectMode) {
      final isSelected = _selectedChatIds.contains(chatId);
      return Container(
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isSelected ? _cardHover : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Checkbox(
            value: isSelected,
            activeColor: _accent,
            checkColor: Colors.black,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedChatIds.add(chatId);
                } else {
                  _selectedChatIds.remove(chatId);
                }
              });
            },
          ),
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedChatIds.remove(chatId);
              } else {
                _selectedChatIds.add(chatId);
              }
            });
          },
        ),
      );
    }

    return Dismissible(
      key: Key(chatId),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 8),
        color: const Color(0xFF333333),
        child: const Icon(Icons.push_pin_rounded, color: Colors.white, size: 14),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 8),
        color: Colors.redAccent,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 14),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.endToStart) {
          _confirmDeleteChats(chatIds: [chatId], userId: userId);
          return false;
        } else {
          await DatabaseService.togglePinChat(userId, chatId, !isPinned);
          return false;
        }
      },
      child: GestureDetector(
        onLongPress: () => _showChatOptionsSheet(chat, userId, projects),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            margin: const EdgeInsets.only(bottom: 1),
            decoration: BoxDecoration(
              color: isActive
                  ? _cardHover
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              leading: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 14, // Larger icon (from 13 to 14)
                color: isActive ? _accent : _textSecondary,
              ),
              title: Row(
                children: [
                  if (isPinned)
                    const Padding(
                      padding: EdgeInsets.only(right: 2.0),
                      child: Icon(Icons.push_pin_rounded, color: _accent, size: 11),
                    ),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isActive ? _accent : _textMain,
                        fontSize: 14, // Larger font size (from 13 to 14)
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isStarred)
                    const Icon(Icons.star_rounded, color: Color(0xFFFCD34D), size: 11),
                  const SizedBox(width: 4),
                  Text(timeStr, style: const TextStyle(color: _textSecondary, fontSize: 11)), // Larger time text size (from 9 to 11)
                ],
              ),
              onTap: () {
                Navigator.of(context).pop();
                widget.onChatSelected(chatId);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectActionBar(String userId) {
    final count = _selectedChatIds.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(color: Color(0xFF151515)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => setState(() {
              _isMultiSelectMode = false;
              _selectedChatIds.clear();
            }),
            child: const Text('Cancel', style: TextStyle(color: _textSecondary, fontSize: 13)), // Larger text size
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            onPressed: count == 0 ? null : () => _confirmDeleteChats(chatIds: _selectedChatIds.toList(), userId: userId),
            child: Text('Delete ($count)', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, User user) {
    final email = user.email ?? '';
    final displayName = user.displayName ?? email.split('@').first;
    final letter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'J';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 40),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
              ),
            ),

            const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // ── Profile card ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2E2E2E)),
                    child: Center(child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(email, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Settings options ──
            _SettingsOption(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              trailing: Switch(
                value: false,
                onChanged: (_) {},
                activeThumbColor: Colors.white,
                trackColor: WidgetStateProperty.all(Colors.white24),
              ),
            ),

            _SettingsOption(
              icon: Icons.delete_sweep_outlined,
              label: 'Clear All Chats',
              labelColor: Colors.redAccent,
              iconColor: Colors.redAccent,
              onTap: () async {
                Navigator.of(ctx).pop();
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    backgroundColor: const Color(0xFF171717),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    title: const Text('Clear All Chats?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    content: const Text(
                      'This will permanently delete all your conversations. This action cannot be undone.',
                      style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(d).pop(false),
                        child: const Text('Cancel', style: TextStyle(color: Color(0xFFA1A1AA))),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => Navigator.of(d).pop(true),
                        child: const Text('Clear All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  // Delete all chats one by one
                  final chats = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('chats')
                      .get();
                  for (var doc in chats.docs) {
                    await DatabaseService.deleteChat(user.uid, doc.id);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('All chats cleared.'),
                        backgroundColor: const Color(0xFF171717),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  }
                }
              },
            ),

            _SettingsOption(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              labelColor: Colors.redAccent,
              iconColor: Colors.redAccent,
              onTap: () async {
                Navigator.of(ctx).pop();
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthGate()),
                    (route) => false,
                  );
                }
              },
            ),

            const SizedBox(height: 16),

            // ── App version ──
            Center(
              child: Text(
                'Jeeni AI  ·  v1.0.0  ·  Built with \u2764\ufe0f',
                style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          _searchQuery.isNotEmpty ? 'No matching chats found.' : '📚 No chats found.',
          style: const TextStyle(color: _textSecondary, fontSize: 14), // Larger font size
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, String email) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        children: [
          _BottomItem(
            icon: Icons.add_rounded,
            label: 'New Chat',
            onTap: () {
              Navigator.of(context).pop();
              widget.onNewChat();
            },
          ),
          _BottomItem(
            icon: Icons.lock_person_outlined,
            label: 'Private Chat',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TempChatScreen()));
            },
          ),
          _BottomItem(
            icon: Icons.history_rounded,
            label: 'All History',
            onTap: () async {
              Navigator.of(context).pop();
              final selectedChatId = await Navigator.of(context).push<String>(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
              if (selectedChatId != null && selectedChatId.isNotEmpty) {
                widget.onChatSelected(selectedChatId);
              }
            },
          ),
          _BottomItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () {
              // Close drawer first, then show settings sheet
              Navigator.of(context).pop();
              final u = FirebaseAuth.instance.currentUser;
              if (u != null) {
                Future.microtask(() => _showSettingsSheet(context, u));
              }
            },
          ),
          _BottomItem(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            onTap: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
              );
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthGate()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 2),
          _ProfileRow(email: email),
        ],
      ),
    );
  }
}

class _BottomItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _BottomItem({required this.icon, required this.label, required this.onTap});

  @override
  State<_BottomItem> createState() => _BottomItemState();
}

class _BottomItemState extends State<_BottomItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF1A1A1A) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 14, color: const Color(0xFFA1A1AA)),
              const SizedBox(width: 6),
              Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 13)), // Larger text size (from 12 to 13)
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String email;
  const _ProfileRow({required this.email});

  @override
  Widget build(BuildContext context) {
    final letter = email.isNotEmpty ? email[0].toUpperCase() : 'J';
    final name = email.split('@').first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF2E2E2E),
            ),
            child: Center(
              child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), // Larger text size
            ),
          ),
          const Icon(Icons.more_horiz, size: 14, color: Color(0xFFA1A1AA)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// SETTINGS OPTION ROW
// ═══════════════════════════════════════════════════

class _SettingsOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsOption({
    required this.icon,
    required this.label,
    this.labelColor,
    this.iconColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? const Color(0xFFA1A1AA)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor ?? Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) trailing!
            else if (onTap != null)
              Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

// Keep SidebarChat model definition for legacy imports
class SidebarChat {
  final String id;
  final String title;
  final DateTime lastUpdated;
  final String category;

  const SidebarChat({
    required this.id,
    required this.title,
    required this.lastUpdated,
    this.category = 'Chats',
  });
}
