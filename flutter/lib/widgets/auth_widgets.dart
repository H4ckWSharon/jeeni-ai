import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════
// AUTHENTICATION WIDGETS
// ═══════════════════════════════════════════════════

class AuthTextField extends StatefulWidget {
  final String hintText;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final IconData? prefixIcon;

  const AuthTextField({
    super.key,
    required this.hintText,
    this.isPassword = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _isObscure = true;
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.isPassword;
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _isFocused ? Colors.white.withOpacity(0.5) : Colors.white.withOpacity(0.15),
          width: 1.0,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: _isObscure,
        keyboardType: widget.keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: widget.prefixIcon != null
              ? Icon(
                  widget.prefixIcon,
                  color: _isFocused ? Colors.white : const Color(0xFF9CA3AF),
                  size: 20,
                )
              : null,
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF9CA3AF),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}

class AuthButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isLoading;
  final Widget? icon;

  const AuthButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isPrimary = true,
    this.isLoading = false,
    this.icon,
  });

  @override
  State<AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<AuthButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isLoading) _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.isLoading) {
      _scaleController.reverse();
      widget.onTap();
    }
  }

  void _onTapCancel() {
    if (!widget.isLoading) _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isPrimary ? Colors.white : Colors.transparent;
    final borderColor = widget.isPrimary ? Colors.transparent : Colors.white.withOpacity(0.15);
    final textColor = widget.isPrimary ? Colors.black : Colors.white;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: borderColor),
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: widget.isPrimary ? Colors.black : Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        widget.icon!,
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// GOOGLE AUTH BUTTON (OFFICIAL STYLE)
// ═══════════════════════════════════════════════════

class GoogleAuthButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isLoading;
  const GoogleAuthButton({super.key, required this.onTap, this.isLoading = false});

  @override
  State<GoogleAuthButton> createState() => _GoogleAuthButtonState();
}

class _GoogleAuthButtonState extends State<GoogleAuthButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _scaleController.forward();
  
  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap();
  }
  
  void _onTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: widget.isLoading 
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CustomPaint(painter: _GoogleLogoPainter()),
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final double w = size.width;
    final double h = size.height;

    // Red
    paint.color = const Color(0xFFEA4335);
    Path path1 = Path()
      ..moveTo(w * 0.5, h * 0.0)
      ..cubicTo(w * 0.75, h * 0.0, w * 0.95, h * 0.15, w * 0.95, h * 0.15)
      ..lineTo(w * 0.78, h * 0.35)
      ..cubicTo(w * 0.7, h * 0.28, w * 0.6, h * 0.25, w * 0.5, h * 0.25)
      ..cubicTo(w * 0.36, h * 0.25, w * 0.23, h * 0.33, w * 0.15, h * 0.45)
      ..lineTo(w * 0.0, h * 0.3)
      ..cubicTo(w * 0.1, h * 0.12, w * 0.28, h * 0.0, w * 0.5, h * 0.0)
      ..close();
    canvas.drawPath(path1, paint);

    // Yellow
    paint.color = const Color(0xFFFBBC05);
    Path path2 = Path()
      ..moveTo(w * 0.0, h * 0.3)
      ..cubicTo(w * -0.05, h * 0.45, w * -0.05, h * 0.55, w * 0.0, h * 0.7)
      ..lineTo(w * 0.15, h * 0.55)
      ..cubicTo(w * 0.12, h * 0.5, w * 0.12, h * 0.5, w * 0.15, h * 0.45)
      ..close();
    canvas.drawPath(path2, paint);

    // Green
    paint.color = const Color(0xFF34A853);
    Path path3 = Path()
      ..moveTo(w * 0.0, h * 0.7)
      ..cubicTo(w * 0.1, h * 0.88, w * 0.28, h * 1.0, w * 0.5, h * 1.0)
      ..cubicTo(w * 0.75, h * 1.0, w * 0.95, h * 0.85, w * 0.95, h * 0.85)
      ..lineTo(w * 0.8, h * 0.68)
      ..cubicTo(w * 0.72, h * 0.76, w * 0.62, h * 0.8, w * 0.5, h * 0.8)
      ..cubicTo(w * 0.36, h * 0.8, w * 0.23, h * 0.7, w * 0.15, h * 0.55)
      ..close();
    canvas.drawPath(path3, paint);

    // Blue
    paint.color = const Color(0xFF4285F4);
    Path path4 = Path()
      ..moveTo(w * 0.5, h * 0.48)
      ..lineTo(w * 1.0, h * 0.48)
      ..lineTo(w * 1.0, h * 0.6)
      ..cubicTo(w * 1.0, h * 0.75, w * 0.95, h * 0.85, w * 0.95, h * 0.85)
      ..lineTo(w * 0.8, h * 0.68)
      ..cubicTo(w * 0.85, h * 0.65, w * 0.85, h * 0.6, w * 0.85, h * 0.6)
      ..lineTo(w * 0.5, h * 0.6)
      ..close();
    canvas.drawPath(path4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════
// APPLE AUTH BUTTON
// ═══════════════════════════════════════════════════

class AppleAuthButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isLoading;
  const AppleAuthButton({super.key, required this.onTap, this.isLoading = false});

  @override
  State<AppleAuthButton> createState() => _AppleAuthButtonState();
}

class _AppleAuthButtonState extends State<AppleAuthButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _scaleController.forward();
  
  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap();
  }
  
  void _onTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: widget.isLoading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.apple, color: Colors.white, size: 20),
                  SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Continue with Apple',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// AUTH DIVIDER
// ═══════════════════════════════════════════════════

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.1))),
      ],
    );
  }
}
