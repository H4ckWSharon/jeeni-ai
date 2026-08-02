import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class DatabaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════
  // CHAT SESSIONS CRUD
  // ═══════════════════════════════════════════════════

  /// Creates a new chat session document in Firestore
  static Future<String> createChat(String userId, String firstMessageText) async {
    final chatRef = _db.collection('users').doc(userId).collection('chats').doc();
    final title = firstMessageText.length > 28 
        ? '${firstMessageText.substring(0, 28)}…' 
        : firstMessageText;

    // Classify category subject based on keywords
    final subject = _classifySubject(firstMessageText);

    await chatRef.set({
      'id': chatRef.id,
      'title': title,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      'isStarred': false,
      'isPinned': false,
      'projectId': null,
      'subject': subject,
      'category': 'Chats', // Legacy field support
      'lastMessage': firstMessageText,
    });

    return chatRef.id;
  }

  /// Fetches a stream of all chats for a given user, sorted by pinned state and lastUpdated descending
  static Stream<List<Map<String, dynamic>>> getChatsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('chats')
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs.map((doc) => doc.data()).toList();
          // Sort in-memory to avoid Firestore composite index errors
          chats.sort((a, b) {
            final aPinned = a['isPinned'] == true ? 1 : 0;
            final bPinned = b['isPinned'] == true ? 1 : 0;
            if (aPinned != bPinned) {
              return bPinned.compareTo(aPinned); // Pinned first
            }
            final aTime = a['lastUpdated'] ?? 0;
            final bTime = b['lastUpdated'] ?? 0;
            return bTime.compareTo(aTime); // Latest first
          });
          return chats;
        });
  }

  /// Star or unstar a specific chat session
  static Future<void> toggleStarChat(String userId, String chatId, bool isStarred) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(chatId)
        .update({'isStarred': isStarred});
  }

  /// Pin or unpin a specific chat session
  static Future<void> togglePinChat(String userId, String chatId, bool isPinned) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(chatId)
        .update({'isPinned': isPinned});
  }

  /// Rename a chat session
  static Future<void> renameChat(String userId, String chatId, String newTitle) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(chatId)
        .update({'title': newTitle});
  }

  /// Move a chat to a specific project (null = no project)
  static Future<void> moveChatToProject(String userId, String chatId, String? projectId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(chatId)
        .update({'projectId': projectId});
  }

  /// Duplicate a chat and all its messages
  static Future<String> duplicateChat(String userId, String chatId) async {
    final originalChatRef = _db.collection('users').doc(userId).collection('chats').doc(chatId);
    final originalSnap = await originalChatRef.get();
    if (!originalSnap.exists) {
      throw Exception('Original chat does not exist');
    }

    final data = originalSnap.data()!;
    final newChatRef = _db.collection('users').doc(userId).collection('chats').doc();

    // Create duplicated chat document
    await newChatRef.set({
      ...data,
      'id': newChatRef.id,
      'title': '${data['title'] ?? 'No Title'} (Copy)',
      'isPinned': false,
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    });

    // Copy nested messages
    final messagesSnap = await originalChatRef.collection('messages').get();
    final batch = _db.batch();
    for (var msgDoc in messagesSnap.docs) {
      final msgData = msgDoc.data();
      final newMsgRef = newChatRef.collection('messages').doc(msgDoc.id);
      batch.set(newMsgRef, msgData);
    }
    await batch.commit();

    return newChatRef.id;
  }

  /// Delete a chat session and all its nested messages
  static Future<void> deleteChat(String userId, String chatId) async {
    final chatDocRef = _db.collection('users').doc(userId).collection('chats').doc(chatId);

    // Delete subcollection 'messages' documents first
    final messagesSnapshot = await chatDocRef.collection('messages').get();
    final batch = _db.batch();
    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete the chat document itself
    batch.delete(chatDocRef);
    await batch.commit();
  }

  // ═══════════════════════════════════════════════════
  // PROJECTS CRUD
  // ═══════════════════════════════════════════════════

  /// Creates a new project document in Firestore
  static Future<String> createProject(String userId, String projectName) async {
    final projectRef = _db.collection('users').doc(userId).collection('projects').doc();
    await projectRef.set({
      'id': projectRef.id,
      'name': projectName,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    return projectRef.id;
  }

  /// Rename an existing project
  static Future<void> renameProject(String userId, String projectId, String newName) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('projects')
        .doc(projectId)
        .update({'name': newName});
  }

  /// Delete an existing project and reset all chats in it to no project
  static Future<void> deleteProject(String userId, String projectId) async {
    final projectDocRef = _db.collection('users').doc(userId).collection('projects').doc(projectId);

    // Set projectId of all matching chats to null
    final chatsRef = _db.collection('users').doc(userId).collection('chats');
    final querySnapshot = await chatsRef.where('projectId', isEqualTo: projectId).get();
    
    final batch = _db.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'projectId': null});
    }

    // Delete the project document
    batch.delete(projectDocRef);
    await batch.commit();
  }

  /// Fetches a stream of all projects for a given user, sorted by createdAt
  static Stream<List<Map<String, dynamic>>> getProjectsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('projects')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // ═══════════════════════════════════════════════════
  // MESSAGES CRUD
  // ═══════════════════════════════════════════════════

  /// Saves a message (user or AI response) inside the messages subcollection of the chat
  static Future<void> saveMessage(String userId, String chatId, ChatMessage message) async {
    final chatDocRef = _db.collection('users').doc(userId).collection('chats').doc(chatId);

    // Write message document
    await chatDocRef.collection('messages').doc(message.id).set(message.toMap());

    // Update lastUpdated timestamp and lastMessage on parent chat document
    await chatDocRef.update({
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      'lastMessage': message.text,
    });
  }

  /// Fetches a stream of messages for a given chat, sorted by timestamp ascending
  static Stream<List<ChatMessage>> getMessagesStream(String userId, String chatId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data()))
            .toList());
  }

  /// Deletes all messages in a chat that were sent after the given timestamp
  static Future<void> deleteMessagesAfter(String userId, String chatId, DateTime timestamp) async {
    final messagesRef = _db
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(chatId)
        .collection('messages');
    
    final querySnapshot = await messagesRef
        .where('timestamp', isGreaterThan: timestamp.millisecondsSinceEpoch)
        .get();
        
    final batch = _db.batch();
    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Helper classification methods
  static String _classifySubject(String text) {
    final lower = text.toLowerCase();
    
    if (lower.contains('code') || lower.contains('program') || lower.contains('python') || 
        lower.contains('java') || lower.contains('javascript') || lower.contains('c++') || 
        lower.contains('flutter') || lower.contains('dart') || lower.contains('html') || 
        lower.contains('css') || lower.contains('rust') || lower.contains('sql') ||
        lower.contains('write a function') || lower.contains('debugging') || lower.contains('bug')) {
      return 'Programming';
    }
    
    if (lower.contains('security') || lower.contains('hack') || lower.contains('cyber') || 
        lower.contains('firewall') || lower.contains('malware') || lower.contains('encryption') || 
        lower.contains('phish') || lower.contains('vulnerability') || lower.contains('exploit') ||
        lower.contains('penetration') || lower.contains('phishing') || lower.contains('trojan')) {
      return 'Cyber Security';
    }
    
    if (lower.contains('equation') || lower.contains('math') || lower.contains('algebra') || 
        lower.contains('calculus') || lower.contains('geometry') || lower.contains('solve') || 
        lower.contains('derivative') || lower.contains('integral') || lower.contains('fraction') ||
        lower.contains('arithmetic') || lower.contains('trigonometry') || lower.contains('matrix')) {
      return 'Mathematics';
    }
    
    if (lower.contains('physics') || lower.contains('gravity') || lower.contains('quantum') || 
        lower.contains('relativity') || lower.contains('force') || lower.contains('energy') || 
        lower.contains('thermodynamics') || lower.contains('velocity') || lower.contains('acceleration') ||
        lower.contains('optics') || lower.contains('astronomy')) {
      return 'Physics';
    }
    
    if (lower.contains('chemistry') || lower.contains('molecule') || lower.contains('reaction') || 
        lower.contains('periodic') || lower.contains('covalent') || lower.contains('ionic') || 
        lower.contains('atom') || lower.contains('acid') || lower.contains('base') ||
        lower.contains('ph ') || lower.contains('chemical') || lower.contains('organic')) {
      return 'Chemistry';
    }
    
    if (lower.contains('biology') || lower.contains('cell') || lower.contains('dna') || 
        lower.contains('rna') || lower.contains('evolution') || lower.contains('plant') || 
        lower.contains('photosynthesis') || lower.contains('anatomy') || lower.contains('species') ||
        lower.contains('genetics') || lower.contains('organism') || lower.contains('mitosis')) {
      return 'Biology';
    }
    
    if (lower.contains('grammar') || lower.contains('essay') || lower.contains('poem') || 
        lower.contains('sentence') || lower.contains('vocabulary') || lower.contains('literature') || 
        lower.contains('spelling') || lower.contains('english') || lower.contains('adjective') ||
        lower.contains('verb') || lower.contains('noun') || lower.contains('pronoun')) {
      return 'English';
    }
    
    if (lower.contains('history') || lower.contains('war') || lower.contains('empire') || 
        lower.contains('king') || lower.contains('queen') || lower.contains('revolution') || 
        lower.contains('ancient') || lower.contains('century') || lower.contains('timeline') ||
        lower.contains('dynasty') || lower.contains('civilization')) {
      return 'History';
    }
    
    return 'General';
  }
}
