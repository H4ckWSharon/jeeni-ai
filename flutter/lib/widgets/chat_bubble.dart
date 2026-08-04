import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../models/chat_message.dart';
import '../learning_engine/services/widget_registry.dart';

/// Strips internal Jeeni tags from message text before clipboard/display use
String _cleanText(String raw) {
  return raw
      .replaceAll(RegExp(r'\[interactive:[a-zA-Z0-9_-]+\]'), '')
      .replaceAll(RegExp(r'<<<RAG_SOURCES_START>>>[\s\S]*?<<<RAG_SOURCES_END>>>'), '')
      .replaceAll(RegExp(r'\[rag_sources:[\s\S]*?\]\]?'), '')
      .trim();
}


class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final void Function(String newText)? onEdit;
  final VoidCallback? onRegenerate;

  const ChatBubble({
    super.key,
    required this.message,
    this.onEdit,
    this.onRegenerate,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _isEditing = false;
  late TextEditingController _editController;
  bool _isHovered = false;
  bool? _isLiked; // null = no response, true = liked, false = disliked

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380))..forward();
    _editController = TextEditingController(text: widget.message.text);
  }

  @override
  void didUpdateWidget(ChatBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message.text != oldWidget.message.text) {
      _editController.text = widget.message.text;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _copyMessage() {
    // Strip internal widget/RAG tags so clipboard gets clean text
    final cleanedText = _cleanText(widget.message.text);
    Clipboard.setData(ClipboardData(text: cleanedText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard!'),
        backgroundColor: const Color(0xFF171717),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _likeMessage() {
    final newVal = _isLiked == true ? null : true;
    setState(() => _isLiked = newVal);
    HapticFeedback.selectionClick();
    if (newVal == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('👍 Thanks for the feedback!'),
          backgroundColor: const Color(0xFF171717),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _dislikeMessage() {
    final newVal = _isLiked == false ? null : false;
    setState(() => _isLiked = newVal);
    HapticFeedback.selectionClick();
    if (newVal == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('👎 Noted — Jeeni will do better!'),
          backgroundColor: const Color(0xFF171717),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Widget _actionIcon(IconData icon, String tooltip, VoidCallback onTap, {Color? color}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 15,
            color: color ?? const Color(0xFFA1A1AA),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(bool isUser) {
    if (isUser) {
      return SelectableText(
        widget.message.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          height: 1.7,
        ),
      );
    }

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _parseMessageText(widget.message.text, context),
      ),
    );
  }

  List<Widget> _parseMessageText(String rawText, BuildContext context) {
    final List<Widget> children = [];

    // Extract RAG sources if present (supports new & legacy tag formats)
    String text = rawText;
    List<dynamic> parsedSources = [];

    // 1. Try new delimiter: <<<RAG_SOURCES_START>>>...<<<RAG_SOURCES_END>>>
    final newRagMatch = RegExp(r'<<<RAG_SOURCES_START>>>([\s\S]*?)<<<RAG_SOURCES_END>>>').firstMatch(text);
    if (newRagMatch != null) {
      try {
        final jsonStr = newRagMatch.group(1)!;
        parsedSources = jsonDecode(jsonStr) as List<dynamic>;
        text = text.replaceFirst(newRagMatch.group(0)!, '').trim();
      } catch (e) {
        debugPrint('Error parsing new RAG sources JSON: $e');
      }
    } else {
      // 2. Fallback to legacy delimiter: [rag_sources:[...]]
      final oldRagMatch = RegExp(r'\[rag_sources:([\s\S]*?\])\]').firstMatch(text);
      if (oldRagMatch != null) {
        try {
          final jsonStr = oldRagMatch.group(1)!;
          parsedSources = jsonDecode(jsonStr) as List<dynamic>;
          text = text.replaceFirst(oldRagMatch.group(0)!, '').trim();
        } catch (e) {
          debugPrint('Error parsing legacy RAG sources JSON: $e');
        }
      }
    }

    final regExp = RegExp(r'\[interactive:([a-zA-Z0-9_-]+)\]');
    int lastMatchEnd = 0;
    final matches = regExp.allMatches(text);

    for (final match in matches) {
      // 1. Add preceding text segment if any
      if (match.start > lastMatchEnd) {
        final textSegment = text.substring(lastMatchEnd, match.start).trim();
        if (textSegment.isNotEmpty) {
          children.add(_buildMarkdownBlock(textSegment, context));
        }
      }

      // 2. Add interactive widget
      final widgetId = match.group(1);
      if (widgetId != null) {
        if (WidgetRegistry.hasWidget(widgetId)) {
          final interactiveWidget = WidgetRegistry.buildWidget(widgetId, context);
          children.add(interactiveWidget);
        } else {
          children.add(
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Interactive widget "$widgetId" not registered.',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }
      }

      lastMatchEnd = match.end;
    }

    // 3. Add remaining text segment if any
    if (lastMatchEnd < text.length) {
      final textSegment = text.substring(lastMatchEnd).trim();
      if (textSegment.isNotEmpty) {
        children.add(_buildMarkdownBlock(textSegment, context));
      }
    }

    // 4. Append RAG Sources indicator if sources were present
    if (parsedSources.isNotEmpty) {
      children.add(RAGSourcesWidget(sources: parsedSources));
    }

    return children;
  }

  Widget _buildMarkdownBlock(String markdownText, BuildContext context) {
    return MarkdownBody(
      data: markdownText,
      selectable: true,
      builders: {
        'pre': CodeBlockBuilder(context),
      },
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: const TextStyle(
          color: Color(0xFFE4E4E7),
          fontSize: 16,
          height: 1.7,
        ),
        code: const TextStyle(
          backgroundColor: Color(0xFF2A2A2A),
          color: Color(0xFFF43F5E),
          fontFamily: 'monospace',
          fontSize: 14,
        ),
        h1: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        h2: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        h3: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        listBullet: const TextStyle(
          color: Color(0xFFE4E4E7),
        ),
        tableBody: const TextStyle(
          color: Color(0xFFE4E4E7),
        ),
        tableHead: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;
    const showActions = true;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) {
        final fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut).value;
        final slide = Tween(begin: 14.0, end: 0.0)
            .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic)).value;
        return Opacity(
          opacity: fade,
          child: Transform.translate(offset: Offset(0, slide), child: child),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.only(left: 48, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextField(
                        controller: _editController,
                        maxLines: null,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF171717),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2B2B2B)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF10A37F)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                _editController.text = widget.message.text;
                              });
                            },
                            child: const Text('Cancel', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10A37F),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            onPressed: () {
                              final text = _editController.text.trim();
                              if (text.isNotEmpty) {
                                widget.onEdit!(text);
                              }
                              setState(() {
                                _isEditing = false;
                              });
                            },
                            child: const Text('Save & Submit', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                Row(
                  mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: isUser 
                                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                                : const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            margin: EdgeInsets.only(
                              left: isUser ? 64 : 0,
                              right: isUser ? 0 : 0, // full width for AI widgets
                            ),
                            decoration: BoxDecoration(
                              color: isUser ? const Color(0xFF202020) : Colors.transparent,
                              borderRadius: const BorderRadius.all(Radius.circular(18)),
                            ),
                            child: _buildMessageContent(isUser),
                          ),

                          if (isUser && widget.onEdit != null && showActions)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, right: 4),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isEditing = true;
                                  });
                                },
                                child: const MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit_outlined, size: 12, color: Color(0xFFA1A1AA)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Edit',
                                        style: TextStyle(
                                          color: Color(0xFFA1A1AA),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              if (!isUser && !_isEditing)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _actionIcon(Icons.copy_rounded, 'Copy Message', _copyMessage),
                      const SizedBox(width: 8),
                      if (widget.onRegenerate != null) ...[
                        _actionIcon(Icons.refresh_rounded, 'Regenerate Response', widget.onRegenerate!),
                        const SizedBox(width: 8),
                      ],
                      _actionIcon(
                        _isLiked == true ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                        'Like',
                        _likeMessage,
                        color: _isLiked == true ? const Color(0xFF10A37F) : null,
                      ),
                      const SizedBox(width: 8),
                      _actionIcon(
                        _isLiked == false ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
                        'Dislike',
                        _dislikeMessage,
                        color: _isLiked == false ? const Color(0xFFEF4444) : null,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CodeBlockBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  CodeBlockBuilder(this.context);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final codeText = element.textContent.trimRight();
    String language = 'code';
    if (element.attributes.containsKey('class')) {
      final className = element.attributes['class'] ?? '';
      if (className.startsWith('language-')) {
        language = className.substring(9);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2B2B2B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFA1A1AA),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: codeText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Code copied to clipboard!'),
                        backgroundColor: const Color(0xFF171717),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.copy_rounded, color: Color(0xFFA1A1AA), size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Copy code',
                        style: TextStyle(
                          color: Color(0xFFA1A1AA),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                codeText,
                style: GoogleFonts.firaCode(
                  color: const Color(0xFFE2E8F0),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RAGSourcesWidget extends StatefulWidget {
  final List<dynamic> sources;
  const RAGSourcesWidget({super.key, required this.sources});

  @override
  State<RAGSourcesWidget> createState() => _RAGSourcesWidgetState();
}

class _RAGSourcesWidgetState extends State<RAGSourcesWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.sources.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFF818CF8), size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '📚 Textbook Verified',
                            style: TextStyle(
                              color: Color(0xFF818CF8),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${widget.sources.length} Source${widget.sources.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Cited from your uploaded learning materials',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF818CF8),
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const SizedBox(height: 10),
            const Divider(color: Color(0xFF2E313D), height: 1),
            const SizedBox(height: 10),
            ...widget.sources.map((src) {
              final title = src['title'] ?? 'Textbook';
              final page = src['page'] ?? 1;
              final score = src['score'] ?? 0;
              final snippet = src['snippet'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF17181F),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2E313D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '📖 $title (Page $page)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$score% Match',
                          style: const TextStyle(
                            color: Color(0xFF60A5FA),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (snippet.toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '"$snippet"',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}
