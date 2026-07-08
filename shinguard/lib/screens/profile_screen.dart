import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/firebase_data_repository.dart';
import '../models/app_data.dart';
import '../shared/shared_widgets.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final FirebaseDataRepository _repository = FirebaseDataRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserAppData>(
      stream: _repository.watchUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoading();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const AppMessage(
            title: 'Profile unavailable',
            detail: 'Check your Firebase user document.',
            icon: Icons.cloud_off_rounded,
          );
        }

        final data = snapshot.data!;
        return AppScrollView(
          children: [
            ProfileHeader(data: data),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ProfileStat(
                    value: '${data.matches}',
                    label: 'MATCHES',
                  ),
                ),
                Expanded(
                  child: ProfileStat(value: '${data.goals}', label: 'GOALS'),
                ),
                Expanded(
                  child: ProfileStat(
                    value: '${data.avgScore}',
                    label: 'AVG SCORE',
                  ),
                ),
              ],
            ),
            const SectionHeader(title: 'Achievements', action: 'View all'),
            SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: data.achievements.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final achievement = data.achievements[index];
                  return Achievement(
                    icon: achievement.icon,
                    title: achievement.title,
                  );
                },
              ),
            ),
            const SectionHeader(title: 'My ShinPulse'),
            DeviceCard(device: data.device),
            const SectionHeader(title: 'Settings'),
            const SettingsTile(
              icon: Icons.groups_rounded,
              title: 'Team & Coach',
            ),
            const SizedBox(height: 10),
            const SettingsTile(
              icon: Icons.notifications_rounded,
              title: 'Notifications',
              trailing: Switch(value: true, onChanged: null),
            ),
            const SizedBox(height: 10),
            const SettingsTile(
              icon: Icons.family_restroom,
              title: 'Parent Dashboard',
            ),
            const SizedBox(height: 10),
            const SettingsTile(
              icon: Icons.help_rounded,
              title: 'Help & Support',
            ),
            const SizedBox(height: 10),
            AccountActions(repository: _repository),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }
}

class AccountActions extends StatefulWidget {
  const AccountActions({required this.repository, super.key});

  final FirebaseDataRepository repository;

  @override
  State<AccountActions> createState() => _AccountActionsState();
}

class _AccountActionsState extends State<AccountActions> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsTile(
          icon: Icons.logout_rounded,
          title: 'Sign out',
          onTap: _isDeleting ? null : () => FirebaseAuth.instance.signOut(),
        ),
        const SizedBox(height: 10),
        SettingsTile(
          icon: Icons.delete_forever_rounded,
          title: _isDeleting ? 'Deleting account...' : 'Delete account',
          iconColor: AppColors.red,
          onTap: _isDeleting ? null : () => _showDeleteAccountDialog(context),
        ),
      ],
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: !_isDeleting,
      builder: (context) => const DeleteAccountDialog(),
    );

    if (password == null || !context.mounted) {
      return;
    }

    await _deleteAccount(context, password);
  }

  Future<void> _deleteAccount(BuildContext context, String password) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      _showError(context, 'No signed-in email account was found.');
      return;
    }

    setState(() => _isDeleting = true);
    var deleteSucceeded = false;
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await widget.repository.deleteCurrentUserData();
      await user.delete();
      deleteSucceeded = true;
    } on FirebaseAuthException catch (error) {
      if (context.mounted) {
        _showError(context, _messageForAuthError(error));
      }
    } catch (_) {
      if (context.mounted) {
        _showError(context, 'Unable to delete account data right now.');
      }
    } finally {
      if (mounted && !deleteSucceeded) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.red),
    );
  }

  String _messageForAuthError(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-credential' || 'wrong-password' => 'Password is incorrect.',
      'network-request-failed' => 'Network error. Check your connection.',
      'requires-recent-login' => 'Sign out, sign back in, then try again.',
      _ => error.message ?? 'Unable to delete this account right now.',
    };
  }
}

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.panel,
      title: const Text('Delete account'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your profile, sessions, matches, muscle reports, and login account.',
              style: TextStyle(
                color: AppColors.softText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
              ),
              validator: (value) {
                if ((value ?? '').isEmpty) {
                  return 'Enter your password to confirm.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: AppColors.ink,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_passwordController.text);
            }
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.data, super.key});

  final UserAppData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xff214e32), Color(0xff347449)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const PulseAvatar(size: 68),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.profileSubtitle,
                  style: const TextStyle(
                    color: AppColors.softText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  const DeviceCard({required this.device, super.key});

  final DeviceData device;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: panelDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              const IconBadge(
                icon: Icons.shield_rounded,
                color: AppColors.pulse,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      [
                        device.status,
                        device.firmware,
                      ].where((item) => item.isNotEmpty).join(' · '),
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.pulse,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.pulse, blurRadius: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: device.battery,
              minHeight: 8,
              backgroundColor: AppColors.deepInk,
              valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                device.batteryLabel,
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              Spacer(),
              Text(
                device.timeRemaining,
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileStat extends StatelessWidget {
  const ProfileStat({required this.value, required this.label, super.key});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.softText,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class Achievement extends StatelessWidget {
  const Achievement({required this.icon, required this.title, super.key});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 98,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: panelDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.pulse.withValues(alpha: .18),
            child: Icon(icon, color: AppColors.pulse),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.height * 0.0118,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.iconColor = AppColors.cyan,
    super.key,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IconBadge(icon: icon, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                trailing ??
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.muted,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
