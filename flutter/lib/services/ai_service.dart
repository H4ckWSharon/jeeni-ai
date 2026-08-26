import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/chat_message.dart';

class AIService {
  /// The URL of your Jeeni backend server.
  /// All OpenAI calls are made server-side — no API key in the app.
  static const _serverUrl = 'http://213.133.97.141:3000';

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

    // ── Interactive Widget Instruction ──
    const interactiveInstruction = """

Interactive Learning Widgets:
You have access to a set of built-in interactive learning widgets that can be embedded directly in your response. 
When a student asks about any of the following topics, you MUST include the corresponding widget tag on its own line at the end of your explanation:

Available widgets (use EXACTLY these tags):
- Circle area, circumference, geometry of circles → [interactive:circle_area]
- Newton's second law, F=ma, force mass acceleration → [interactive:newton_second_law]
- Linear equations, graphs, slope, y-intercept, algebra → [interactive:graph_plotter]
- Trigonometry, sine, cosine, tangent, unit circle, angles → [interactive:unit_circle]
- Atoms, protons, neutrons, electrons, atomic structure, chemistry → [interactive:atom_builder]
- Heart, cardiac cycle, heartbeat, biology, circulatory system → [interactive:heart_pump]
- Earth rotation, seasons, axial tilt, geography, day and night → [interactive:earth_rotation]

Rules:
1. Place the widget tag on its own line at the end of your response.
2. Only include a widget tag if the topic genuinely matches.
3. Never include more than one widget tag per response.
4. Never explain or mention the tag itself to the student — just include it silently.
5. Do NOT wrap the tag in backticks or code blocks.
""";

    String systemInstruction = '';
    String model = 'gemini-3.1-flash-lite';

    switch (mode) {
      case 'Deep Research':
        systemInstruction = '$preamble$interactiveInstruction '
            'You are a highly analytical deep researcher. Provide comprehensive, '
            'fact-based answers with structure and simulated citations with author, '
            'journal, and year. Use a formal, academic tone. Always include a '
            'Summary, Key Findings, and Further Reading section.';
        model = 'gemini-3.1-flash-lite';
        break;
      case 'Web Search':
        systemInstruction = '$preamble$interactiveInstruction '
            'You simulate a smart web search engine. When given a query, respond as '
            'if you searched the web and are presenting the top aggregated results. '
            'Show 3-5 summarised results with bullet points, URLs (simulated), and a '
            'final summary paragraph. Label each result with a numbered source.';
        model = 'gemini-3.1-flash-lite';
        break;
      case 'Homework':
        systemInstruction = '$preamble$interactiveInstruction '
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
        systemInstruction = '$preamble$interactiveInstruction '
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
            Uri.parse('$_serverUrl/api/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'mode': mode,
              'webSearch': mode == 'Web Search',
              'messages': messages,
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

        // NEVER inject interactive widgets for image analysis responses
        String resultText = attachments.isEmpty
            ? _appendInteractiveWidget(rawText, prompt)
            : rawText;  // Images: return Gemini Vision response as-is

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


  // ─────────────────────────────────────────────────────────────────
  // ADAPTIVE INTERACTIVE WIDGET INJECTION
  // Educational Rules:
  // 1. Basic "explain X" questions get clean, clear text explanations.
  // 2. If student asks for visual models, simulations, interactive practice,
  //    says "I don't understand", or requests deep learning, the matching
  //    educational simulation widget is dynamically attached.
  // 3. Covers all major subject domains (Physics, Chem, Bio, Math, Geo).
  // ─────────────────────────────────────────────────────────────────
  static String _appendInteractiveWidget(String aiResponse, String userPrompt) {
    // 1. Skip if AI response already embedded a widget tag
    if (RegExp(r'\[interactive:[a-zA-Z0-9_-]+\]').hasMatch(aiResponse)) {
      return aiResponse;
    }

    // 2. ONLY match against the user's prompt — never against the AI response text.
    // This prevents hallucinated widget injection.
    final promptLower = userPrompt.toLowerCase();

    // 3. BLACKLIST: prompts that are about images/diagrams/files — never inject a widget
    final imageBlacklist = [
      'this image', 'this photo', 'this picture', 'this diagram', 'this chart',
      'this screenshot', 'this figure', 'explain this', 'analyze this', 'analyse this',
      'what is this', 'what does this', 'describe this', 'look at this',
      'attached image', 'uploaded image', 'the image', 'the photo',
    ];
    if (imageBlacklist.any((kw) => promptLower.contains(kw))) {
      return aiResponse;
    }

    // 4. Comprehensive Subject Domain Keyword Registry
    final domainRules = <String, List<String>>{
      // ⚛️ Chemistry / Atomic Physics Domain
      'atom_builder': [
        'atom', 'atomic structure', 'proton', 'neutron', 'electron',
        'nucleus', 'atomic number', 'atomic mass', 'element', 'isotope',
        'bohr model', 'electron shell', 'valence', 'subatomic', 'matter',
        'chemical structure', 'helium atom', 'hydrogen atom',
      ],

      // ⚡ Physics / Dynamics / Mechanics Domain
      'newton_second_law': [
        'newton', 'second law', 'f = ma', 'f=ma', 'force mass acceleration',
        'net force', 'fma', 'law of motion', 'inertia',
        'friction', 'gravity', 'velocity', 'momentum', 'kinematics',
        'physics simulation', 'force calculation',
      ],

      // 📐 Geometry / Area & Measurement Domain
      'circle_area': [
        'area of a circle', 'circle area', 'πr²', 'pi r squared',
        'circumference of circle', 'radius of circle', 'diameter of circle',
        'circle geometry', 'disk area', 'circle math',
      ],

      // 🔵 Trigonometry / Periodic Functions Domain
      'unit_circle': [
        'unit circle', 'sine cosine', 'sin cos', 'trigonometry', 'trigonometric',
        'sin(', 'cos(', 'tan(', 'radian', 'degrees to radians',
        'pythagorean identity', 'trig ratio', 'angle measure', 'hypotenuse',
      ],

      // 📊 Algebra / Coordinate Geometry & Functions Domain
      'graph_plotter': [
        'linear equation', 'slope intercept', 'y = mx', 'y=mx', 'straight line graph',
        'plot a graph', 'graph of equation', 'gradient of line', 'y-intercept',
        'algebraic graph', 'slope of line', 'coordinate geometry', 'function plot',
      ],

      // ❤️ Biology / Human Physiology Domain
      'heart_pump': [
        'heart', 'cardiac', 'heartbeat', 'circulatory system', 'blood pump',
        'ventricle', 'atrium', 'pulse rate', 'bpm', 'heart rate',
        'systole', 'diastole', 'cardiovascular', 'human heart', 'blood circulation',
      ],

      // 🌍 Geography / Astronomy / Planetary Science Domain
      'earth_rotation': [
        'earth rotation', 'earth revolve', 'axial tilt', 'seasons',
        'day and night', 'day night cycle', 'solstice', 'equinox',
        'earth orbit', 'rotation of earth', 'why do seasons change',
        'geographic rotation', 'planetary tilt',
      ],
    };

    // 5. Match predefined domain rules ONLY — no fallback slug generation
    for (final entry in domainRules.entries) {
      final widgetId = entry.key;
      final keywords = entry.value;
      final matchesTopic = keywords.any((kw) => promptLower.contains(kw));
      if (matchesTopic) {
        return '$aiResponse\n\n[interactive:$widgetId]';
      }
    }

    // 6. No match found — return clean response without any widget
    //    (Removed _deriveTopicSlug fallback: it created fake "Interactive Model: This Image"
    //     widgets from generic prompts like "explain this image")
    return aiResponse;
  }

  /// Derives a clean concept slug identifier from any user prompt
  static String _deriveTopicSlug(String prompt) {
    final clean = prompt
        .replaceAll(RegExp(r'\b(explain|simulate|simulation|animation|interactive|model|visual|visually|diagram|practice|sandbox|experiment|deep|deeply|understand|concept|show|me|how|does|what|is|are|the|a|an|of|in|to|for|with|about|can|you|please|help|i|dont|dont|didnt)\b'), '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .trim();

    if (clean.isEmpty) return 'general_concept';
    final words = clean.split(RegExp(r'\s+')).where((w) => w.length > 1).take(3).toList();
    if (words.isEmpty) return 'general_concept';
    return words.join('_');
  }

  static String _getMockFallbackResponse(String prompt) {
    final query = prompt.toLowerCase();

    if (query.contains('code') || query.contains('program') || query.contains('write a') || query.contains('flutter') || query.contains('dart')) {
      return r"""Here is a custom Flutter widget demonstrating our premium styling concepts.

### Flutter Custom Container Example

We can create a clean, modern container with custom borders and background colors:

```dart
class PremiumContainer extends StatelessWidget {
  final Widget child;

  const PremiumContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2B2B2B), width: 1.2),
      ),
      child: child,
    );
  }
}
```

This widget uses:
* **Matte background** (`Color(0xFF171717)`)
* **Solid border** (`Color(0xFF2B2B2B)`)
* **Smooth rounded corners** (`12px`)""";
    }

    if (query.contains('math') || query.contains('solve') || query.contains('equation')) {
      return r"""Let's solve the quadratic equation $x^2 - 5x + 6 = 0$ step-by-step:

### Quadratic Equation Solution

Given equation:
$$x^2 - 5x + 6 = 0$$

1. **Identify the coefficients**:
   * $a = 1$
   * $b = -5$
   * $c = 6$

2. **Apply the quadratic formula**:
   $$x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$$

3. **Calculate the discriminant**:
   $$D = (-5)^2 - 4(1)(6) = 25 - 24 = 1$$

4. **Find the roots**:
   * $x_1 = \frac{5 + 1}{2} = 3$
   * $x_2 = \frac{5 - 1}{2} = 2$

The solution set is **{2, 3}**.""";
    }

    // Generic connection error — honest and helpful
    return """🔄 **Jeeni couldn't reach the server right now.**

This may be due to:
- A temporary network issue
- A slow or large file upload taking too long
- The server restarting

**Please try again in a moment.** If the issue persists, try refreshing the page.

> Your question was: *"$prompt"*""";
  }
}
