// ═══════════════════════════════════════════════════
// JEENI — AUTHORITATIVE MESSAGE & ATTACHMENT MODEL
// ═══════════════════════════════════════════════════

/// A single file/image attachment on a chat message.
///
/// Supports persistence in Firestore (serialised via [toMap]/[fromMap])
/// and on-device display via [localPath] (cleared after the session).
class MessageAttachment {
  final String type;       // 'image' | 'text_file'
  final String name;       // Original filename
  final String mimeType;   // e.g. 'image/jpeg'
  final int sizeBytes;
  final String? localPath;
  final String? base64Data; // Base64 encoded image data for persistent cross-session & web rendering

  const MessageAttachment({
    required this.type,
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    this.localPath,
    this.base64Data,
  });

  Map<String, dynamic> toMap() => {
    'type': type,
    'name': name,
    'mimeType': mimeType,
    'sizeBytes': sizeBytes,
    if (localPath != null) 'localPath': localPath,
    if (base64Data != null) 'base64Data': base64Data,
  };

  factory MessageAttachment.fromMap(Map<String, dynamic> map) {
    return MessageAttachment(
      type: (map['type'] as String?) ?? 'image',
      name: (map['name'] as String?) ?? 'attachment',
      mimeType: (map['mimeType'] as String?) ?? 'image/jpeg',
      sizeBytes: (map['sizeBytes'] as int?) ?? 0,
      localPath: map['localPath'] as String?,
      base64Data: map['base64Data'] as String?,
    );
  }

  bool get isImage => type == 'image';
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  /// Structured attachment metadata — survives Firestore persistence.
  /// [MessageAttachment.localPath] is NOT persisted but IS populated
  /// immediately after sending so the current session can render the image.
  final List<MessageAttachment> attachments;

  final List<Map<String, dynamic>>? sources;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.attachments = const [],
    this.sources,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'attachments': attachments.map((a) => a.toMap()).toList(),
      'sources': sources ?? [],
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    // Safely parse attachments — handles both new structured format
    // and legacy List<String> format (plain strings are ignored gracefully)
    final rawAttachments = map['attachments'];
    final List<MessageAttachment> parsedAttachments = [];
    if (rawAttachments is List) {
      for (final item in rawAttachments) {
        if (item is Map<String, dynamic>) {
          parsedAttachments.add(MessageAttachment.fromMap(item));
        }
        // Legacy plain strings (old format) are silently dropped —
        // they were never rendered so no regression.
      }
    }

    return ChatMessage(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? true,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
          map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
      attachments: parsedAttachments,
      sources: map['sources'] != null
          ? List<Map<String, dynamic>>.from(
              (map['sources'] as List).map((x) => Map<String, dynamic>.from(x)))
          : null,
    );
  }
}
