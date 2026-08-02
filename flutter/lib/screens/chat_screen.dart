import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/empty_chat_state.dart';
import '../widgets/chat_sidebar.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import 'dart:io';

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
  String _selectedModel = 'Guided Learning';

  StreamSubscription<List<ChatMessage>>? _messagesSubscription;
  String? _currentChatId;

  // Serialises all Firestore writes so createChat() is only ever called once
  // per session, even if the user sends messages rapidly.
  Future<void> _saveQueue = Future.value();
  bool _chatCreationStarted = false;

  @override
  void initState() {
    super.initState();
    _currentChatId = widget.chatId;
    _setupMessagesSubscription();
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
    'Explain the concept of Circle Area with an interactive model.\n\n[interactive:circle_area]',
    'Simulate Force, Mass, and Acceleration using Newton\'s second law.\n\n[interactive:newton_second_law]',
    'Plot algebraic straight lines using the Linear Equation grapher.\n\n[interactive:graph_plotter]',
    'Explore Sine and Cosine shadows using the Trigonometry Unit Circle.\n\n[interactive:unit_circle]',
    'Build stable Helium atoms in the Chemical Atom Builder.\n\n[interactive:atom_builder]',
    'Simulate heartbeat dynamics and cardiac cycles in the Biology Heart Pump.\n\n[interactive:heart_pump]',
    'Rotate the Earth and change axial tilts in the Geography orbital simulation.\n\n[interactive:earth_rotation]',
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
    setState(() {
      _currentChatId = null;
      _chatCreationStarted = false;
      _saveQueue = Future.value();
      _messages.clear();
    });
    _setupMessagesSubscription();
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
  }

  void _onChatTap(String chatId) {
    // Close drawer first if open
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
    setState(() {
      _currentChatId = chatId;
      // Reset save queue state — this is an existing chat so no creation needed
      _chatCreationStarted = true;
      _saveQueue = Future.value();
      _messages.clear();
      _isLoadingChat = true; // show spinner while Firestore loads
    });
    _setupMessagesSubscription();
  }

  Future<void> _sendMessage(String text, {List<File> attachments = const []}) async {
    final t = text.trim();
    if (t.isEmpty && attachments.isEmpty) return;
    _inputController.clear();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final displayText = t.isNotEmpty ? t : (attachments.isNotEmpty ? '📎 Attached file(s)' : '');

    final userMsgId = DateTime.now().millisecondsSinceEpoch.toString();
    final userMessage = ChatMessage(
      id: userMsgId,
      text: displayText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Show user message locally immediately (so screen is never blank)
    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _scrollToBottom();

    // Save to Firestore in background - never await so AI is never blocked
    _saveToFirestoreInBackground(user.uid, userMessage, t, attachments);

    // Call Gemini AI immediately — uses local messages minus the just-added one
    final historyForAI = _messages.length > 1
        ? _messages.sublist(0, _messages.length - 1)
        : <ChatMessage>[];

    final promptForAI = t.isNotEmpty ? t : 'Please describe or analyse the attached file(s).';

    final aiText = await AIService.generateResponse(
      prompt: promptForAI,
      mode: _selectedModel,
      history: historyForAI,
      attachments: attachments,
    );
    if (!mounted) return;

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
  }

  /// Saves to Firestore without blocking the UI. Creates chat session if needed.
  /// All calls are chained onto _saveQueue so createChat() runs EXACTLY ONCE.
  void _saveToFirestoreInBackground(String uid, ChatMessage userMessage, String text, List<File> attachments) {
    _saveQueue = _saveQueue.then((_) async {
      try {
        // Only create the chat if we haven't started creating it yet
        if (_currentChatId == null && !_chatCreationStarted) {
          _chatCreationStarted = true;
          final title = text.isNotEmpty ? text : (attachments.isNotEmpty ? 'File/Image conversation' : 'New chat');
          final newChatId = await DatabaseService.createChat(uid, title)
              .timeout(const Duration(seconds: 15));
          if (mounted) setState(() => _currentChatId = newChatId);
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
            color: const Color(0xFF0F172A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Select AI Model', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              _buildModelOption('Guided Learning', Icons.school_outlined, 'Step-by-step educational breakdown', Colors.blue),
              _buildModelOption('Deep Research', Icons.biotech_outlined, 'In-depth analysis and comprehensive data', Colors.purple),
              _buildModelOption('Web Search', Icons.travel_explore_rounded, 'Real-time simulated web aggregated results', Colors.green),
              _buildModelOption('Homework', Icons.menu_book_rounded, 'Homework helper focusing on hints', Colors.orange),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelOption(String title, IconData icon, String description, Color color) {
    final isSelected = _selectedModel == title;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedModel = title);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color.withOpacity(0.5) : Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05), shape: BoxShape.circle),
              child: Icon(icon, color: isSelected ? color : Colors.white.withOpacity(0.5), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                  const SizedBox(height: 4),
                  Text(description, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMessages = _messages.isNotEmpty || _isTyping;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0D0D0D),
      drawer: Drawer(
        width: 270,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ChatSidebar(
          activeChatId: _currentChatId,
          onNewChat: _newChat,
          onChatSelected: (chatId) => _onChatTap(chatId),
          onSettingsTap: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.black),
        child: Column(
          children: [
            // ── Top Nav ──
            _TopBar(
              onMenu: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              onNewChat: _newChat,
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
                      : EmptyChatState(suggestions: _suggestions, onSuggestionTap: _sendMessage),
            ),

            // ── Input Panel ──
            ChatInputBar(
              controller: _inputController, 
              onSend: _sendMessage, 
              isTyping: _isTyping,
              selectedModel: _selectedModel,
              onModelTap: _showModelSelector,
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

    setState(() {
      _messages.removeRange(index + 1, _messages.length);
      _messages[index] = updatedMessage;
      _isTyping = true;
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
    
    try {
      final aiText = await AIService.generateResponse(
        prompt: newText,
        mode: _selectedModel,
        history: historyForAI,
        attachments: const [],
      );
      if (!mounted) return;

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
      setState(() {
        _isTyping = false;
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
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _messages.length && _isTyping) return const TypingIndicator();
        final message = _messages[i];
        return ChatBubble(
          message: message,
          onEdit: message.isUser ? (newText) => _editMessage(i, newText) : null,
          onRegenerate: message.isUser ? null : () => _regenerateMessage(i),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════
// TOP BAR — Exact match to reference image
// ═══════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final VoidCallback onMenu;
  final VoidCallback onNewChat;
  const _TopBar({required this.onMenu, required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      height: 60 + top,
      padding: EdgeInsets.fromLTRB(16, top, 16, 0),
      color: const Color(0xFF0D0D0D),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Hamburger (history menu) ──
          GestureDetector(
            onTap: onMenu,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 36, height: 36,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 22, height: 1.5, color: Colors.white.withOpacity(0.8)),
                  const SizedBox(height: 5),
                  Container(width: 18, height: 1.5, color: Colors.white.withOpacity(0.8)),
                  const SizedBox(height: 5),
                  Container(width: 22, height: 1.5, color: Colors.white.withOpacity(0.8)),
                ],
              ),
            ),
          ),

          const Spacer(),

          // ── "JEENI" title ──
          const Text('JEENI', style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            letterSpacing: 8,
            fontFamily: 'serif',
          )),

          const Spacer(),

          // ── Spacer to balance layout ──
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}
