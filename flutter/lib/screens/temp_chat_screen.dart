import 'dart:async';
import 'dart:io' show File;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_message.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input_bar.dart';
import '../services/ai_service.dart';
import 'auth/login_screen.dart';
import 'auth/auth_gate.dart';

// ═══════════════════════════════════════════════════
// TEMPORARY CHAT SCREEN (PRIVATE MODE)
// ═══════════════════════════════════════════════════

class TempChatScreen extends StatefulWidget {
  const TempChatScreen({super.key});

  @override
  State<TempChatScreen> createState() => _TempChatScreenState();
}

class _TempChatScreenState extends State<TempChatScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  bool _isTyping = false;
  int _userMessageCount = 0;
  bool _hasPromptedLogin = false;
  String _selectedModel = 'Guided Learning';

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
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

  Future<void> _sendMessage(String text, {List<XFile> attachments = const []}) async {
    final t = text.trim();
    if (t.isEmpty && attachments.isEmpty) return;
    _inputController.clear();

    final displayText = t.isNotEmpty ? t : (attachments.isNotEmpty ? '📎 Attached file(s)' : '');

    setState(() {
      _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: displayText,
          isUser: true,
          timestamp: DateTime.now()));
      _isTyping = true;
      _userMessageCount++;
    });
    _scrollToBottom();

    // Trigger Login Prompt after 3 messages for unsigned users
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    if (!isLoggedIn && _userMessageCount >= 3 && !_hasPromptedLogin) {
      _hasPromptedLogin = true;
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      _showLoginPrompt();
      setState(() => _isTyping = false);
      return;
    }

    // Call Gemini AI
    try {
      final promptForAI = t.isNotEmpty ? t : 'Carefully examine and explain exactly what is shown in this image in detail. Describe every element, diagram, chart, or text you can see.';
      final historyForAI = _messages.length > 1
          ? _messages.sublist(0, _messages.length - 1)
          : <ChatMessage>[];

      final aiText = await AIService.generateResponse(
        prompt: promptForAI,
        mode: _selectedModel,
        history: historyForAI,
        attachments: attachments,
      );
      if (!mounted) return;

      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: aiText,
            isUser: false,
            timestamp: DateTime.now()));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: '⚠️ Jeeni is currently busy.\n\nPlease wait a few seconds and try again. If the issue continues, check your internet connection and try again later.',
            isUser: false,
            timestamp: DateTime.now()));
      });
    }
    _scrollToBottom();
    HapticFeedback.lightImpact();
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

  void _showLoginPrompt() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            child: FadeTransition(
              opacity: anim1,
              child: AlertDialog(
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: Colors.white.withOpacity(0.1))),
                contentPadding: const EdgeInsets.all(24),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 15)],
                      ),
                      child: const Icon(Icons.security_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Privacy & Persistence',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You are in Temporary Mode. To keep these conversations forever, please sign in.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () {
                           Navigator.of(context).push(
                             MaterialPageRoute(builder: (_) => const LoginScreen()),
                           );
                         },
                        child: const Text('Login to Sync', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Stay Temporary', style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMessages = _messages.isNotEmpty || _isTyping;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // ── Background Genie Image ──
          if (!hasMessages)
            Center(
              child: Opacity(
                opacity: 0.4, // Adjusted opacity for the new black background image
                child: Image.asset(
                  'assets/images/dashed_genie.png',
                  width: MediaQuery.of(context).size.width * 0.75, // 75% of screen width for perfect balance
                  fit: BoxFit.contain,
                ),
              ),
            ),

          Column(
            children: [
              _TempTopBar(),

              Expanded(
                child: hasMessages
                    ? _buildMessages()
                    : _TempEmptyState(onSend: _sendMessage),
              ),

              // ── Use the exact same Input Panel as main chat ──
              ChatInputBar(
                controller: _inputController, 
                onSend: _sendMessage, 
                isTyping: _isTyping,
                selectedModel: _selectedModel,
                onModelTap: _showModelSelector,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editMessage(int index, String newText) async {
    if (index < 0 || index >= _messages.length) return;
    
    final originalMessage = _messages[index];

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
// UI COMPONENTS (Matching Main Chat Style)
// ═══════════════════════════════════════════════════

class _TempTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final canPop = Navigator.of(context).canPop();
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    return Container(
      height: 60 + top,
      padding: EdgeInsets.fromLTRB(16, top, 16, 0),
      color: Colors.transparent,
      child: Row(
        children: [
          canPop
              ? IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                )
              : const SizedBox(width: 48),
          const Spacer(),
          const Text('JEENI', style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w400, color: Colors.white, letterSpacing: 8, fontFamily: 'serif',
          )),
          const Spacer(),
          GestureDetector(
            onTap: () {
              if (isLoggedIn) {
                if (canPop) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const AuthGate()),
                  );
                }
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isLoggedIn ? Colors.white.withOpacity(0.1) : Colors.transparent,
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Text(
                isLoggedIn ? 'Main Chat' : 'Login',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TempEmptyState extends StatelessWidget {
  final Function(String) onSend;
  const _TempEmptyState({required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          // Central Privacy Title
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_person_rounded, size: 42, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 16),
                Text(
                  'PRIVATE SESSION',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Temporary chat • No history saved',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 100), // Push up slightly from center
              ],
            ),
          ),

          // Bottom Feature Row (Clean like main chat)
          Positioned(
            left: 0, right: 0, bottom: 12,
            child: _FeatureRow(),
          ),
        ],
      ),
    );
  }
}

// FeatureRow and other components remain as they are unique to the empty state of private chat
class _FeatureRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _item(Icons.chat_bubble_outline_rounded, 'Ask Anything'),
          _divider(),
          _item(Icons.hub_outlined, 'Learn Faster'),
          _divider(),
          _item(Icons.track_changes_rounded, 'Achieve More'),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Icon(icon, color: Colors.white.withOpacity(0.45), size: 15),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w400)),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 28, color: Colors.white.withOpacity(0.06), margin: const EdgeInsets.symmetric(horizontal: 4));
}
