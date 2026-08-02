import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class LearningScaffold extends StatefulWidget {
  final String title;
  final Widget level1;
  final Widget level2;
  final Widget level3;
  final Widget level4;
  final Widget level5;
  final List<String> levelAudioTexts; // List of 5 strings corresponding to each level
  
  // Playback control callbacks (used in simulations)
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onReset;
  final VoidCallback? onStepForward;
  final VoidCallback? onStepBackward;
  final bool showPlaybackControls;
  final bool isPlaying;

  const LearningScaffold({
    super.key,
    required this.title,
    required this.level1,
    required this.level2,
    required this.level3,
    required this.level4,
    required this.level5,
    required this.levelAudioTexts,
    this.onPlay,
    this.onPause,
    this.onReset,
    this.onStepForward,
    this.onStepBackward,
    this.showPlaybackControls = false,
    this.isPlaying = false,
  });

  @override
  State<LearningScaffold> createState() => _LearningScaffoldState();
}

class _LearningScaffoldState extends State<LearningScaffold> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _stopSpeaking();
        setState(() {});
      }
    });
    _initTts();
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() => _isSpeaking = false);
      debugPrint('TTS Error: $msg');
    });
  }

  Future<void> _speakText() async {
    if (_isSpeaking) {
      await _stopSpeaking();
      return;
    }
    final text = widget.levelAudioTexts.length > _tabController.index
        ? widget.levelAudioTexts[_tabController.index]
        : '';
    if (text.isNotEmpty) {
      setState(() => _isSpeaking = true);
      await _flutterTts.speak(text);
    }
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    if (mounted) {
      setState(() => _isSpeaking = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeLevel = _tabController.index + 1;
    final showPlayback = widget.showPlaybackControls && activeLevel == 4;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Level $activeLevel - ${_getLevelName(activeLevel)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Audio Narration
                IconButton(
                  icon: Icon(
                    _isSpeaking ? Icons.volume_up : Icons.volume_mute,
                    color: _isSpeaking ? const Color(0xFF10B981) : Colors.white.withOpacity(0.6),
                    size: 20,
                  ),
                  onPressed: _speakText,
                  tooltip: _isSpeaking ? 'Mute' : 'Speak concept',
                ),
                // Custom simulation controls in Level 4
                if (showPlayback) ...[
                  IconButton(
                    icon: Icon(Icons.skip_previous_rounded, color: Colors.white.withOpacity(0.6), size: 20),
                    onPressed: widget.onStepBackward,
                    tooltip: 'Step Back',
                  ),
                  IconButton(
                    icon: Icon(
                      widget.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: const Color(0xFF10B981),
                      size: 22,
                    ),
                    onPressed: widget.isPlaying ? widget.onPause : widget.onPlay,
                    tooltip: widget.isPlaying ? 'Pause' : 'Play',
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_next_rounded, color: Colors.white.withOpacity(0.6), size: 20),
                    onPressed: widget.onStepForward,
                    tooltip: 'Step Forward',
                  ),
                  IconButton(
                    icon: Icon(Icons.replay_rounded, color: Colors.white.withOpacity(0.6), size: 20),
                    onPressed: widget.onReset,
                    tooltip: 'Reset',
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF222222)),

          // ── Level Tabs ──
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF10B981),
            labelColor: const Color(0xFF10B981),
            unselectedLabelColor: Colors.white.withOpacity(0.4),
            indicatorWeight: 2,
            dividerColor: Colors.transparent,
            labelPadding: EdgeInsets.zero,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'L1'),
              Tab(text: 'L2'),
              Tab(text: 'L3'),
              Tab(text: 'L4'),
              Tab(text: 'L5'),
            ],
          ),
          const Divider(height: 1, color: Color(0xFF222222)),

          // ── Content Tab Views ──
          SizedBox(
            height: 380,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(child: widget.level1),
                  SingleChildScrollView(child: widget.level2),
                  SingleChildScrollView(child: widget.level3),
                  SingleChildScrollView(child: widget.level4),
                  SingleChildScrollView(child: widget.level5),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  String _getLevelName(int level) {
    switch (level) {
      case 1:
        return 'Definition';
      case 2:
        return 'Analogy';
      case 3:
        return 'Visualization';
      case 4:
        return 'Simulation';
      case 5:
        return 'Practice Quiz';
      default:
        return '';
    }
  }
}
