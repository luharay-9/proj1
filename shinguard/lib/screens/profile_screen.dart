import 'package:flutter/material.dart';

import '../shared/shared_widgets.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScrollView(
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xff214e32), Color(0xff347449)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Row(
            children: [
              PulseAvatar(size: 68),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leo Martinez',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'U14 · #7 · Eagles FC',
                      style: TextStyle(
                        color: AppColors.softText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Row(
          children: [
            Expanded(
              child: ProfileStat(value: '38', label: 'MATCHES'),
            ),
            Expanded(
              child: ProfileStat(value: '12', label: 'GOALS'),
            ),
            Expanded(
              child: ProfileStat(value: '87', label: 'AVG SCORE'),
            ),
          ],
        ),
        const SectionHeader(title: 'Achievements', action: 'View all'),
        SizedBox(
          height: 104,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              Achievement(icon: Icons.emoji_events, title: 'First Goal'),
              Achievement(icon: Icons.bolt, title: 'Speed Demon'),
              Achievement(
                icon: Icons.local_fire_department,
                title: '10 km Day',
              ),
              Achievement(icon: Icons.shield, title: 'Iron Shin'),
            ],
          ),
        ),
        const SectionHeader(title: 'My ShinPulse'),
        const DeviceCard(),
        const SectionHeader(title: 'Settings'),
        const SettingsTile(icon: Icons.groups_rounded, title: 'Team & Coach'),
        const SettingsTile(
          icon: Icons.notifications_rounded,
          title: 'Notifications',
          trailing: Switch(value: true, onChanged: null),
        ),
        const SettingsTile(
          icon: Icons.family_restroom,
          title: 'Parent Dashboard',
        ),
        const SettingsTile(icon: Icons.help_rounded, title: 'Help & Support'),
      ],
    );
  }
}

class DeviceCard extends StatelessWidget {
  const DeviceCard({super.key});

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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ShinPulse Pro',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Connected · Firmware v2.3',
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
            child: const LinearProgressIndicator(
              value: .84,
              minHeight: 8,
              backgroundColor: AppColors.deepInk,
              valueColor: AlwaysStoppedAnimation(AppColors.cyan),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Text(
                'Battery 84%',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              Spacer(),
              Text(
                '18 hrs left',
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
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
    super.key,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconBadge(icon: icon, color: AppColors.cyan),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          trailing ??
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}
