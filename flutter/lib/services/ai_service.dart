import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/chat_message.dart';
import '../models/student_profile.dart';

class AIService {
  /// The default URL of your Jeeni backend server.
  static const _defaultServerUrl = 'http://213.133.97.141:3000';

  /// Resolves the backend URL dynamically on Web to prevent CORS or Mixed Content issues.
  static String get serverUrl {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && origin.startsWith('http') && !origin.contains('localhost')) {
        return origin;
      }
    }
    return _defaultServerUrl;
  }

  /// Intercepts specific local system-related questions without calling the API
  static String? getLocalSystemResponse(String query) {
    final q = query.trim().toLowerCase();

    // 1. Greetings
    if (q == 'hi' || q == 'hello' || q == 'hey' || q == 'hello jeeni' || q == 'hi jeeni') {
      return "Hello! I am **Jeeni**, your personal AI teacher and study companion. 🎓✨\n\nHow can I help you learn something amazing today?";
    }

    // 2. Identity / Name
    if (q.contains('who are you') || q.contains('what is jeeni') || q.contains('your name') || q == 'jeeni') {
      return "I am **Jeeni**, your interactive AI educational companion! 🪐\n\nMy goal is to make learning simple, engaging, and tailored just for you. Whether you need help solving complex equations, doing deep research, preparing for homework, or exploring new topics, I've got your back! 🚀";
    }

    // 3. Private Session / Temp Chat
    if (q.contains('private session') || q.contains('temp chat') || q.contains('temporary chat') || q.contains('incognito')) {
      return "You are currently exploring **Jeeni's Private Session** (Temporary Mode)! 🕵️‍♂️🔒\n\n**Here is how it works:**\n- 🤐 **Complete Privacy**: None of your messages are saved to the cloud or Firestore.\n- ⏳ **Ephemeral**: The moment you close or exit this session, the chat history vanishes forever.\n- 🛡️ **Safe Space**: Perfect for asking quick, private questions without cluttering your main dashboard.\n\nTo save conversations permanently, you can easily tap **\"Login to Sync\"** and switch back to the Main Chat!";
    }

    return null;
  }

  // ═══════════════════════════════════════════════════
  // STUDENT PROFILE & MEMORY BACKEND SYNC (Phase 3, 5, 8)
  // ═══════════════════════════════════════════════════

  /// Synchronizes student profile to the backend server
  static Future<bool> syncStudentProfile(String studentId, StudentProfile profile) async {
    try {
      final res = await http.post(
        Uri.parse('$serverUrl/api/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': studentId,
          ...profile.toMap(),
        }),
      ).timeout(const Duration(seconds: 15));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[AIService] Profile backend sync warning: $e');
      return false;
    }
  }

  /// Adds an explicit memory to the backend server
  static Future<bool> syncMemory(String studentId, {required String content, String category = 'Learning Preference'}) async {
    try {
      final res = await http.post(
        Uri.parse('$serverUrl/api/memories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': studentId,
          'category': category,
          'content': content,
          'source': 'explicit_app',
        }),
      ).timeout(const Duration(seconds: 15));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[AIService] Memory sync warning: $e');
      return false;
    }
  }

  /// Deletes a memory on the backend server
  static Future<bool> deleteBackendMemory(String studentId, String memoryId) async {
    try {
      final res = await http.delete(
        Uri.parse('$serverUrl/api/memories/$memoryId?student_id=$studentId'),
      ).timeout(const Duration(seconds: 15));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Clears all memories on the backend server
  static Future<bool> clearBackendMemories(String studentId) async {
    try {
      final res = await http.delete(
        Uri.parse('$serverUrl/api/memories?student_id=$studentId'),
      ).timeout(const Duration(seconds: 15));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Toggles personalization setting on the backend server
  static Future<bool> toggleBackendPersonalization(String studentId, bool enabled) async {
    try {
      final res = await http.patch(
        Uri.parse('$serverUrl/api/profile/personalization'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': studentId,
          'enabled': enabled,
        }),
      ).timeout(const Duration(seconds: 15));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static (String model, String systemPrompt) _getModelAndPrompt(String mode) {
    const preamble = """
You are Jeeni (developed based on EduMind specifications), an advanced AI learning companion designed to maximize student understanding, retention, confidence, and academic growth. 
Your primary objective is not merely to answer questions but to build a dynamic mental model of each student and continuously adapt your teaching strategy.
Always respond in a beautiful, structured, and premium formatting using markdown, bullet points, bold headers, and supportive emojis where appropriate. Always identify as 'Jeeni'.

Core Responsibilities:
1. Student Understanding Model:
   - Maintain an evolving profile of the student's knowledge, strengths, weaknesses, misconceptions, learning style, confidence level, and academic goals.
   - Infer probable knowledge gaps from patterns in mistakes and questions.
   - Continuously update your understanding after every interaction.
2. Personalized Teaching:
   - Adjust explanations based on the student's age, background knowledge, learning speed, and preferences.
   - Use analogies, stories, diagrams, real-world examples, and step-by-step reasoning when appropriate.
   - Never provide explanations that are unnecessarily advanced.
3. Misconception Detection:
   - Identify hidden misunderstandings even when the student asks a different question.
   - Trace mistakes back to prerequisite concepts.
   - Explain why the mistake occurred and how to avoid it.
4. Learning Analytics:
   - Estimate mastery levels for topics.
   - Detect recurring weaknesses.
   - Predict future difficulties based on current performance.
   - Recommend personalized revision plans.
5. Socratic Guidance:
   - Prefer guiding students toward discoveries rather than immediately revealing answers.
   - Ask strategic questions that uncover reasoning.
   - Encourage critical thinking and self-reflection.
6. Confidence Awareness:
   - Detect frustration, confusion, boredom, overconfidence, anxiety, or disengagement from conversation patterns.
   - Adapt teaching style accordingly.
   - Provide encouragement based on evidence of progress.
7. Memory Integration:
   - Remember relevant past interactions, mistakes, achievements, goals, and learning preferences.
   - Use previous learning history to personalize future responses.
8. Adaptive Difficulty:
   - Continuously estimate the student's current ability level.
   - Increase challenge when mastery is demonstrated.
   - Simplify explanations when confusion is detected.
9. Deep Reasoning (Before responding):
   - Analyze what the student explicitly asked.
   - Infer what they may actually need.
   - Identify prerequisite concepts.
   - Estimate confidence and understanding level.
   - Choose the teaching strategy most likely to maximize learning.
10. Response Framework (For every educational response):
    - Assess understanding.
    - Explain clearly.
    - Verify comprehension.
    - Provide examples.
    - Offer practice questions.
    - Recommend next learning steps.
11. Ethical Constraints:
    - Never claim to read minds.
    - Never invent student information.
    - Clearly distinguish observations from predictions.
    - Base all inferences on evidence from student interactions.

Success Metric:
Your success is measured not by how many answers you provide, but by how much the student genuinely understands, retains, and can independently apply the knowledge.
""";

    String systemInstruction = '';
    String model = 'gemini-3.1-flash-lite';

    switch (mode) {
      case 'Deep Research':
        systemInstruction = '$preamble '
            'You are a highly analytical deep researcher. Provide comprehensive, '
            'fact-based answers with structure and simulated citations with author, '
            'journal, and year. Use a formal, academic tone. Always include a '
            'Summary, Key Findings, and Further Reading section.';
        model = 'gemini-3.1-flash-lite';
        break;
      case 'Web Search':
        systemInstruction = '$preamble '
            'You are Jeeni Web Search Engine powered by live Google Search Grounding. '
            'Provide accurate, up-to-date, real-time facts and search results retrieved from the web. '
            'Summarize the findings clearly with bullet points, dates, and explanations.';
        model = 'gemini-3.1-flash-lite';
        break;
      case 'Homework':
        systemInstruction = '$preamble '
            'You are a patient homework tutor. Your role is to NEVER give the direct '
            'answer. Instead: (1) Ask what the student has tried so far. (2) Give a '
            'relevant hint or principle. (3) Break the problem into smaller steps. '
            '(4) Encourage the student to attempt each step themselves. Only confirm '
            'correct reasoning — never complete the work for them.';
        model = 'gemini-3.1-flash-lite';
        break;
      case 'Exam Prep':
        systemInstruction = '$preamble '
            'You are a Socratic Exam Coach. Your job is to QUIZ the student, not explain. '
            'Rules: '
            '1. When the student gives you a topic (e.g. "Photosynthesis"), immediately generate ONE practice question about it — MCQ, short answer, or fill-in-the-blank. '
            '2. Wait for the student to answer before asking the next question. '
            '3. After each answer: evaluate it (Correct / Partially correct / Incorrect), explain why briefly, then give the NEXT question. '
            '4. Keep a running score (e.g. "Score: 3/5"). '
            '5. After 5 questions, give a performance summary and recommend weak areas to review. '
            '6. NEVER just explain a topic without asking a question first. '
            'Start by asking: "What topic would you like to be quizzed on today? 📝"';
        model = 'gemini-3.1-flash-lite';
        break;
      case 'Guided Learning':
      default:
        systemInstruction = '$preamble '
            'You are a friendly, step-by-step educational AI. Break down complex topics '
            'into simple, easy-to-understand explanations with emojis. Always end your '
            'response with a quick comprehension check question.';
        model = 'gemini-3.1-flash-lite';
        break;
    }

    return (model, systemInstruction);
  }

  static Future<String> generateResponse({
    required String prompt,
    required String mode,
    required List<ChatMessage> history,
    List<XFile> attachments = const [],
    String? studentId,
    StudentProfile? profile,
  }) async {
    try {
      // Intercept local system-related responses first
      if (attachments.isEmpty) {
        final localResponse = getLocalSystemResponse(prompt);
        if (localResponse != null) {
          return localResponse;
        }
      }

      final (model, systemInstruction) = _getModelAndPrompt(mode);

      // Build messages array for our server
      final List<Map<String, dynamic>> messages = [];

      // System prompt
      if (systemInstruction.isNotEmpty) {
        messages.add({
          'role': 'system',
          'content': systemInstruction,
        });
      }

      // Chat history
      for (var msg in history) {
        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.text,
        });
      }

      // ── STAGE 1: Build prompt — if no text, use vision instruction ──
      final effectivePrompt = prompt.isNotEmpty
          ? prompt
          : 'Carefully examine and explain exactly what is shown in this image in detail. Describe every element, diagram, chart, text, equation, or drawing you can see.';

      if (attachments.isEmpty) {
        messages.add({'role': 'user', 'content': effectivePrompt});
      } else {
        // ── STAGE 2: Build multipart content (text + image bytes) ──
        final List<Map<String, dynamic>> contentParts = [
          {'type': 'text', 'text': effectivePrompt},
        ];

        for (var xfile in attachments) {
          final name = xfile.name.toLowerCase();
          final ext = name.contains('.') ? name.split('.').last : '';

          // ── Determine if file is an image or a document ──
          const imageExts = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp', 'heic'];
          const textExts  = ['txt', 'md', 'csv', 'json', 'xml', 'log'];
          final isImage = imageExts.contains(ext);
          final isText  = textExts.contains(ext);

          if (isImage) {
            // ── Image → encode as base64 inline data ──
            final bytes = await xfile.readAsBytes();
            if (bytes.isEmpty) {
              debugPrint('[Vision] WARNING: Empty image bytes for ${xfile.name}');
              continue;
            }
            String mimeType = 'image/jpeg';
            if (ext == 'png')  mimeType = 'image/png';
            if (ext == 'webp') mimeType = 'image/webp';
            if (ext == 'gif')  mimeType = 'image/gif';
            if (ext == 'bmp')  mimeType = 'image/bmp';
            debugPrint('[Vision] Attaching image: ${xfile.name} | MIME: $mimeType | Size: ${(bytes.length / 1024).toStringAsFixed(1)}KB');
            contentParts.add({
              'type': 'image_url',
              'image_url': {'url': 'data:$mimeType;base64,${base64Encode(bytes)}'},
            });
          } else if (isText) {
            // ── Plain text file → read content and inject as text ──
            final bytes = await xfile.readAsBytes();
            final textContent = String.fromCharCodes(bytes);
            debugPrint('[Vision] Attaching text file: ${xfile.name} (${textContent.length} chars)');
            contentParts.add({
              'type': 'text',
              'text': '--- File: ${xfile.name} ---\n$textContent\n--- End of file ---',
            });
          } else {
            // ── PDF / DOC / DOCX / other binary ── cannot be processed as image
            debugPrint('[Vision] Unsupported file type: ${xfile.name} ($ext) — sending as note');
            contentParts.add({
              'type': 'text',
              'text': '📎 The student attached a file named "${xfile.name}" (.$ext). '
                  'Unfortunately, PDF and Word document parsing is not yet supported for direct analysis. '
                  'Please ask the student to paste the relevant text content directly into the chat, '
                  'or describe what the document is about so you can help them.',
            });
          }
        }

        messages.add({'role': 'user', 'content': contentParts});
        debugPrint('[Vision] Sending ${attachments.length} image(s) + text to server');
      }

      // ── STAGE 3: Send to Jeeni backend (Vision, Web Search, or Text pipeline) ──
      debugPrint('[Vision] POST /api/chat | Mode: $mode | Has images: ${attachments.isNotEmpty} | Prompt: "${effectivePrompt.length > 60 ? effectivePrompt.substring(0, 60) : effectivePrompt}..."');

      final response = await http
          .post(
            Uri.parse('$serverUrl/api/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'mode': mode,
              'webSearch': mode == 'Web Search',
              'enableRag': true, // Always enforce RAG — never allow Gemini to hallucinate textbook answers
              'messages': messages,
              if (studentId != null) 'student_id': studentId,
              if (profile != null) 'profile': profile.toMap(),
            }),
          )
          .timeout(const Duration(seconds: 120));

      // ── STAGE 4: Handle response ──────────────────────────────────
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rawText = (data['content'] as String?) ?? 'Sorry, I could not generate a response.';
        final sources = (data['sources'] as List?) ?? [];
        final pipeline = (data['pipeline'] as String?) ?? 'TEXT_ONLY';

        debugPrint('[Vision] Response received | Pipeline: $pipeline | Length: ${rawText.length} chars');

        // Interactive widgets turned off — return clean plain text response
        String resultText = rawText.replaceAll(RegExp(r'\[interactive:[a-zA-Z0-9_-]+\]'), '').trim();

        if (sources.isNotEmpty) {
          final sourcesJson = jsonEncode(sources);
          resultText = '$resultText\n\n<<<RAG_SOURCES_START>>>$sourcesJson<<<RAG_SOURCES_END>>>';
        }
        return resultText;
      } else {
        debugPrint('[Vision] Server error ${response.statusCode}: ${response.body}');
        // Return specific message for image failures vs text failures
        if (attachments.isNotEmpty) {
          return '🔴 **Jeeni Vision could not analyze the image.**\n\nThe server returned an error (${response.statusCode}). This may be because:\n- The image file is too large (try under 4MB)\n- The image format is not supported\n- The server is temporarily overloaded\n\nPlease try again or upload a different image.';
        }
        return _getMockFallbackResponse(prompt);
      }
    } catch (e) {
      debugPrint('[Vision] AI Service Error: $e');
      if (attachments.isNotEmpty) {
        return '🔴 **Jeeni Vision Error**\n\nFailed to analyze the image: $e\n\nPlease try again. If the image is large, try resizing it first.';
      }
      return _getMockFallbackResponse(prompt);
    }
  }


  static String _getMockFallbackResponse(String prompt) {
    // Honest, user-friendly connection error — never hallucinate mock answers
    return """🔄 **Jeeni couldn't reach the server right now.**

This may be due to:
- A temporary network interruption
- The request taking longer than expected
- The server undergoing a quick update

**Please tap retry or ask again in a moment.**

> Your question was: *"$prompt"*""";
  }
}
