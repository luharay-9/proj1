import 'package:flutter/material.dart';

import '../models/app_data.dart';
import '../theme/app_colors.dart';

class AppScrollView extends StatelessWidget {
  const AppScrollView({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 100),
      children: children,
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({required this.title, this.eyebrow, this.action, super.key});

  final String title;
  final String? eyebrow;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null)
                Text(
                  eyebrow!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, required this.icon, super.key});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.pulse.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.pulse),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.pulse,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class PulseAvatar extends StatelessWidget {
  const PulseAvatar({this.avatar, this.onTap, this.size = 44, super.key});

  final AvatarData? avatar;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        ClipOval(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.panel,
              border: Border.all(color: AppColors.pulse, width: 2),
            ),
            child: avatar?.isPhoto ?? false
                ? Image.network(
                    _versionedPhotoUrl(avatar!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _fallbackIcon(),
                  )
                : _fallbackIcon(),
          ),
        ),
        if (onTap != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * .28,
              height: size * .28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan,
              ),
              child: Icon(
                Icons.edit_rounded,
                color: AppColors.ink,
                size: size * .17,
              ),
            ),
          ),
      ],
    );

    if (onTap == null) {
      return content;
    }

    return Semantics(
      button: true,
      label: 'Choose profile photo',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }

  Widget _fallbackIcon() {
    return Icon(
      avatar?.icon ?? Icons.person_rounded,
      color: AppColors.softText,
      size: size * .52,
    );
  }

  String _versionedPhotoUrl(AvatarData avatar) {
    final separator = avatar.value.contains('?') ? '&' : '?';
    return '${avatar.value}${separator}v=${avatar.revision}';
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.action, super.key});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const Spacer(),
          if (action != null)
            Text(
              action!,
              style: const TextStyle(
                color: AppColors.pulse,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge({required this.icon, required this.color, super.key});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }
}

class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.pulse),
    );
  }
}

class AppMessage extends StatelessWidget {
  const AppMessage({
    required this.title,
    this.detail,
    this.icon = Icons.info_rounded,
    super.key,
  });

  final String title;
  final String? detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.pulse, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyDataPanel extends StatelessWidget {
  const EmptyDataPanel({
    required this.title,
    this.detail,
    this.icon = Icons.inbox_rounded,
    super.key,
  });

  final String title;
  final String? detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.pulse.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.pulse, size: 28),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    detail!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
