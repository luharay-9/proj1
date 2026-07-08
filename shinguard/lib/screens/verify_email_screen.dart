import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    required this.user,
    required this.onVerified,
    super.key,
  });

  final User user;
  final VoidCallback onVerified;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isChecking = false;
  bool _isSending = false;
  String? _message;
  bool _isError = false;

  @override
  Widget build(BuildContext context) {
    final email = widget.user.email ?? 'your email';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.mark_email_unread_rounded,
                    color: AppColors.pulse,
                    size: 76,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Verify your email',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a verification link to $email. Open that link, then come back here and continue.',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _message!,
                      style: TextStyle(
                        color: _isError ? AppColors.red : AppColors.pulse,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _isChecking ? null : _checkVerification,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.pulse,
                      foregroundColor: AppColors.ink,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    child: _isChecking
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.ink,
                            ),
                          )
                        : const Text('I verified my email'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isSending ? null : _sendVerificationEmail,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.pulse,
                      side: const BorderSide(color: AppColors.line),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    child: Text(
                      _isSending ? 'Sending...' : 'Resend verification email',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: const Text('Back to sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkVerification() async {
    setState(() {
      _isChecking = true;
      _message = null;
      _isError = false;
    });

    try {
      await widget.user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser?.emailVerified ?? false) {
        await refreshedUser?.getIdToken(true);
        widget.onVerified();
      } else {
        setState(() {
          _message = 'That email is not verified yet.';
          _isError = true;
        });
      }
    } on FirebaseAuthException catch (error) {
      setState(() {
        _message = error.message ?? 'Unable to check verification right now.';
        _isError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _sendVerificationEmail() async {
    setState(() {
      _isSending = true;
      _message = null;
      _isError = false;
    });

    try {
      await widget.user.sendEmailVerification();
      setState(() {
        _message = 'Verification email sent.';
        _isError = false;
      });
    } on FirebaseAuthException catch (error) {
      setState(() {
        _message = error.message ?? 'Unable to send verification email.';
        _isError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}
