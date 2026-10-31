import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

typedef PasswordResetSender = Future<void> Function();
typedef PasswordChanger =
    Future<void> Function(String currentPassword, String newPassword);

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    this.sendResetEmail,
    this.changePassword,
    super.key,
  });

  final PasswordResetSender? sendResetEmail;
  final PasswordChanger? changePassword;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSendingEmail = false;
  bool _isChangingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  String? _emailMessage;
  String? _passwordMessage;
  bool _emailError = false;
  bool _passwordError = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
        children: [
          _PasswordOptionCard(
            title: 'Verify through email',
            detail: 'Send a secure password-reset link to your account email.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  key: const Key('send-password-reset'),
                  onPressed: _isSendingEmail ? null : _sendResetEmail,
                  icon: _isSendingEmail
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.mark_email_read_rounded),
                  label: Text(
                    _isSendingEmail ? 'Sending...' : 'Send reset email',
                  ),
                ),
                if (_emailMessage != null) ...[
                  const SizedBox(height: 10),
                  _StatusMessage(message: _emailMessage!, isError: _emailError),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _PasswordOptionCard(
            title: 'Change with current password',
            detail:
                'Reauthenticate with your current password, then choose a new one.',
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('current-password'),
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrent,
                    autofillHints: const [AutofillHints.password],
                    decoration: _passwordDecoration(
                      label: 'Current password',
                      obscured: _obscureCurrent,
                      onToggle: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    validator: (value) => (value ?? '').isEmpty
                        ? 'Enter your current password.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('new-password'),
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: _passwordDecoration(
                      label: 'New password',
                      obscured: _obscureNew,
                      onToggle: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    validator: (value) => (value ?? '').length < 6
                        ? 'Enter at least 6 characters.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('confirm-new-password'),
                    controller: _confirmPasswordController,
                    obscureText: _obscureNew,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                      filled: true,
                      fillColor: AppColors.deepInk,
                    ),
                    validator: (value) => value != _newPasswordController.text
                        ? 'Passwords must match.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const Key('change-password'),
                    onPressed: _isChangingPassword ? null : _changePassword,
                    icon: _isChangingPassword
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.password_rounded),
                    label: Text(
                      _isChangingPassword ? 'Changing...' : 'Change password',
                    ),
                  ),
                  if (_passwordMessage != null) ...[
                    const SizedBox(height: 10),
                    _StatusMessage(
                      message: _passwordMessage!,
                      isError: _passwordError,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _passwordDecoration({
    required String label,
    required bool obscured,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.deepInk,
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          obscured ? Icons.visibility_rounded : Icons.visibility_off_rounded,
        ),
      ),
    );
  }

  Future<void> _sendResetEmail() async {
    setState(() {
      _isSendingEmail = true;
      _emailMessage = null;
      _emailError = false;
    });
    try {
      final callback = widget.sendResetEmail;
      if (callback != null) {
        await callback();
      } else {
        final email = FirebaseAuth.instance.currentUser?.email;
        if (email == null || email.isEmpty) {
          throw StateError('No account email is available.');
        }
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      }
      if (!mounted) return;
      setState(() {
        _emailMessage = 'Password reset email sent.';
        _emailError = false;
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _emailMessage = _firebaseMessage(error);
        _emailError = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _emailMessage = error is StateError
            ? error.message.toString()
            : 'Unable to send the reset email.';
        _emailError = true;
      });
    } finally {
      if (mounted) setState(() => _isSendingEmail = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isChangingPassword = true;
      _passwordMessage = null;
      _passwordError = false;
    });
    try {
      final currentPassword = _currentPasswordController.text;
      final newPassword = _newPasswordController.text;
      final callback = widget.changePassword;
      if (callback != null) {
        await callback(currentPassword, newPassword);
      } else {
        final user = FirebaseAuth.instance.currentUser;
        final email = user?.email;
        if (user == null || email == null || email.isEmpty) {
          throw StateError('No signed-in email account is available.');
        }
        final credential = EmailAuthProvider.credential(
          email: email,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
      }
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      if (!mounted) return;
      setState(() {
        _passwordMessage = 'Password changed successfully.';
        _passwordError = false;
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _passwordMessage = _firebaseMessage(error);
        _passwordError = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _passwordMessage = error is StateError
            ? error.message.toString()
            : 'Unable to change the password.';
        _passwordError = true;
      });
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  String _firebaseMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' => 'The current password is incorrect.',
      'weak-password' => 'Choose a stronger new password.',
      'too-many-requests' => 'Too many attempts. Try again later.',
      'network-request-failed' => 'Network error. Check your connection.',
      'user-not-found' => 'This account is no longer available.',
      _ => error.message ?? 'Unable to update the password.',
    };
  }
}

class _PasswordOptionCard extends StatelessWidget {
  const _PasswordOptionCard({
    required this.title,
    required this.detail,
    required this.child,
  });

  final String title;
  final String detail;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            detail,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(
        color: isError ? AppColors.red : AppColors.pulse,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
