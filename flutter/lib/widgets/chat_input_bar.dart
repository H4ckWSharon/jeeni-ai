import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

// ═══════════════════════════════════════════════════
// CHAT INPUT PANEL — with Voice, File & Model support
// ═══════════════════════════════════════════════════

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function(String, {List<XFile> attachments}) onSend;
  final bool isTyping;
  final String selectedModel;
  final VoidCallback onModelTap;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.isTyping,
    this.selectedModel = 'Guided Learning',
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

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  void _onText() {
    final has = widget.controller.text.trim().isNotEmpty || _attachments.isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _speech.stop();
    super.dispose();
  }

  void _send() {
    if (widget.isTyping) return;
    final t = widget.controller.text.trim();
    if (t.isNotEmpty || _attachments.isNotEmpty) {
      HapticFeedback.lightImpact();
      final attachmentsCopy = List<XFile>.from(_attachments);
      setState(() {
        _attachments.clear();
        _hasText = false;
      });
      widget.onSend(t, attachments: attachmentsCopy);
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
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(2))),
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
                      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg'],
                    );
                    if (result != null) {
                      final xfiles = result.files
                          .where((f) => kIsWeb ? f.bytes != null : f.path != null)
                          .map((f) => kIsWeb
                              ? XFile.fromData(f.bytes!, name: f.name, mimeType: 'image/${f.extension ?? 'jpeg'}')
                              : XFile(f.path!))
                          .toList();
                      setState(() {
                        _attachments.addAll(xfiles);
                        _hasText = true;
                      });
                    }
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

  @override
  Widget build(BuildContext context) {
    final bot = MediaQuery.of(context).viewInsets.bottom;
    final safeBot = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, bot > 0 ? 12 : safeBot + 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF2B2B2B), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Attachment Thumbnails ──
          if (_attachments.isNotEmpty) _AttachmentPreviewRow(
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
                    color: _isListening ? Colors.red.withOpacity(0.3) : Colors.transparent,
                  ),
                  child: Icon(
                    _isListening ? Icons.graphic_eq_rounded : Icons.auto_awesome,
                    size: 20,
                    color: _isListening ? Colors.red : Colors.white.withOpacity(0.5),
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
                      filled: true, fillColor: Colors.transparent, isDense: true,
                      hintText: _isListening ? 'Listening...' : 'Message Jeeni...',
                      hintStyle: GoogleFonts.inter(color: _isListening ? Colors.red : const Color(0xFFA1A1AA), fontSize: 16, fontWeight: FontWeight.w400),
                      border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
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
                _ModelPill(selectedModel: widget.selectedModel, onTap: widget.onModelTap),
                const Spacer(),
                _VoiceBtn(isListening: _isListening, onTap: _toggleVoice),
              ],
            ),
          ),
        ],
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
                    color: Colors.white.withOpacity(0.07),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
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
          color: isListening ? Colors.red.withOpacity(0.2) : Colors.transparent,
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
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.12), border: Border.all(color: color.withOpacity(0.25))),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
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
// MODEL PILL
// ═══════════════════════════════════════════════════

class _ModelPill extends StatefulWidget {
  final String selectedModel;
  final VoidCallback onTap;
  const _ModelPill({required this.selectedModel, required this.onTap});

  @override
  State<_ModelPill> createState() => _ModelPillState();
}

class _ModelPillState extends State<_ModelPill> {
  bool _pressed = false;

  IconData _getIconForModel(String model) {
    switch (model) {
      case 'Guided Learning': return Icons.school_outlined;
      case 'Deep Research': return Icons.biotech_outlined;
      case 'Web Search': return Icons.travel_explore_rounded;
      case 'Homework': return Icons.menu_book_rounded;
      default: return Icons.psychology_outlined;
    }
  }

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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: const Color(0xFF2B2B2B), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getIconForModel(widget.selectedModel), size: 18, color: const Color(0xFFA1A1AA)),
              const SizedBox(width: 8),
              Text(widget.selectedModel, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFFA1A1AA)),
            ],
          ),
        ),
      ),
    );
  }
}
