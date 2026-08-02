import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Main filter tabs
  final List<String> _filters = ['All', 'Subjects', 'Projects', 'Favorites'];
  int _selectedFilterIndex = 0;

  // Selected sub-filters
  String _selectedSubject = 'All';
  String? _selectedProjectId; // null = all projects

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
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  // Confirm delete dialog for single/multiple
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
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(
          chatIds.length == 1
              ? 'This conversation will be permanently deleted.'
              : 'These ${chatIds.length} conversations will be permanently deleted.',
          style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFA1A1AA))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        title: const Text('Rename Conversation', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: 'Enter new name...',
            hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
            filled: true,
            fillColor: const Color(0xFF202020),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2B2B2B))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFA1A1AA))),
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
        title: const Text('Create Project', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: 'Project name...',
            hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
            filled: true,
            fillColor: const Color(0xFF202020),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2B2B2B))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFA1A1AA))),
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
        title: const Text('Rename Project', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: 'Enter new name...',
            hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
            filled: true,
            fillColor: const Color(0xFF202020),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2B2B2B))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFA1A1AA))),
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
        title: const Text('Delete Project?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Delete "$projectName"? Chats associated with this project will be kept but moved to no project.', style: const TextStyle(color: Color(0xFFA1A1AA))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFA1A1AA))),
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
              child: Text('Move to Project', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                leading: Icon(Icons.folder_outlined, color: isCurrent ? Colors.white : Colors.white70),
                title: Text(p['name'] ?? '', style: TextStyle(color: isCurrent ? Colors.white : Colors.white)),
                trailing: isCurrent ? const Icon(Icons.check_rounded, color: Colors.white) : null,
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

  void _shareChat(Map<String, dynamic> chat) {
    final title = chat['title'] ?? 'No Title';
    final lastMsg = chat['lastMessage'] ?? '';
    Clipboard.setData(ClipboardData(text: 'Jeeni Chat: "$title"\n\nLast message: $lastMsg'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Chat summary copied to clipboard!'),
        backgroundColor: const Color(0xFF171717),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 1),
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
                  Navigator.of(context).pop(chatId);
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
                leading: const Icon(Icons.share_outlined, color: Colors.white),
                title: const Text('Share Summary', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _shareChat(chat);
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

  void _showDesktopMenu(BuildContext context, Offset position, Map<String, dynamic> chat, String userId, List<Map<String, dynamic>> projects) {
    final chatId = chat['id'] ?? '';
    final title = chat['title'] ?? '';
    final isStarred = chat['isStarred'] == true;
    final isPinned = chat['isPinned'] == true;
    final currentProjectId = chat['projectId'];

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      color: const Color(0xFF171717),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF2B2B2B))),
      items: [
        const PopupMenuItem(value: 'open', child: Text('Open Chat', style: TextStyle(color: Colors.white))),
        PopupMenuItem(value: 'pin', child: Text(isPinned ? 'Unpin' : 'Pin', style: const TextStyle(color: Colors.white))),
        PopupMenuItem(value: 'favorite', child: Text(isStarred ? 'Remove Favorite' : 'Mark Favorite', style: const TextStyle(color: Colors.white))),
        const PopupMenuItem(value: 'rename', child: Text('Rename', style: TextStyle(color: Colors.white))),
        const PopupMenuItem(value: 'duplicate', child: Text('Duplicate', style: TextStyle(color: Colors.white))),
        const PopupMenuItem(value: 'project', child: Text('Move to Project', style: TextStyle(color: Colors.white))),
        const PopupMenuItem(value: 'share', child: Text('Share', style: TextStyle(color: Colors.white))),
        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
      ],
    ).then((choice) async {
      if (choice == null) return;
      switch (choice) {
        case 'open':
          if (mounted) Navigator.of(context).pop(chatId);
          break;
        case 'pin':
          await DatabaseService.togglePinChat(userId, chatId, !isPinned);
          break;
        case 'favorite':
          await DatabaseService.toggleStarChat(userId, chatId, !isStarred);
          break;
        case 'rename':
          _renameChatDialog(chatId, title, userId);
          break;
        case 'duplicate':
          await DatabaseService.duplicateChat(userId, chatId);
          break;
        case 'project':
          _moveChatToProjectSheet(chatId, currentProjectId, userId, projects);
          break;
        case 'share':
          _shareChat(chat);
          break;
        case 'delete':
          _confirmDeleteChats(chatIds: [chatId], userId: userId);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDesktop = Theme.of(context).platform != TargetPlatform.android &&
        Theme.of(context).platform != TargetPlatform.iOS;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('Please log in to view chat history.', style: TextStyle(color: Colors.white)))
            : StreamBuilder<List<Map<String, dynamic>>>(
                stream: DatabaseService.getChatsStream(user.uid),
                builder: (context, chatSnapshot) {
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: DatabaseService.getProjectsStream(user.uid),
                    builder: (context, projSnapshot) {
                      final chatsList = chatSnapshot.data ?? [];
                      final projects = projSnapshot.data ?? [];

                      // 1. Process search filtering
                      var filtered = chatsList;
                      if (_searchQuery.isNotEmpty) {
                        filtered = filtered.where((c) {
                          final title = (c['title'] ?? '').toString().toLowerCase();
                          final lastMsg = (c['lastMessage'] ?? '').toString().toLowerCase();
                          return title.contains(_searchQuery.toLowerCase()) || lastMsg.contains(_searchQuery.toLowerCase());
                        }).toList();
                      }

                      // 2. Process Tab filter
                      if (_selectedFilterIndex == 1) {
                        // Subjects tab
                        if (_selectedSubject != 'All') {
                          filtered = filtered.where((c) => c['subject'] == _selectedSubject).toList();
                        }
                      } else if (_selectedFilterIndex == 2) {
                        // Projects tab
                        if (_selectedProjectId != null) {
                          filtered = filtered.where((c) => c['projectId'] == _selectedProjectId).toList();
                        } else {
                          // Show only chats belonging to ANY project
                          filtered = filtered.where((c) => c['projectId'] != null).toList();
                        }
                      } else if (_selectedFilterIndex == 3) {
                        // Favorites
                        filtered = filtered.where((c) => c['isStarred'] == true).toList();
                      }

                      // Grouping
                      final pinnedChats = <Map<String, dynamic>>[];
                      final todayChats = <Map<String, dynamic>>[];
                      final yesterdayChats = <Map<String, dynamic>>[];
                      final olderChats = <Map<String, dynamic>>[];

                      final now = DateTime.now();
                      final todayStart = DateTime(now.year, now.month, now.day);
                      final yesterdayStart = todayStart.subtract(const Duration(days: 1));

                      for (var c in filtered) {
                        if (c['isPinned'] == true) {
                          pinnedChats.add(c);
                        } else {
                          final lastUpdatedMs = c['lastUpdated'] ?? 0;
                          final lastUpdated = DateTime.fromMillisecondsSinceEpoch(lastUpdatedMs);
                          if (lastUpdated.isAfter(todayStart)) {
                            todayChats.add(c);
                          } else if (lastUpdated.isAfter(yesterdayStart)) {
                            yesterdayChats.add(c);
                          } else {
                            olderChats.add(c);
                          }
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTopBar(user.uid),
                          if (_showSearchBar) _buildSearchBarRow(),
                          _buildFilterTabsRow(),
                          if (_selectedFilterIndex == 1) _buildSubjectsSubRow(),
                          if (_selectedFilterIndex == 2) _buildProjectsSubRow(user.uid, projects),
                          
                          Expanded(
                            child: chatSnapshot.connectionState == ConnectionState.waiting
                                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                                : chatSnapshot.hasError
                                    ? Center(child: Text('Error loading history: ${chatSnapshot.error}', style: const TextStyle(color: Colors.redAccent)))
                                    : filtered.isEmpty
                                        ? _buildEmptyState()
                                        : ListView(
                                            physics: const BouncingScrollPhysics(),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            children: [
                                              if (pinnedChats.isNotEmpty) ...[
                                                _buildSectionHeader('Pinned'),
                                                ...pinnedChats.map((c) => _buildChatItemRow(c, user.uid, projects, isDesktop)),
                                                const SizedBox(height: 8),
                                              ],
                                              if (todayChats.isNotEmpty) ...[
                                                _buildSectionHeader('Today'),
                                                ...todayChats.map((c) => _buildChatItemRow(c, user.uid, projects, isDesktop)),
                                                const SizedBox(height: 8),
                                              ],
                                              if (yesterdayChats.isNotEmpty) ...[
                                                _buildSectionHeader('Yesterday'),
                                                ...yesterdayChats.map((c) => _buildChatItemRow(c, user.uid, projects, isDesktop)),
                                                const SizedBox(height: 8),
                                              ],
                                              if (olderChats.isNotEmpty) ...[
                                                _buildSectionHeader('Previous Days'),
                                                ...olderChats.map((c) => _buildChatItemRow(c, user.uid, projects, isDesktop)),
                                                const SizedBox(height: 8),
                                              ],
                                            ],
                                          ),
                          ),
                          if (_isMultiSelectMode) _buildMultiSelectActionBar(user.uid),
                        ],
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildTopBar(String userId) {
    return Container(
      height: 48, // Reduced height (ChatGPT layout style)
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          const Text(
            'JEENI',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              letterSpacing: 4,
              fontFamily: 'serif',
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close_rounded : Icons.search_rounded, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(_isMultiSelectMode ? Icons.check_circle_rounded : Icons.checklist_rtl_rounded,
                color: _isMultiSelectMode ? Colors.white : Colors.white70, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _isMultiSelectMode = !_isMultiSelectMode;
                _selectedChatIds.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBarRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(color: Color(0xFF111111)),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: 'Search chats...',
          hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFA1A1AA), size: 18),
          filled: true,
          fillColor: const Color(0xFF171717),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2B2B2B))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildFilterTabsRow() {
    return Container(
      height: 38, // Reduced height (44 -> 38)
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (ctx, i) {
          final isSelected = _selectedFilterIndex == i;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedFilterIndex = i;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF202020) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? Colors.white : const Color(0xFF2B2B2B)),
              ),
              child: Text(
                _filters[i],
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFA1A1AA),
                  fontSize: 13, // Larger readable font size
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
      height: 32, // Reduced height
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _subjects.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (ctx, i) {
          final sub = _subjects[i];
          final isSelected = _selectedSubject == sub;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedSubject = sub;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF171717) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isSelected ? Colors.white : Colors.transparent),
              ),
              child: Text(
                sub,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFA1A1AA),
                  fontSize: 12, // Clear font size
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
      height: 32, // Reduced height
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          GestureDetector(
            onTap: () => setState(() {
              _selectedProjectId = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _selectedProjectId == null ? const Color(0xFF171717) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _selectedProjectId == null ? Colors.white : Colors.transparent),
              ),
              child: Text(
                'All Projects',
                style: TextStyle(
                  color: _selectedProjectId == null ? Colors.white : const Color(0xFFA1A1AA),
                  fontSize: 12,
                  fontWeight: _selectedProjectId == null ? FontWeight.w600 : FontWeight.w400,
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
              onLongPress: () => _projectActionsMenu(pId, name, userId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF171717) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isSelected ? Colors.white : Colors.transparent),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFFA1A1AA),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: () => _createProjectDialog(userId),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF2B2B2B)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text('New Project', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.only(left: 4, top: 12, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16, // H4 style
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChatItemRow(Map<String, dynamic> chat, String userId, List<Map<String, dynamic>> projects, bool isDesktop) {
    final chatId = chat['id'] ?? '';
    final title = chat['title'] ?? 'No Title';
    final lastMsg = chat['lastMessage'] ?? 'No message snippet.';
    final isStarred = chat['isStarred'] == true;
    final isPinned = chat['isPinned'] == true;
    final subject = chat['subject'] ?? 'General';
    final lastUpdated = chat['lastUpdated'] ?? 0;
    final timeStr = _formatTime(lastUpdated);

    if (_isMultiSelectMode) {
      final isSelected = _selectedChatIds.contains(chatId);
      return GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedChatIds.remove(chatId);
            } else {
              _selectedChatIds.add(chatId);
            }
          });
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // More compact height
          decoration: BoxDecoration(
            color: const Color(0xFF171717),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? Colors.white : const Color(0xFF2B2B2B)),
          ),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                activeColor: Colors.white,
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
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis), // Larger text size
                    const SizedBox(height: 2),
                    Text(lastMsg, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis), // Larger text size
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Dismissible(
      key: Key(chatId),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        color: const Color(0xFF333333),
        child: const Icon(Icons.push_pin_rounded, color: Colors.white, size: 16),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.redAccent,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 16),
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
        onTap: () {
          Navigator.of(context).pop(chatId);
        },
        onLongPressStart: (details) {
          if (isDesktop) {
            _showDesktopMenu(context, details.globalPosition, chat, userId, projects);
          } else {
            _showChatOptionsSheet(chat, userId, projects);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 4), // Compact bottom margin
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Reduced height padding
          decoration: BoxDecoration(
            color: const Color(0xFF171717),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2B2B2B)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isPinned)
                          const Padding(
                            padding: EdgeInsets.only(right: 6.0),
                            child: Icon(Icons.push_pin_rounded, color: Colors.white, size: 14),
                          ),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), // Larger font size (from 15 to 16)
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMsg,
                      style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14), // Larger font size (from 13 to 14)
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF202020), borderRadius: BorderRadius.circular(6)),
                      child: Text(subject, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12, fontWeight: FontWeight.bold)), // Larger font size
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(timeStr, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13)), // Larger font size (from 11 to 13)
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (isStarred)
                        const Icon(Icons.star_rounded, color: Color(0xFFFCD34D), size: 16),
                      const SizedBox(width: 6),
                      Icon(Icons.more_horiz_rounded, color: const Color(0xFFA1A1AA).withOpacity(0.5), size: 16),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectActionBar(String userId) {
    final count = _selectedChatIds.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(top: BorderSide(color: Color(0xFF2B2B2B), width: 1)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _isMultiSelectMode = false;
                  _selectedChatIds.clear();
                });
              },
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 14)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: count == 0
                  ? null
                  : () => _confirmDeleteChats(chatIds: _selectedChatIds.toList(), userId: userId),
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 16),
              label: Text('Delete Selected ($count)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 40, color: const Color(0xFFA1A1AA).withOpacity(0.3)),
            const SizedBox(height: 10),
            const Text(
              'No matching conversations found.',
              style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '📚 No conversations yet',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6),
            Text(
              'Start chatting with Jeeni to build your learning history.',
              style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
