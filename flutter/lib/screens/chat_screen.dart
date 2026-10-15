import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';
import '../models/student_profile.dart';
import '../models/jeeni_mode.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/empty_chat_state.dart';
import '../widgets/chat_sidebar.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import 'profile_settings_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../response_visualization/models/response_mode.dart';
import '../response_visualization/services/adaptive_response_classifier.dart';
import '../thinking_orbs/models/orb_state.dart';
import '../thinking_orbs/services/orb_state_resolver.dart';
import '../thinking_orbs/widgets/thinking_orbs_response_view.dart';

class ChatScreen extends StatefulWidget {
  final String? chatId;
  const ChatScreen({super.key, this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  bool _isTyping = false;
  bool _isLoadingChat = false;
  JeeniMode _selectedMode = JeeniMode.learning;
  StudentProfile? _studentProfile;

  StreamSubscription<List<ChatMessage>>? _messagesSubscription;
  String? _currentChatId;

  // Serialises all Firestore writes so createChat() is only ever called once
  // per session, even if the user sends messages rapidly.
  Future<void> _saveQueue = Future.value();
  bool _chatCreationStarted = false;

  AdaptiveAnimationConfig? _activeAnimationConfig;
  int _currentRequestId = 0;
  bool _isSidebarOpen = true;

  void _stopGeneration() {
    if (!_isTyping) return;
    setState(() {
      _isTyping = false;
      _currentRequestId++;
      _activeAnimationConfig = null;
    });
    HapticFeedback.mediumImpact();
  }

  @override
  void initState() {
    super.initState();
    _currentChatId = widget.chatId;
    _setupMessagesSubscription();
    _loadStudentProfile();
  }

  Future<void> _loadStudentProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final p = await DatabaseService.getStudentProfile(user.uid);
      if (mounted) setState(() => _studentProfile = p);
    }
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chatId != oldWidget.chatId) {
      setState(() {
        _currentChatId = widget.chatId;
      });
      _setupMessagesSubscription();
    }
  }

  void _setupMessagesSubscription() {
    _messagesSubscription?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _currentChatId != null) {
      _messagesSubscription = DatabaseService.getMessagesStream(user.uid, _currentChatId!).listen((messages) {
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(messages);
            _isLoadingChat = false; // done loading
          });
          _scrollToBottom();
        }
      }, onError: (e) {
        // Firestore not available - keep local messages
        debugPrint('Firestore stream error: $e');
        if (mounted) setState(() => _isLoadingChat = false);
      });
    } else if (_currentChatId == null) {
      // Only clear if starting a truly new chat
      setState(() {
        _messages.clear();
        _isLoadingChat = false;
      });
    }
  }

  final _suggestions = <String>[
    'Explain the concept of Circle Area and how it is derived.',
    'Simulate Force, Mass, and Acceleration using Newton\'s second law.',
    'Plot algebraic straight lines using the Linear Equation grapher.',
    'Explore Sine and Cosine shadows using the Trigonometry Unit Circle.',
    'Explain the atomic structure of Helium and periodic table trends.',
    'Explain heartbeat dynamics and cardiac cycles in the human heart.',
    'Why does the Earth have seasons and how does axial tilt work?',
  ];



  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _newChat() {
    _stopGeneration();
    setState(() {
      _currentChatId = null;
      _chatCreationStarted = false;
      _saveQueue = Future.value();
      _messages.clear();
      _activeAnimationConfig = null;
      _isLoadingChat = false;
    });
    _setupMessagesSubscription();
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  void _onChatTap(String chatId) {
    _stopGeneration();
    // Close drawer safely without popping any route
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      _scaffoldKey.currentState?.closeDrawer();
    }
    setState(() {
      _currentChatId = chatId;
      // Reset save queue state — this is an existing chat so no creation needed
      _chatCreationStarted = true;
      _saveQueue = Future.value();
      _messages.clear();
      _isLoadingChat = true; // show spinner while Firestore loads
      _activeAnimationConfig = null;
    });
    _setupMessagesSubscription();
    // Safety guard: guarantee _isLoadingChat is cleared within 4s even if stream is silent
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _isLoadingChat) {
        setState(() => _isLoadingChat = false);
      }
    });
  }

  Future<void> _sendMessage(String text, {List<XFile> attachments = const [], JeeniMode? mode}) async {
    if (_isTyping) return;
    final t = text.trim();
    if (t.isEmpty && attachments.isEmpty) return;
    _inputController.clear();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final effectiveMode = mode ?? _selectedMode;
    final displayText = t.isNotEmpty ? t : (attachments.isNotEmpty ? '📎 Attached file(s)' : '');

    final sessionChatId = _currentChatId;
    final thisRequestId = ++_currentRequestId;
    final userMsgId = DateTime.now().millisecondsSinceEpoch.toString();

    // Instant adaptive classification before network dispatch
    final animConfig = AdaptiveResponseClassifier.classify(
      prompt: t,
      mode: effectiveMode.label,
      attachments: attachments,
    );

    // ── Build structured attachment metadata from XFiles ──────────
    // This is the authoritative mapping point: XFile → MessageAttachment.
    // Previously userMessage was created WITHOUT attachments — that was the bug.
    final List<MessageAttachment> msgAttachments = [];
    for (final xfile in attachments) {
      final name = xfile.name;
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
      const imageExts = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'heic'];
      final isImage = imageExts.contains(ext);
      String mimeType = 'application/octet-stream';
      if (ext == 'png') {
        mimeType = 'image/png';
      } else if (ext == 'jpg' || ext == 'jpeg') {
        mimeType = 'image/jpeg';
      } else if (ext == 'webp') {
        mimeType = 'image/webp';
      } else if (ext == 'gif') {
        mimeType = 'image/gif';
      } else if (ext == 'bmp') {
        mimeType = 'image/bmp';
      } else if (ext == 'heic') {
        mimeType = 'image/heic';
      } else if (ext == 'txt' || ext == 'md' || ext == 'csv') {
        mimeType = 'text/plain';
      }
      final attachType = isImage ? 'image' : 'text_file';
      int sizeBytes = 0;
      String? b64;
      try {
        final bytes = await xfile.readAsBytes();
        sizeBytes = bytes.length;
        if (isImage && bytes.isNotEmpty && bytes.length <= 750 * 1024) {
          b64 = base64Encode(bytes);
        }
      } catch (_) {}
      msgAttachments.add(MessageAttachment(
        type: attachType,
        name: name,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        localPath: kIsWeb ? null : xfile.path,
        base64Data: b64,
      ));
      debugPrint('[Jeeni Attachment] selected: true | type: $attachType | name: $name | mime: $mimeType | size: ${sizeBytes}B | hasB64: ${b64 != null}');
    }
    debugPrint('[Jeeni Send] textLength: ${t.length} | attachmentCount: ${attachments.length}');

    final userMessage = ChatMessage(
      id: userMsgId,
      text: displayText,
      isUser: true,
      timestamp: DateTime.now(),
      attachments: msgAttachments, // ← FIX: was missing before
    );

    // Show user message locally immediately (so screen is never blank)
    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
      _activeAnimationConfig = animConfig;
    });
    _scrollToBottom();

    // Save to Firestore in background - never await so AI is never blocked
    _saveToFirestoreInBackground(user.uid, userMessage, t, attachments);

    // Call Gemini AI immediately — uses local messages minus the just-added one
    final historyForAI = _messages.length > 1
        ? _messages.sublist(0, _messages.length - 1)
        : <ChatMessage>[];

    final promptForAI = t.isNotEmpty ? t : 'Carefully examine and explain exactly what is shown in this image in detail. Describe every element, diagram, chart, or text you can see.';

    var currentProfile = _studentProfile;
    if (currentProfile == null) {
      currentProfile = await DatabaseService.getStudentProfile(user.uid);
      if (mounted && currentProfile != null) {
        _studentProfile = currentProfile;
      }
    }

    try {
      final aiText = await AIService.generateResponse(
        prompt: promptForAI,
        mode: effectiveMode.id,
        history: historyForAI,
        attachments: attachments,
        studentId: user.uid,
        profile: currentProfile,
      );
      if (!mounted) return;

      // Stop/Cancellation Guard: Discard if request was cancelled or stopped by student
      if (_currentRequestId != thisRequestId) {
        debugPrint('[Chat] Request #$thisRequestId was cancelled/stopped. Suppressing local append.');
        return;
      }

      // Cross-Chat Isolation Guard: If user navigated to another chat while generation was active, discard local append
      if (_currentChatId != sessionChatId && sessionChatId != null) {
        debugPrint('[Chat] Active chat changed during AI generation. Suppressing local append to prevent cross-chat leakage.');
        return;
      }

      final aiMsgId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
      final aiMessage = ChatMessage(
        id: aiMsgId,
        text: aiText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
        _isTyping = false;
        _activeAnimationConfig = null;
      });
      _scrollToBottom();
      HapticFeedback.lightImpact();

      // Save AI response to Firestore — chain onto the save queue so it waits
      // for the chat session to be created first.
      _saveQueue = _saveQueue.then((_) async {
        try {
          if (_currentChatId != null) {
            await DatabaseService.saveMessage(user.uid, _currentChatId!, aiMessage)
                .timeout(const Duration(seconds: 15));
          }
        } catch (e) {
          debugPrint('Firestore AI save failed (non-critical): $e');
        }
      });
    } catch (e) {
      if (!mounted) return;
      if (_currentRequestId != thisRequestId) return;
      setState(() {
        _isTyping = false;
        _activeAnimationConfig = null;
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: '⚠️ Jeeni is currently busy.\n\nPlease wait a few seconds and try again. If the issue continues, check your internet connection and try again later.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  /// Saves to Firestore without blocking the UI. Creates chat session if needed.
  /// All calls are chained onto _saveQueue so createChat() runs EXACTLY ONCE.
  void _saveToFirestoreInBackground(String uid, ChatMessage userMessage, String text, List<XFile> attachments) {
    _saveQueue = _saveQueue.then((_) async {
      try {
        // Only create the chat if we haven't started creating it yet
        if (_currentChatId == null && !_chatCreationStarted) {
          _chatCreationStarted = true;
          final title = text.isNotEmpty ? text : (attachments.isNotEmpty ? 'File/Image conversation' : 'New chat');
          final newChatId = await DatabaseService.createChat(uid, title)
              .timeout(const Duration(seconds: 15));
          if (mounted) {
            setState(() => _currentChatId = newChatId);
            _setupMessagesSubscription();
          }
        }
        // Wait until _currentChatId is available (it will be after createChat)
        if (_currentChatId != null) {
          await DatabaseService.saveMessage(uid, _currentChatId!, userMessage)
              .timeout(const Duration(seconds: 15));
        }
      } catch (e) {
        debugPrint('Firestore background save failed (non-critical): $e');
      }
    });
  }




  void _showModelSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 48),
          decoration: BoxDecoration(
            color: const Color(0xFF171717),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Jeeni Modes', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              ...JeeniMode.values.map((mode) => _buildModeOption(mode)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeOption(JeeniMode mode) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMode = mode);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? mode.color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? mode.color.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? mode.color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Text(mode.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mode.label, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                  const SizedBox(height: 4),
                  Text(mode.description, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: mode.color, size: 22),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final hasMessages = _messages.isNotEmpty || _isTyping;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0D0D0D),
      drawer: isDesktop
          ? null
          : Drawer(
              width: 280,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ChatSidebar(
                activeChatId: _currentChatId,
                onNewChat: _newChat,
                onChatSelected: (chatId) => _onChatTap(chatId),
                onSettingsTap: () async {
                  if (_scaffoldKey.currentState?.isDrawerOpen == true) {
                    Navigator.of(context).pop();
                  }
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
                  );
                  _loadStudentProfile();
                },
              ),
            ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.black),
        child: Row(
          children: [
            // ── Desktop Docked Sidebar ──
            if (isDesktop && _isSidebarOpen) ...[
              SizedBox(
                width: 270,
                child: ChatSidebar(
                  activeChatId: _currentChatId,
                  onNewChat: _newChat,
                  onChatSelected: (chatId) => _onChatTap(chatId),
                  onSettingsTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
                    );
                    _loadStudentProfile();
                  },
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1, color: Color(0xFF222222)),
            ],

            // ── Main Chat Area ──
            Expanded(
              child: Column(
                children: [
                  // ── Responsive Top Nav ──
                  _TopBar(
                    isDesktop: isDesktop,
                    isSidebarOpen: _isSidebarOpen,
                    selectedMode: _selectedMode,
                    onToggleSidebar: () {
                      if (isDesktop) {
                        setState(() => _isSidebarOpen = !_isSidebarOpen);
                      } else {
                        _scaffoldKey.currentState?.openDrawer();
                      }
                    },
                    onNewChat: _newChat,
                    onModeTap: _showModelSelector,
                    onProfileTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
                      );
                      _loadStudentProfile();
                    },
                  ),

                  // ── Content ──
                  Expanded(
                    child: _isLoadingChat
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 1.5,
                            ),
                          )
                        : hasMessages
                            ? _buildMessages()
                            : EmptyChatState(
                                suggestions: _suggestions,
                                onSuggestionTap: _sendMessage,
                              ),
                  ),

                  // ── Input Panel ──
                  ChatInputBar(
                    controller: _inputController,
                    onSend: _sendMessage,
                    isTyping: _isTyping,
                    selectedMode: _selectedMode,
                    onModeChanged: (m) => setState(() => _selectedMode = m),
                    onModelTap: _showModelSelector,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editMessage(int index, String newText) async {
    if (index < 0 || index >= _messages.length) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final originalMessage = _messages[index];
    final originalTimestamp = originalMessage.timestamp;

    final updatedMessage = ChatMessage(
      id: originalMessage.id,
      text: newText,
      isUser: true,
      timestamp: originalMessage.timestamp,
      attachments: originalMessage.attachments,
    );

    final editAnimConfig = AdaptiveResponseClassifier.classify(
      prompt: newText,
      mode: _selectedMode.label,
    );
    final thisRequestId = ++_currentRequestId;

    setState(() {
      _messages.removeRange(index + 1, _messages.length);
      _messages[index] = updatedMessage;
      _isTyping = true;
      _activeAnimationConfig = editAnimConfig;
    });
    _scrollToBottom();

    if (_currentChatId != null) {
      Future(() async {
        try {
          await DatabaseService.deleteMessagesAfter(user.uid, _currentChatId!, originalTimestamp);
          await DatabaseService.saveMessage(user.uid, _currentChatId!, updatedMessage);
        } catch (e) {
          debugPrint('Firestore edit clean failed: $e');
        }
      });
    }

    final historyForAI = _messages.sublist(0, index);
    
    var currentProfile = _studentProfile;
    if (currentProfile == null) {
      currentProfile = await DatabaseService.getStudentProfile(user.uid);
      if (mounted && currentProfile != null) {
        _studentProfile = currentProfile;
      }
    }

    try {
      final aiText = await AIService.generateResponse(
        prompt: newText,
        mode: _selectedMode.id,
        history: historyForAI,
        attachments: const [],
        studentId: user.uid,
        profile: currentProfile,
      );
      if (!mounted) return;
      if (_currentRequestId != thisRequestId) return;

      final aiMsgId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
      final aiMessage = ChatMessage(
        id: aiMsgId,
        text: aiText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
        _isTyping = false;
        _activeAnimationConfig = null;
      });
      _scrollToBottom();
      HapticFeedback.lightImpact();

      if (_currentChatId != null) {
        DatabaseService.saveMessage(user.uid, _currentChatId!, aiMessage)
            .timeout(const Duration(seconds: 5))
            .catchError((e) { debugPrint('Firestore edit AI save failed: $e'); });
      }
    } catch (e) {
      if (!mounted) return;
      if (_currentRequestId != thisRequestId) return;
      setState(() {
        _isTyping = false;
        _activeAnimationConfig = null;
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: '⚠️ Jeeni is currently busy.\n\nPlease wait a few seconds and try again. If the issue continues, check your internet connection and try again later.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  void _regenerateMessage(int index) {
    if (index <= 0) return;
    final userMsgIndex = index - 1;
    if (_messages[userMsgIndex].isUser) {
      _editMessage(userMsgIndex, _messages[userMsgIndex].text);
    }
  }

  Widget _buildMessages() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          itemCount: _messages.length + (_isTyping ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (i == _messages.length && _isTyping) {
              final state = _activeAnimationConfig != null
                  ? OrbStateResolver.resolveFromConfig(_activeAnimationConfig)
                  : OrbState.working;
              return ThinkingOrbsResponseView(
                state: state,
                config: _activeAnimationConfig,
                onStop: _stopGeneration,
              );
            }
            final message = _messages[i];
            return ChatBubble(
              message: message,
              onEdit: message.isUser ? (newText) => _editMessage(i, newText) : null,
              onRegenerate: message.isUser ? null : () => _regenerateMessage(i),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// TOP BAR — Responsive Top Navigation
// ═══════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final bool isDesktop;
  final bool isSidebarOpen;
  final JeeniMode selectedMode;
  final VoidCallback onToggleSidebar;
  final VoidCallback onNewChat;
  final VoidCallback onModeTap;
  final VoidCallback? onProfileTap;

  const _TopBar({
    required this.isDesktop,
    required this.isSidebarOpen,
    required this.selectedMode,
    required this.onToggleSidebar,
    required this.onNewChat,
    required this.onModeTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      height: 56 + (isDesktop ? 0 : top),
      padding: EdgeInsets.fromLTRB(16, isDesktop ? 0 : top, 16, 0),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D0D),
        border: Border(bottom: BorderSide(color: Color(0xFF1E1E1E), width: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sidebar Toggle button
          Tooltip(
            message: isDesktop ? (isSidebarOpen ? 'Close sidebar' : 'Open sidebar') : 'Chat history',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onToggleSidebar,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: Icon(
                    isDesktop
                        ? (isSidebarOpen ? Icons.menu_open_rounded : Icons.menu_rounded)
                        : Icons.menu_rounded,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // New Chat Button
          Tooltip(
            message: 'New chat',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onNewChat,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          // Center: Clean JEENI wordmark
          const Text(
            'JEENI',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              letterSpacing: 6,
              fontFamily: 'serif',
            ),
          ),

          const Spacer(),

          // Profile / Settings Action
          Tooltip(
            message: 'Student Profile & Settings',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onProfileTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E1B4B),
                    border: Border.all(color: const Color(0xFF818CF8).withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.school_outlined, color: Color(0xFF818CF8), size: 17),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
