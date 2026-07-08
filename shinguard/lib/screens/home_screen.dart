import 'package:flutter/material.dart';

import '../data/firebase_data_repository.dart';
import '../models/app_data.dart';
import '../models/match_summary.dart';
import '../shared/shared_widgets.dart';
import '../theme/app_colors.dart';

class HomeDashboard extends StatelessWidget {
  HomeDashboard({super.key});

  final FirebaseDataRepository _repository = FirebaseDataRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserAppData>(
      stream: _repository.watchUserData(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const AppLoading();
        }
        if (userSnapshot.hasError) {
          return const AppMessage(
            title: 'Dashboard unavailable',
            detail: 'Check your Firebase permissions and user document.',
            icon: Icons.cloud_off_rounded,
          );
        }
        final data = userSnapshot.data;
        if (data == null) {
          return const AppMessage(title: 'No dashboard data yet');
        }

        return StreamBuilder<List<MatchSummary>>(
          stream: _repository.watchMatches(),
          builder: (context, matchSnapshot) {
            final matches = matchSnapshot.data ?? const <MatchSummary>[];
            final latestMatch = matches.isEmpty ? null : matches.first;
            return AppScrollView(
              children: [
                TopBar(
                  eyebrow: 'Welcome back',
                  title: data.displayName,
                  action: const PulseAvatar(),
                ),
                const SizedBox(height: 18),
                ReadinessCard(readiness: data.readiness),
                const SizedBox(height: 18),
                _MetricRow(metrics: data.metrics.take(3).toList()),
                const SectionHeader(title: 'Last Match', action: 'View all'),
                if (matchSnapshot.connectionState == ConnectionState.waiting)
                  const SizedBox(height: 148, child: AppLoading())
                else if (latestMatch == null)
                  const SizedBox(
                    height: 148,
                    child: AppMessage(title: 'No matches synced yet'),
                  )
                else
                  MatchPreviewCard(match: latestMatch),
                const SectionHeader(title: "Today's Tips", action: 'See all'),
                SizedBox(
                  height: 170,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: data.tips.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final tip = data.tips[index];
                      return TipCard(
                        tag: tip.tag,
                        title: tip.title,
                        icon: tip.icon,
                        color: tip.color,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.metrics});

  final List<DashboardMetric> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const AppMessage(title: 'No dashboard metrics synced yet');
    }

    return Row(
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: MetricCard(
              icon: metrics[i].icon,
              label: metrics[i].label,
              value: metrics[i].value,
              color: metrics[i].color,
            ),
          ),
        ],
      ],
    );
  }
}

class ReadinessCard extends StatelessWidget {
  const ReadinessCard({required this.readiness, super.key});

  final ReadinessData readiness;

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
              Text(
                readiness.label,
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
                child: Text(
                  readiness.status,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${readiness.score}',
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
              value: readiness.progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: .14),
              valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.flash_on_rounded, color: AppColors.softText, size: 14),
              Text(
                readiness.detail,
                style: TextStyle(
                  color: AppColors.softText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Spacer(),
              Text(
                readiness.recoveryLabel,
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
  const MatchPreviewCard({required this.match, super.key});

  final MatchSummary match;

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
          Positioned(
            top: 0,
            left: 0,
            child: StatusPill(
              label: [
                match.result,
                match.score,
              ].where((item) => item.isNotEmpty).join(' '),
              icon: Icons.circle,
            ),
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
          Positioned(
            left: 0,
            bottom: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.title,
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
                      ' ${match.minutes} min  ',
                      style: TextStyle(color: AppColors.softText),
                    ),
                    Icon(
                      Icons.route_rounded,
                      size: 14,
                      color: AppColors.softText,
                    ),
                    Text(
                      ' ${match.distance}  ',
                      style: TextStyle(color: AppColors.softText),
                    ),
                    Icon(
                      Icons.bolt_rounded,
                      size: 14,
                      color: AppColors.softText,
                    ),
                    Text(
                      ' ${match.sprints} sprints',
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
