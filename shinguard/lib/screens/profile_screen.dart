import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/firebase_data_repository.dart';
import '../data/shinguard_ble_service.dart';
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
            const SectionHeader(title: 'Athlete Details'),
            AthleteProfileCard(
              profile: data.athleteProfile,
              repository: _repository,
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
            SettingsTile(
              icon: Icons.bluetooth_connected_rounded,
              title: 'Manage Device',
              onTap: () => showModalBottomSheet<void>(
                context: context,
                backgroundColor: AppColors.panel,
                showDragHandle: true,
                builder: (context) => ManageDeviceSheet(
                  device: data.device,
                  repository: _repository,
                ),
              ),
            ),
            const SizedBox(height: 10),
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

class AthleteProfileCard extends StatelessWidget {
  const AthleteProfileCard({
    required this.profile,
    required this.repository,
    super.key,
  });

  final AthleteProfile profile;
  final FirebaseDataRepository repository;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Dominant foot', profile.dominantFoot),
      ('Position', profile.position),
      ('Height', profile.height),
      ('Weight', profile.weight),
      ('Club', profile.club),
      ('Age group', profile.ageGroup),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: panelDecoration(),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.$1,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    row.$2.isEmpty ? 'Not set' : row.$2,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showEditSheet(context),
              child: const Text('Edit details'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      showDragHandle: true,
      builder: (context) =>
          EditAthleteProfileSheet(profile: profile, repository: repository),
    );
  }
}

class EditAthleteProfileSheet extends StatefulWidget {
  const EditAthleteProfileSheet({
    required this.profile,
    required this.repository,
    super.key,
  });

  final AthleteProfile profile;
  final FirebaseDataRepository repository;

  @override
  State<EditAthleteProfileSheet> createState() =>
      _EditAthleteProfileSheetState();
}

class _EditAthleteProfileSheetState extends State<EditAthleteProfileSheet> {
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _clubController;
  late final TextEditingController _ageGroupController;
  late String _dominantFoot;
  late String _position;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dominantFoot = widget.profile.dominantFoot;
    _position = widget.profile.position;
    _heightController = TextEditingController(text: widget.profile.height);
    _weightController = TextEditingController(text: widget.profile.weight);
    _clubController = TextEditingController(text: widget.profile.club);
    _ageGroupController = TextEditingController(text: widget.profile.ageGroup);
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _clubController.dispose();
    _ageGroupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Edit Athlete Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 18),
              _ChoiceRow(
                label: 'Dominant foot',
                value: _dominantFoot,
                options: const ['Right', 'Left', 'Both'],
                onChanged: (value) => setState(() => _dominantFoot = value),
              ),
              _ChoiceRow(
                label: 'Position',
                value: _position,
                options: const ['Forward', 'Midfield', 'Defense', 'Goalkeeper'],
                onChanged: (value) => setState(() => _position = value),
              ),
              _ProfileField(label: 'Height', controller: _heightController),
              _ProfileField(label: 'Weight', controller: _weightController),
              _ProfileField(label: 'Club', controller: _clubController),
              _ProfileField(
                label: 'Age group',
                controller: _ageGroupController,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.pulse,
                  foregroundColor: AppColors.ink,
                ),
                child: Text(_isSaving ? 'Saving...' : 'Save details'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await widget.repository.updateAthleteProfile({
      'dominantFoot': _dominantFoot,
      'position': _position,
      'height': _heightController.text.trim(),
      'weight': _weightController.text.trim(),
      'club': _clubController.text.trim(),
      'ageGroup': _ageGroupController.text.trim(),
    });
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final selected = value == option;
              return ChoiceChip(
                selected: selected,
                label: Text(option),
                selectedColor: AppColors.pulse,
                backgroundColor: AppColors.deepInk,
                labelStyle: TextStyle(
                  color: selected ? AppColors.ink : AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
                onSelected: (_) => onChanged(option),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.deepInk,
        ),
      ),
    );
  }
}

class ManageDeviceSheet extends StatefulWidget {
  const ManageDeviceSheet({
    required this.device,
    required this.repository,
    super.key,
  });

  final DeviceData device;
  final FirebaseDataRepository repository;

  @override
  State<ManageDeviceSheet> createState() => _ManageDeviceSheetState();
}

class _ManageDeviceSheetState extends State<ManageDeviceSheet> {
  final _ble = ShinGuardBleService.instance;
  bool _isWorking = false;

  @override
  Widget build(BuildContext context) {
    final hasDevice = widget.device.remoteId.isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: StreamBuilder<ShinGuardBleState>(
          stream: _ble.states,
          initialData: _ble.currentState,
          builder: (context, snapshot) {
            final state = snapshot.data ?? _ble.currentState;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Manage Device',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text(
                  hasDevice
                      ? '${widget.device.name} · ${widget.device.status}'
                      : 'No ShinGuard is paired yet.',
                  style: const TextStyle(
                    color: AppColors.softText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _isWorking ? null : _connect,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.pulse,
                    foregroundColor: AppColors.ink,
                  ),
                  child: Text(hasDevice ? 'Reconnect device' : 'Pair device'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _isWorking || !hasDevice ? null : _remove,
                  child: const Text('Remove device'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _connect() async {
    setState(() => _isWorking = true);
    final connection = await _ble.connectToFirstAvailable();
    if (connection != null) {
      await widget.repository.saveDeviceConnection(
        remoteId: connection.remoteId,
        name: connection.name,
      );
    }
    if (mounted) {
      setState(() => _isWorking = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _isWorking = true);
    await _ble.disconnect();
    await widget.repository.removeDevice();
    if (mounted) {
      Navigator.of(context).pop();
    }
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
