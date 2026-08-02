class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? attachments;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.attachments,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'attachments': attachments ?? [],
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? true,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
      attachments: List<String>.from(map['attachments'] ?? []),
    );
  }
}
