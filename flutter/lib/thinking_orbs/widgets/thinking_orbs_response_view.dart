import 'dart:async';
import 'package:flutter/material.dart';
import '../../response_visualization/models/response_mode.dart';
import '../models/orb_state.dart';
import '../renderers/thinking_orb_painter.dart';

/// Production-ready mobile Thinking Orbs response visualization card.
/// Designed specifically for Android APK to deliver an intelligent,
/// educational, and polished visual experience.
class ThinkingOrbsResponseView extends StatefulWidget {
  final OrbState state;
  final OrbVariant variant;
  final AdaptiveAnimationConfig? config;
  final VoidCallback? onStop;

  const ThinkingOrbsResponseView({
    super.key,
    required this.state,
    this.variant = OrbVariant.classic,
    this.config,
    this.onStop,
  });

  @override
  State<ThinkingOrbsResponseView> createState() => _ThinkingOrbsResponseViewState();
}

class _ThinkingOrbsResponseViewState extends State<ThinkingOrbsResponseView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  Timer? _statusTimer;
  int _statusPhraseIndex = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _startStatusRotation();
  }

  void _startStatusRotation() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
      if (!mounted) return;
      final config = OrbStateConfig.of(widget.state);
      if (config.statusPhrases.isNotEmpty) {
        setState(() {
          _statusPhraseIndex = (_statusPhraseIndex + 1) % config.statusPhrases.length;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant ThinkingOrbsResponseView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _statusPhraseIndex = 0;
      _startStatusRotation();
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final stateMeta = OrbStateConfig.of(widget.state);

    final statusText = stateMeta.statusPhrases.isNotEmpty
        ? stateMeta.statusPhrases[_statusPhraseIndex % stateMeta.statusPhrases.length]
        : 'Thinking...';

    return Semantics(
      liveRegion: true,
      label: 'Jeeni AI status: ${stateMeta.label}. $statusText',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141416) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: stateMeta.primaryColor.withValues(alpha: isDark ? 0.22 : 0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: stateMeta.glowColor,
              blurRadius: 18,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar: State badge, Complexity pill, Stop button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // State Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: stateMeta.primaryColor.withValues(alpha: isDark ? 0.16 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: stateMeta.primaryColor.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        stateMeta.icon,
                        size: 13,
                        color: stateMeta.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        stateMeta.label.toUpperCase(),
                        style: TextStyle(
                          color: stateMeta.primaryColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Stop Generation Button
                if (widget.onStop != null)
                  InkWell(
                    onTap: widget.onStop,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF222228) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? const Color(0xFF33333E) : const Color(0xFFE2E8F0),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Stop',
                            style: TextStyle(
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Center Stage: Thinking Orb Animation Canvas
            Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: ThinkingOrbPainter(
                        state: widget.state,
                        variant: widget.variant,
                        progress: reduceMotion ? 0.25 : _animController.value,
                        isDark: isDark,
                        primaryColor: stateMeta.primaryColor,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Bottom Status Text with subtle glowing pulse
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: Row(
                  key: ValueKey<String>(statusText),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stateMeta.primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: stateMeta.primaryColor,
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
