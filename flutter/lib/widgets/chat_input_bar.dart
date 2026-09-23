import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../models/jeeni_mode.dart';

// ═══════════════════════════════════════════════════
// CHAT INPUT PANEL — with @ Jeeni Mode Selector, Voice & Attachments
// ═══════════════════════════════════════════════════

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function(String, {List<XFile> attachments, JeeniMode? mode}) onSend;
  final bool isTyping;
  final JeeniMode selectedMode;
  final ValueChanged<JeeniMode>? onModeChanged;
  final VoidCallback onModelTap;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.isTyping,
    this.selectedMode = JeeniMode.learning,
    this.onModeChanged,
    required this.onModelTap,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasText = false;
  final List<XFile> _attachments = [];
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  // ── @ Jeeni Mode State ──
  JeeniMode? _activeModeOverride;
  bool _showModePopup = false;
  String _modeQuery = '';
  int _highlightedIndex = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  void _onText() {
    final text = widget.controller.text;
    final sel = widget.controller.selection;
    final cursorPos = sel.baseOffset >= 0 ? sel.baseOffset : text.length;

    // Detect if cursor is on an active '@' query
    final textBeforeCursor = text.substring(0, cursorPos.clamp(0, text.length));
    final atIndex = textBeforeCursor.lastIndexOf('@');

    if (atIndex != -1) {
      final isWordStart = atIndex == 0 || textBeforeCursor[atIndex - 1].trim().isEmpty;
      final query = textBeforeCursor.substring(atIndex + 1);

      if (isWordStart && !query.contains(' ') && !query.contains('\n')) {
        final filtered = JeeniMode.filter(query);
        setState(() {
          _showModePopup = true;
          _modeQuery = query;
          if (_highlightedIndex >= filtered.length) {
            _highlightedIndex = 0;
          }
        });
      } else {
        if (_showModePopup) setState(() => _showModePopup = false);
      }
    } else {
      if (_showModePopup) setState(() => _showModePopup = false);
    }

    final has = text.trim().isNotEmpty || _attachments.isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!_showModePopup) return KeyEventResult.ignored;

    final filtered = JeeniMode.filter(_modeQuery);
    if (filtered.isEmpty) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _highlightedIndex = (_highlightedIndex + 1) % filtered.length;
        });
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _highlightedIndex = (_highlightedIndex - 1 + filtered.length) % filtered.length;
        });
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.tab) {
        if (_highlightedIndex >= 0 && _highlightedIndex < filtered.length) {
          _selectMode(filtered[_highlightedIndex]);
          return KeyEventResult.handled;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() => _showModePopup = false);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _selectMode(JeeniMode mode) {
    HapticFeedback.lightImpact();
    final text = widget.controller.text;
    final sel = widget.controller.selection;
    final cursorPos = sel.baseOffset >= 0 ? sel.baseOffset : text.length;
    final textBeforeCursor = text.substring(0, cursorPos.clamp(0, text.length));
    final atIndex = textBeforeCursor.lastIndexOf('@');

    String newText = text;
    int newCursor = cursorPos;

    if (atIndex != -1) {
      final beforeAt = text.substring(0, atIndex);
      final afterCursor = text.substring(cursorPos.clamp(0, text.length));
      newText = (beforeAt + afterCursor).trimLeft();
      newCursor = beforeAt.length;
    }

    setState(() {
      _activeModeOverride = mode;
      _showModePopup = false;
      _modeQuery = '';
      _highlightedIndex = 0;
    });

    widget.onModeChanged?.call(mode);

    widget.controller.text = newText;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: newCursor.clamp(0, newText.length)),
    );
    _focusNode.requestFocus();
    _onText();
  }

  void _clearModeOverride() {
    HapticFeedback.lightImpact();
    setState(() {
      _activeModeOverride = null;
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focusNode.dispose();
    _speech.stop();
    super.dispose();
  }

  void _send() {
    if (widget.isTyping) return;
    final t = widget.controller.text.trim();
    if (t.isNotEmpty || _attachments.isNotEmpty) {
      HapticFeedback.lightImpact();
      final attachmentsCopy = List<XFile>.from(_attachments);
      final effectiveMode = _activeModeOverride ?? widget.selectedMode;
      setState(() {
        _attachments.clear();
        _hasText = false;
        _showModePopup = false;
        _activeModeOverride = null; // Reset per-message override after send
      });
      widget.onSend(t, attachments: attachmentsCopy, mode: effectiveMode);
    }
  }

  // ── File / Image Picker ──
  Future<void> _showAttachmentSheet() async {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.only(top: 12, bottom: 32, left: 20, right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Add Attachment', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: Colors.blue,
                  onTap: () async {
                    Navigator.pop(context);
                    final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
                    if (img != null) setState(() { _attachments.add(img); _hasText = true; });
                  },
                ),
                _AttachOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: Colors.green,
                  onTap: () async {
                    Navigator.pop(context);
                    final img = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
                    if (img != null) setState(() { _attachments.add(img); _hasText = true; });
                  },
                ),
                _AttachOption(
                  icon: Icons.insert_drive_file_rounded,
                  label: 'File',
                  color: Colors.orange,
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await fp.FilePicker.pickFiles(
                      allowMultiple: true,
                      type: fp.FileType.custom,
                      allowedExtensions: ['txt', 'md', 'csv', 'png', 'jpg', 'jpeg', 'webp'],
                    );
                    if (result != null) {
                      final xfiles = result.files
                          .where((f) => kIsWeb ? f.bytes != null : f.path != null)
                          .map((f) => kIsWeb
                              ? XFile.fromData(f.bytes!, name: f.name)
                              : XFile(f.path!))
                          .toList();
                      setState(() {
                        _attachments.addAll(xfiles);
                        _hasText = true;
                      });
                    }
                  },
                ),
                _AttachOption(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'PDF Soon',
                  color: Colors.red.withValues(alpha: 0.5),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('📄 PDF analysis coming soon! For now, paste the text content directly into the chat.'),
                        backgroundColor: const Color(0xFF171717),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Voice to Text ──
  Future<void> _toggleVoice() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎤 Voice input works best in Chrome. Tap the mic and speak.'),
          backgroundColor: const Color(0xFF171717),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
      final available = await _speech.initialize(
        onStatus: (s) { if (s == 'done' || s == 'notListening') setState(() => _isListening = false); },
        onError: (e) => setState(() => _isListening = false),
      );
      if (!available) return;
      setState(() => _isListening = true);
      HapticFeedback.mediumImpact();
      _speech.listen(
        onResult: (val) {
          widget.controller.text = val.recognizedWords;
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller.text.length),
          );
          _onText();
        },
        listenOptions: stt.SpeechListenOptions(cancelOnError: true),
      );
      return;
    }

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required.'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    final available = await _speech.initialize(
      onStatus: (s) { if (s == 'done' || s == 'notListening') setState(() => _isListening = false); },
      onError: (e) => setState(() => _isListening = false),
    );
    if (!available) return;

    setState(() => _isListening = true);
    HapticFeedback.mediumImpact();
    _speech.listen(
      onResult: (val) {
        widget.controller.text = val.recognizedWords;
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.controller.text.length),
        );
        _onText();
      },
      listenOptions: stt.SpeechListenOptions(cancelOnError: true),
    );
  }

  Widget _buildModePopup(List<JeeniMode> modes) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF333333), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFF262626), width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alternate_email_rounded, size: 14, color: Color(0xFFA1A1AA)),
                  const SizedBox(width: 6),
                  Text(
                    'Jeeni Modes',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFA1A1AA),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Select a mode',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF71717A),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: modes.length,
                itemBuilder: (context, i) {
                  final mode = modes[i];
                  final isHighlighted = i == _highlightedIndex;
                  return InkWell(
                    onTap: () => _selectMode(mode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      color: isHighlighted
                          ? mode.color.withValues(alpha: 0.16)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: mode.color.withValues(alpha: 0.15),
                              border: Border.all(
                                color: mode.color.withValues(alpha: isHighlighted ? 0.6 : 0.25),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              mode.emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  mode.label,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  mode.description,
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFFA1A1AA),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isHighlighted)
                            Icon(
                              Icons.keyboard_return_rounded,
                              size: 14,
                              color: mode.color,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveModeChip(JeeniMode mode) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: mode.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: mode.color.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(mode.emoji, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Text(
                  mode.label,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _clearModeOverride,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).viewInsets.bottom;
    final safeBot = MediaQuery.of(context).padding.bottom;
    final filteredModes = JeeniMode.filter(_modeQuery);
    final effectiveMode = _activeModeOverride ?? widget.selectedMode;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        margin: EdgeInsets.fromLTRB(16, 0, 16, bot > 0 ? 12 : safeBot + 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Floating @ Mode Selector Popup ──
            if (_showModePopup && filteredModes.isNotEmpty)
              _buildModePopup(filteredModes),

            // ── Main Composer Container ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF2B2B2B), width: 1.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Active Mode Chip (when selected) ──
                  if (_activeModeOverride != null)
                    _buildActiveModeChip(_activeModeOverride!),

                  // ── Attachment Thumbnails ──
                  if (_attachments.isNotEmpty)
                    _AttachmentPreviewRow(
                      attachments: _attachments,
                      onRemove: (i) => setState(() { _attachments.removeAt(i); _onText(); }),
                    ),

                  // ── MAIN INPUT ROW ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Voice status orb
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening ? Colors.red.withValues(alpha: 0.3) : Colors.transparent,
                          ),
                          child: Icon(
                            _isListening ? Icons.graphic_eq_rounded : Icons.auto_awesome,
                            size: 20,
                            color: _isListening ? Colors.red : Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Text Field
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: TextField(
                            controller: widget.controller,
                            maxLines: 5,
                            minLines: 1,
                            cursorColor: const Color(0xFF10A37F),
                            cursorWidth: 1.5,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400, height: 1.7),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.transparent,
                              isDense: true,
                              hintText: _isListening
                                  ? 'Listening...'
                                  : (_activeModeOverride != null ? 'Ask Jeeni anything...' : 'Message Jeeni... (type @ for modes)'),
                              hintStyle: GoogleFonts.inter(
                                color: _isListening ? Colors.red : const Color(0xFFA1A1AA),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Send Button
                      _SendBtn(active: _hasText && !widget.isTyping, loading: widget.isTyping, onTap: _send),
                    ],
                  ),

                  // ── BOTTOM CONTROLS ──
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        _CtrlBtn(icon: Icons.add_rounded, onTap: _showAttachmentSheet),
                        const SizedBox(width: 8),
                        _ModePill(mode: effectiveMode, onTap: widget.onModelTap),
                        const Spacer(),
                        _VoiceBtn(isListening: _isListening, onTap: _toggleVoice),
                      ],
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
}

// ═══════════════════════════════════════════════════
// ATTACHMENT PREVIEW ROW
// ═══════════════════════════════════════════════════

class _AttachmentPreviewRow extends StatelessWidget {
  final List<XFile> attachments;
  final void Function(int) onRemove;
  const _AttachmentPreviewRow({required this.attachments, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: attachments.length,
        itemBuilder: (_, i) {
          final xfile = attachments[i];
          final ext = (xfile.name.split('.').last).toLowerCase();
          final isImage = ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withValues(alpha: 0.07),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isImage
                      ? FutureBuilder<Uint8List>(
                          future: xfile.readAsBytes(),
                          builder: (ctx, snap) {
                            if (snap.hasData) {
                              return Image.memory(snap.data!, fit: BoxFit.cover);
                            }
                            return const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)));
                          },
                        )
                      : const Icon(Icons.insert_drive_file_rounded, color: Colors.white54, size: 28),
                ),
                Positioned(
                  top: -2, right: -2,
                  child: GestureDetector(
                    onTap: () => onRemove(i),
                    child: Container(
                      width: 20, height: 20,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// VOICE BUTTON — animated mic
// ═══════════════════════════════════════════════════

class _VoiceBtn extends StatelessWidget {
  final bool isListening;
  final VoidCallback onTap;
  const _VoiceBtn({required this.isListening, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 42, height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isListening ? Colors.red.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: isListening ? Colors.red : const Color(0xFF2B2B2B),
            width: 1.2,
          ),
        ),
        child: Icon(
          isListening ? Icons.stop_rounded : Icons.mic_none_rounded,
          size: 22,
          color: isListening ? Colors.red : const Color(0xFFA1A1AA),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// ATTACH OPTION TILE
// ═══════════════════════════════════════════════════

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AttachOption({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.12), border: Border.all(color: color.withValues(alpha: 0.25))),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// SEND BUTTON
// ═══════════════════════════════════════════════════

class _SendBtn extends StatefulWidget {
  final bool active;
  final bool loading;
  final VoidCallback onTap;
  const _SendBtn({required this.active, required this.loading, required this.onTap});

  @override
  State<_SendBtn> createState() => _SendBtnState();
}

class _SendBtnState extends State<_SendBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.active ? Colors.white : const Color(0xFF222222),
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Transform.translate(
                    offset: const Offset(1, 0),
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Icon(Icons.send_rounded, size: 20,
                        color: widget.active ? Colors.black : const Color(0xFFA1A1AA)),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// CONTROL BUTTON — 42px circle
// ═══════════════════════════════════════════════════

class _CtrlBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CtrlBtn({required this.icon, required this.onTap});

  @override
  State<_CtrlBtn> createState() => _CtrlBtnState();
}

class _CtrlBtnState extends State<_CtrlBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(color: const Color(0xFF2B2B2B), width: 1.2),
          ),
          child: Icon(widget.icon, size: 22, color: const Color(0xFFA1A1AA)),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// MODE PILL — Displays current Jeeni Mode
// ═══════════════════════════════════════════════════

class _ModePill extends StatefulWidget {
  final JeeniMode mode;
  final VoidCallback onTap;
  const _ModePill({required this.mode, required this.onTap});

  @override
  State<_ModePill> createState() => _ModePillState();
}

class _ModePillState extends State<_ModePill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: const Color(0xFF2B2B2B), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.mode.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text(widget.mode.label, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFFA1A1AA)),
            ],
          ),
        ),
      ),
    );
  }
}
