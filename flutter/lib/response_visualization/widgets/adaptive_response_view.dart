import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/response_mode.dart';
import '../animations/simple_pulse_animation.dart';
import '../animations/knowledge_flow_animation.dart';
import '../animations/math_flow_animation.dart';
import '../animations/code_generation_animation.dart';
import '../animations/network_flow_animation.dart';
import '../animations/cybersecurity_scan_animation.dart';
import '../animations/retrieval_flow_animation.dart';
import '../animations/comparison_flow_animation.dart';
import '../animations/lesson_builder_animation.dart';
import '../animations/data_analysis_animation.dart';
import '../animations/default_jeeni_animation.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// ADAPTIVE RESPONSE VIEW
/// Production-grade context-aware visualizer for active AI response generation.
/// ════════════════════════════════════════════════════════════════════════════
class AdaptiveResponseView extends StatefulWidget {
  final AdaptiveAnimationConfig config;
  final VoidCallback? onStop;

  const AdaptiveResponseView({
    super.key,
    required this.config,
    this.onStop,
  });

  @override
  State<AdaptiveResponseView> createState() => _AdaptiveResponseViewState();
}

class _AdaptiveResponseViewState extends State<AdaptiveResponseView> {
  int _currentStatusIndex = 0;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _startStatusCycle();
  }

  @override
  void didUpdateWidget(AdaptiveResponseView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.responseMode != widget.config.responseMode) {
      _currentStatusIndex = 0;
      _startStatusCycle();
    }
  }

  void _startStatusCycle() {
    _statusTimer?.cancel();
    if (widget.config.statusLabels.length <= 1) return;

    _statusTimer = Timer.periodic(const Duration(milliseconds: 2100), (timer) {
      if (!mounted) return;
      setState(() {
        _currentStatusIndex = (_currentStatusIndex + 1) % widget.config.statusLabels.length;
      });
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusText = widget.config.statusLabels.isNotEmpty
        ? widget.config.statusLabels[_currentStatusIndex % widget.config.statusLabels.length]
        : 'Preparing response...';

    // Respect user's device preference for reduced motion
    final prefersReducedMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      liveRegion: true,
      label: 'Jeeni response status: $statusText',
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF131316),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.config.primaryColor.withValues(alpha: 0.22),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Header: Mode Badge + Complexity Pill + Stop Button ──
            Row(
              children: [
                // Mode Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.config.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.config.primaryColor.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.config.badgeIcon,
                        size: 13,
                        color: widget.config.primaryColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.config.badgeLabel,
                        style: TextStyle(
                          color: widget.config.accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Complexity Indicator Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.config.complexityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.config.complexityColor.withValues(alpha: 0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    widget.config.complexityLabel,
                    style: TextStyle(
                      color: widget.config.complexityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const Spacer(),

                // Stop Generation Button
                if (widget.onStop != null)
                  Tooltip(
                    message: 'Stop generating',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onStop?.call();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.stop_rounded,
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Stop',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Middle: Distinct Visual Animation ──
            if (prefersReducedMotion)
              _buildReducedMotionFallback()
            else
              _buildAnimation(widget.config),

            const SizedBox(height: 6),

            // ── Bottom: Progressive Status Label ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: widget.config.accentColor.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Text(
                      statusText,
                      key: ValueKey<String>(statusText),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Resolves the specific visual animation based on configuration
  Widget _buildAnimation(AdaptiveAnimationConfig config) {
    switch (config.visualizationType) {
      case VisualizationType.simplePulse:
        return SimplePulseAnimation(
          primaryColor: config.primaryColor,
          accentColor: config.accentColor,
          speed: config.speedMultiplier,
        );
      case VisualizationType.knowledgeFlow:
        return KnowledgeFlowAnimation(
          primaryColor: config.primaryColor,
          accentColor: config.accentColor,
          speed: config.speedMultiplier,
        );
      case VisualizationType.mathFlow:
        return MathFlowAnimation(
          primaryColor: config.primaryColor,
          accentColor: config.accentColor,
          speed: config.speedMultiplier,
        );
      case VisualizationType.codeGeneration:
        return CodeGenerationAnimation(
          primaryColor: config.primaryColor,
          accentColor: config.accentColor,
          speed: config.speedMultiplier,
        );
      case VisualizationType.networkFlow:
        return NetworkFlowAnimation(
          primaryColor: config.primaryColor,
          accentColor: config.accentColor,
          speed: config.speedMultiplier,
        );
      case VisualizationType.securityScan:
        return CybersecurityScanAnimation(
          primaryColor: config.primaryColor,
          accentColor: config.accentColor,
          speed: config.speedMultiplier,
        );
      case VisualizationType.retrievalFlow:
        return RetrievalFlowAnimation(
          primaryColor: config.primaryColor,
          accentColor: config.accentColor,
          speed: config.speedMultiplier,
        );
      case VisualizationType.comparisonFlow:
        return ComparisonFlowAnimation(
          primaryColor: config.primaryColor,
          accentColor: config.accentColor,
          speed: config.speedMultiplier,
        );
      case VisualizationType.lessonBuilder:
        return LessonBuilderAnimation(
          primaryColor: config.primaryColor,
          accentColor: config.accentColor,
          speed: config.speedMultiplier,
        );
      case VisualizationType.dataAnalysis:
        return DataAnalysisAnimation(
          primaryColor: config.primaryColor,
          accentColor: config.accentColor,
          speed: config.speedMultiplier,
        );
      case VisualizationType.defaultJeeni:
        return DefaultJeeniAnimation(
          primaryColor: config.primaryColor,
          accentColor: config.accentColor,
          speed: config.speedMultiplier,
        );
    }
  }

  /// Elegant static visual representation when the user has enabled prefers-reduced-motion
  Widget _buildReducedMotionFallback() {
    return Container(
      height: 48,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.config.badgeIcon,
            color: widget.config.accentColor,
            size: 24,
          ),
          const SizedBox(width: 10),
          Text(
            'Processing...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
