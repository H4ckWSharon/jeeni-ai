import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// A reusable gradient button with press animation
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Gradient gradient;
  final double height;
  final double borderRadius;
  final double fontSize;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    this.gradient = AppColors.primaryGradient,
    this.height = 56,
    this.borderRadius = 16,
    this.fontSize = 16,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.reverse();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _controller.forward();
        widget.onPressed();
      },
      onTapCancel: () => _controller.forward(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) =>
            Transform.scale(scale: _controller.value, child: child),
        child: Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.leadingIcon != null) ...[
                Icon(widget.leadingIcon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(widget.trailingIcon, color: Colors.white, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A reusable ghost/outlined button
class OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final double height;

  const OutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.surfaceElevated, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Jeeni logo widget — reusable across screens
class JeeniLogo extends StatelessWidget {
  final double size;
  final double iconSize;
  final double borderRadius;

  const JeeniLogo({
    super.key,
    this.size = 64,
    this.iconSize = 28,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Center(
        child: Icon(Icons.auto_awesome, color: Colors.white, size: iconSize),
      ),
    );
  }
}
