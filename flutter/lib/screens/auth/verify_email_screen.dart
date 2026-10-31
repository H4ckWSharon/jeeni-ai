import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/auth_widgets.dart';
import 'auth_gate.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isEmailVerified = false;
  bool _canResendEmail = false;
  int _resendCooldown = 60;
  Timer? _cooldownTimer;
  Timer? _autoCheckTimer;
  bool _isChecking = false;
  String? _statusMessage;
  bool _isErrorMessage = false;

  @override
  void initState() {
    super.initState();
    _isEmailVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (!_isEmailVerified) {
      // Automatically poll every 3 seconds to see if user clicked verification link
      _autoCheckTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _checkEmailVerified(silent: true),
      );

      _startResendCooldown();
    }
  }

  void _startResendCooldown() {
    setState(() {
      _canResendEmail = false;
      _resendCooldown = 60;
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown > 1) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
        setState(() => _canResendEmail = true);
      }
    });
  }

  Future<void> _checkEmailVerified({bool silent = false}) async {
    if (_isChecking && !silent) return;

    if (!silent) {
      setState(() => _isChecking = true);
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;

        if (refreshedUser != null && refreshedUser.emailVerified) {
          _autoCheckTimer?.cancel();
          _cooldownTimer?.cancel();

          if (!mounted) return;
          setState(() {
            _isEmailVerified = true;
            _statusMessage = 'Email verified successfully!';
            _isErrorMessage = false;
          });

          // Smooth navigation to chat
          Future.delayed(const Duration(milliseconds: 600), () {
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthGate()),
              (route) => false,
            );
          });
          return;
        } else if (!silent) {
          if (!mounted) return;
          setState(() {
            _statusMessage = 'Email is not verified yet. Please click the link in your inbox.';
            _isErrorMessage = true;
          });
        }
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(() {
          _statusMessage = 'Could not check status. Please try again.';
          _isErrorMessage = true;
        });
      }
    } finally {
      if (!silent && mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        if (!mounted) return;
        setState(() {
          _statusMessage = 'A new verification email has been sent!';
          _isErrorMessage = false;
        });
        _startResendCooldown();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = e.code == 'too-many-requests'
            ? 'Please wait a moment before requesting another email.'
            : (e.message ?? 'Failed to resend email');
        _isErrorMessage = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Failed to resend email. Please try again.';
        _isErrorMessage = true;
      });
    }
  }

  Future<void> _logout() async {
    _autoCheckTimer?.cancel();
    _cooldownTimer?.cancel();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'your email address';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                decoration: BoxDecoration(
                  color: const Color(0xFF111116).withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 40,
                      spreadRadius: 8,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon Header
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_rounded,
                          size: 40,
                          color: Color(0xFF60A5FA),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      'Verify Your Email',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Subtitle with Email
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.5,
                          color: Colors.white.withValues(alpha: 0.70),
                        ),
                        children: [
                          const TextSpan(text: 'We sent a verification link to:\n'),
                          TextSpan(
                            text: email,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Click the link in the email to activate your account. Be sure to check your Spam or Junk folder.',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Status / Error message
                    if (_statusMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: (_isErrorMessage
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981))
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (_isErrorMessage
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF10B981))
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isErrorMessage
                                  ? Icons.error_outline_rounded
                                  : Icons.check_circle_outline_rounded,
                              size: 18,
                              color: _isErrorMessage
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _statusMessage!,
                                style: TextStyle(
                                  color: _isErrorMessage
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF10B981),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Manual Check Button
                    AuthButton(
                      text: "I've Verified My Email",
                      isLoading: _isChecking,
                      onTap: () => _checkEmailVerified(silent: false),
                    ),
                    const SizedBox(height: 14),

                    // Resend Email Button
                    OutlinedButton(
                      onPressed: _canResendEmail ? _resendVerificationEmail : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: BorderSide(
                          color: _canResendEmail
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _canResendEmail
                            ? 'Resend Verification Email'
                            : 'Resend in ${_resendCooldown}s',
                        style: TextStyle(
                          color: _canResendEmail
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Back / Log out
                    Center(
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _logout,
                          child: Text(
                            'Use another email / Log out',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

