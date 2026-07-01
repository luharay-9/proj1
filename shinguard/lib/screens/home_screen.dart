import 'package:flutter/material.dart';

import '../shared/shared_widgets.dart';
import '../theme/app_colors.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScrollView(
      children: [
        const TopBar(
          eyebrow: 'Welcome back',
          title: 'Leo Martinez',
          action: PulseAvatar(),
        ),
        const SizedBox(height: 18),
        const ReadinessCard(),
        const SizedBox(height: 18),
        const Row(
          children: [
            Expanded(
              child: MetricCard(
                icon: Icons.directions_run_rounded,
                label: 'km / week',
                value: '7.2',
                color: AppColors.pulse,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                icon: Icons.speed_rounded,
                label: 'top km/h',
                value: '27.4',
                color: AppColors.cyan,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                icon: Icons.sports_soccer_rounded,
                label: 'touches',
                value: '142',
                color: AppColors.gold,
              ),
            ),
          ],
        ),
        const SectionHeader(title: 'Last Match', action: 'View all'),
        const MatchPreviewCard(),
        const SectionHeader(title: "Today's Tips", action: 'See all'),
        SizedBox(
          height: 170,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              TipCard(
                tag: 'RECOVERY',
                title: '3 stretches to protect your shins after games',
                icon: Icons.self_improvement_rounded,
                color: AppColors.gold,
              ),
              SizedBox(width: 12),
              TipCard(
                tag: 'TECHNIQUE',
                title: 'Land softly: reduce impact force by 30%',
                icon: Icons.sports_soccer_rounded,
                color: AppColors.cyan,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ReadinessCard extends StatelessWidget {
  const ReadinessCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xff234f37), Color(0xff4a9466)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'READINESS TODAY',
                style: TextStyle(
                  color: AppColors.softText,
                  fontSize: 12,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'READY',
                  style: TextStyle(
                    color: AppColors.pulse,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '87',
                style: TextStyle(fontSize: 54, fontWeight: FontWeight.w900),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 11),
                child: Text(
                  '/100',
                  style: TextStyle(
                    color: AppColors.softText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: .82,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: .14),
              valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.flash_on_rounded, color: AppColors.softText, size: 14),
              Text(
                'Recovered well',
                style: TextStyle(
                  color: AppColors.softText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Spacer(),
              Text(
                '82% recovery',
                style: TextStyle(
                  color: AppColors.softText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, color: color),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class MatchPreviewCard extends StatelessWidget {
  const MatchPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xff132918), Color(0xff245035)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            child: StatusPill(label: 'WIN 3-1', icon: Icons.circle),
          ),
          const Positioned(
            right: 0,
            top: 0,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.play_arrow_rounded, color: AppColors.ink),
            ),
          ),
          const Positioned(
            left: 0,
            bottom: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eagles FC vs. Tigers U14',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppColors.softText,
                    ),
                    Text(
                      ' 72 min  ',
                      style: TextStyle(color: AppColors.softText),
                    ),
                    Icon(
                      Icons.route_rounded,
                      size: 14,
                      color: AppColors.softText,
                    ),
                    Text(
                      ' 9.4 km  ',
                      style: TextStyle(color: AppColors.softText),
                    ),
                    Icon(
                      Icons.bolt_rounded,
                      size: 14,
                      color: AppColors.softText,
                    ),
                    Text(
                      ' 18 sprints',
                      style: TextStyle(color: AppColors.softText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TipCard extends StatelessWidget {
  const TipCard({
    required this.tag,
    required this.title,
    required this.icon,
    required this.color,
    super.key,
  });

  final String tag;
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(12),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [Center(child: Icon(icon, size: 42, color: color))],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tag,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, height: 1.1),
          ),
        ],
      ),
    );
  }
}
