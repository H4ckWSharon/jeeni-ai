import 'package:flutter/material.dart';
import '../../response_visualization/models/response_mode.dart';
import '../models/orb_state.dart';
import '../renderers/thinking_orb_painter.dart';

/// Minimalist, native inline Thinking Orb activity indicator for Jeeni Android.
///
/// Designed to sit naturally on the pure black chat background at ~20dp scale:
/// - 100% transparent background (no cards, no borders, no glowing purple panels)
/// - Positioned inline on the left where the AI response text naturally starts
/// - High-contrast, theme-aware light-ink monochrome dot cloud
/// - Compact, non-intrusive stop action
class ThinkingOrbsResponseView extends StatefulWidget {
  final OrbState state;
  final OrbVariant variant;
  final AdaptiveAnimationConfig? config;
  final VoidCallback? onStop;
  final double size; // ~20dp visual scale
  final bool showStatusText;

  const ThinkingOrbsResponseView({
    super.key,
    required this.state,
    this.variant = OrbVariant.classic,
    this.config,
    this.onStop,
    this.size = 20.0,
    this.showStatusText = false,
  });

  @override
  State<ThinkingOrbsResponseView> createState() => _ThinkingOrbsResponseViewState();
}

class _ThinkingOrbsResponseViewState extends State<ThinkingOrbsResponseView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final stateMeta = OrbStateConfig.of(widget.state);

    return Semantics(
      liveRegion: true,
      label: 'Jeeni AI is ${widget.state.name}: ${stateMeta.label}',
      child: Container(
        color: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(left: 16, top: 4, bottom: 6, right: 16),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── The Tiny 20dp Thinking Orb ──
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: ThinkingOrbPainter(
                      state: widget.state,
                      variant: widget.variant,
                      progress: reduceMotion ? 0.25 : _animController.value,
                      isDark: isDark,
                      primaryColor: const Color(0xFFFFFFFF),
                      isInlineSmall: true,
                    ),
                  );
                },
              ),
            ),

            // ── Optional Subtle State Label ──
            if (widget.showStatusText) ...[
              const SizedBox(width: 8),
              Text(
                stateMeta.label,
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
            ],

            // ── Compact, Non-intrusive Stop Action ──
            if (widget.onStop != null) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: widget.onStop,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stop',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.black.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
