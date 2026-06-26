import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const ShinPulseApp());
}

class ShinPulseApp extends StatelessWidget {
  const ShinPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShinPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.ink,
        fontFamily: 'Avenir',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.pulse,
          secondary: AppColors.cyan,
          surface: AppColors.panel,
        ),
      ),
      home: const ShinPulseShell(),
    );
  }
}

class ShinPulseShell extends StatefulWidget {
  const ShinPulseShell({super.key});

  @override
  State<ShinPulseShell> createState() => _ShinPulseShellState();
}

class _ShinPulseShellState extends State<ShinPulseShell> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeDashboard(),
      const SessionTimelineScreen(),
      const PerformanceScreen(),
      const CareScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _tabIndex, children: pages),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.deepInk,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: NavigationBar(
          height: 74,
          selectedIndex: _tabIndex,
          backgroundColor: Colors.transparent,
          indicatorColor: AppColors.pulse.withValues(alpha: .16),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) => setState(() => _tabIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_rounded),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.pulse),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.timeline_rounded),
              selectedIcon: Icon(
                Icons.timeline_rounded,
                color: AppColors.pulse,
              ),
              label: 'Timeline',
            ),
            NavigationDestination(
              icon: Icon(Icons.insert_chart_outlined_rounded),
              selectedIcon: Icon(
                Icons.insert_chart_rounded,
                color: AppColors.pulse,
              ),
              label: 'Stats',
            ),
            NavigationDestination(
              icon: Icon(Icons.health_and_safety_rounded),
              selectedIcon: Icon(
                Icons.health_and_safety_rounded,
                color: AppColors.pulse,
              ),
              label: 'Care',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.pulse),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

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

class SessionTimelineScreen extends StatefulWidget {
  const SessionTimelineScreen({super.key});

  @override
  State<SessionTimelineScreen> createState() => _SessionTimelineScreenState();
}

class _SessionTimelineScreenState extends State<SessionTimelineScreen> {
  int selectedSession = 0;

  @override
  Widget build(BuildContext context) {
    final session = sessions[selectedSession];
    return AppScrollView(
      children: [
        const TopBar(
          eyebrow: 'Selected session',
          title: 'Timeline',
          action: StatusPill(label: 'SYNCED', icon: Icons.sensors_rounded),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final item = sessions[index];
              final selected = selectedSession == index;
              return ChoiceChip(
                selected: selected,
                showCheckmark: false,
                label: Text(item.shortName),
                avatar: Icon(
                  item.typeIcon,
                  size: 16,
                  color: selected ? AppColors.ink : AppColors.muted,
                ),
                selectedColor: AppColors.pulse,
                backgroundColor: AppColors.panel,
                labelStyle: TextStyle(
                  color: selected ? AppColors.ink : AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
                side: BorderSide.none,
                onSelected: (_) => setState(() => selectedSession = index),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemCount: sessions.length,
          ),
        ),
        const SizedBox(height: 12),
        TimelineHero(session: session),
        const SizedBox(height: 18),
        Text(
          'Recorded Events',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        SessionTimeline(session: session),
      ],
    );
  }
}

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  int rangeIndex = 2;

  @override
  Widget build(BuildContext context) {
    return AppScrollView(
      children: [
        const TopBar(eyebrow: 'Past year · 46 sessions', title: 'Performance'),
        const SizedBox(height: 18),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Week')),
            ButtonSegment(value: 1, label: Text('Month')),
            ButtonSegment(value: 2, label: Text('Year')),
          ],
          selected: {rangeIndex},
          showSelectedIcon: false,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.pulse
                  : AppColors.panel,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.ink
                  : AppColors.muted,
            ),
            side: const WidgetStatePropertyAll(BorderSide.none),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          onSelectionChanged: (value) {
            setState(() => rangeIndex = value.first);
          },
        ),
        const SizedBox(height: 18),
        const TrendCard(
          title: 'DISTANCE RUN',
          value: '641.8',
          unit: 'km',
          delta: '+22%',
          points: [18, 25, 28, 36, 44, 41, 47, 50, 49, 56, 62, 68],
        ),
        const SizedBox(height: 20),
        const SectionTitle('Sprint Zones'),
        const SprintZonesCard(),
        const SizedBox(height: 20),
        const SectionTitle('Year History'),
        const SizedBox(height: 10),
        ...yearSessions.map((match) => HistoryCard(match: match)),
      ],
    );
  }
}

class CareScreen extends StatelessWidget {
  const CareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const risks = [
      BodyRisk('R Shin', 8, AppColors.red),
      BodyRisk('R Calf', 7, AppColors.gold),
      BodyRisk('L Shin', 4, AppColors.cyan),
      BodyRisk('L Calf', 3, AppColors.pulse),
    ];

    return AppScrollView(
      children: [
        const TopBar(
          eyebrow: 'AI-powered prevention insights',
          title: 'Injury Care',
        ),
        const SizedBox(height: 18),
        const RiskScoreCard(),
        const SectionHeader(title: 'Body Load Map'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: panelDecoration(),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 240,
                  child: CustomPaint(painter: BodyMapPainter(risks)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: Column(
                  children: risks
                      .map(
                        (risk) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: RiskRow(risk: risk),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Risk scale: 1 completely fine · 10 high injury risk',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SectionHeader(title: 'Recommended Care'),
        const CareAction(
          icon: Icons.ac_unit_rounded,
          title: 'Ice right shin 15 min',
          subtitle: 'Within next hour',
          color: AppColors.cyan,
        ),
        const CareAction(
          icon: Icons.spa_rounded,
          title: 'Calf stretch routine',
          subtitle: '5 min · 4 exercises',
          color: AppColors.violet,
        ),
        const CareAction(
          icon: Icons.hotel_rounded,
          title: 'Reduce training tomorrow',
          subtitle: 'Light technical work only',
          color: AppColors.pulse,
        ),
      ],
    );
  }
}

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
  const PulseAvatar({this.size = 44, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.panel,
            border: Border.all(color: AppColors.pulse, width: 2),
          ),
          child: Icon(
            Icons.person_rounded,
            color: AppColors.softText,
            size: size * .52,
          ),
        ),
        Positioned(
          right: 1,
          top: 2,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.red,
            ),
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
          const Positioned.fill(child: SoccerPattern(opacity: .18)),
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
                children: [
                  const Positioned.fill(child: SoccerPattern(opacity: .12)),
                  Center(child: Icon(icon, size: 42, color: color)),
                ],
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

class TimelineHero extends StatelessWidget {
  const TimelineHero({required this.session, super.key});

  final TrainingSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xff712724), Color(0xffa33a36)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(label: session.result, icon: Icons.circle),
              const Spacer(),
              Text(
                session.durationLabel,
                style: const TextStyle(
                  color: AppColors.pulse,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            session.title,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          Text(
            '${session.date} · ${session.position}',
            style: const TextStyle(
              color: AppColors.softText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: MiniSessionStat(
                  value: '${session.topSpeed}',
                  label: 'Top Speed',
                  unit: 'km/h',
                  icon: Icons.speed_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MiniSessionStat(
                  value: '${session.sprints}',
                  label: 'Sprints',
                  unit: '',
                  icon: Icons.directions_run_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MiniSessionStat(
                  value: '${session.kicks}',
                  label: 'Kicks',
                  unit: '',
                  icon: Icons.sports_soccer_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MiniSessionStat extends StatelessWidget {
  const MiniSessionStat({
    required this.value,
    required this.label,
    required this.unit,
    required this.icon,
    super.key,
  });

  final String value;
  final String label;
  final String unit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.softText),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: unit.isEmpty ? '' : ' $unit',
                  style: const TextStyle(
                    color: AppColors.softText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.softText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class SessionTimeline extends StatelessWidget {
  const SessionTimeline({required this.session, super.key});

  final TrainingSession session;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: session.events.map((event) {
        final isLast = event == session.events.last;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 54,
              child: Text(
                event.time,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: event.color.withValues(alpha: .18),
                    shape: BoxShape.circle,
                    border: Border.all(color: event.color, width: 2),
                  ),
                  child: Icon(event.icon, size: 17, color: event.color),
                ),
                if (!isLast)
                  Container(width: 2, height: 64, color: AppColors.line),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 14),
                padding: const EdgeInsets.all(14),
                decoration: panelDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          event.value,
                          style: TextStyle(
                            color: event.color,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      event.detail,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class TrendCard extends StatelessWidget {
  const TrendCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.delta,
    required this.points,
    super.key,
  });

  final String title;
  final String value;
  final String unit;
  final String delta;
  final List<double> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178,
      padding: const EdgeInsets.all(18),
      decoration: panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.muted,
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
                  color: AppColors.pulse.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  delta,
                  style: const TextStyle(
                    color: AppColors.pulse,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    color: AppColors.softText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 64,
            child: CustomPaint(
              painter: LineChartPainter(points),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class SprintZonesCard extends StatelessWidget {
  const SprintZonesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: panelDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 112,
            height: 112,
            child: CustomPaint(
              painter: DonutPainter(),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '240',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'SPRINTS',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              children: [
                LegendRow(color: AppColors.pulse, label: 'Low', value: '128'),
                LegendRow(color: AppColors.gold, label: 'Medium', value: '82'),
                LegendRow(color: AppColors.red, label: 'High', value: '30'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LegendRow extends StatelessWidget {
  const LegendRow({
    required this.color,
    required this.label,
    required this.value,
    super.key,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class HistoryCard extends StatelessWidget {
  const HistoryCard({required this.match, super.key});

  final MatchSummary match;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [match.color.withValues(alpha: .58), AppColors.panel],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(label: match.result, icon: Icons.circle),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  match.score,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Text(
            match.title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '${match.date} · ${match.minutes} min · ${match.position}',
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              HistoryMetric(value: match.distance, label: 'Distance'),
              HistoryMetric(value: match.speed, label: 'Top Speed'),
              HistoryMetric(value: '${match.sprints}', label: 'Sprints'),
              HistoryMetric(value: '${match.scoreValue}', label: 'Score'),
            ],
          ),
        ],
      ),
    );
  }
}

class HistoryMetric extends StatelessWidget {
  const HistoryMetric({required this.value, required this.label, super.key});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class RiskScoreCard extends StatelessWidget {
  const RiskScoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xff643519), Color(0xff8d4b22)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: CustomPaint(
              painter: RingPainter(.56, AppColors.gold),
              child: const Center(
                child: Text(
                  '6',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RISK SCORE',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Moderate',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Right shin loading is above baseline. Active recovery recommended for 24h.',
                  style: TextStyle(
                    color: AppColors.softText,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
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

class RiskRow extends StatelessWidget {
  const RiskRow({required this.risk, super.key});

  final BodyRisk risk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.deepInk.withValues(alpha: .34),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: risk.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              risk.label,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            '${risk.score}/10',
            style: TextStyle(color: risk.color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class CareAction extends StatelessWidget {
  const CareAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: panelDecoration(),
      child: Row(
        children: [
          IconBadge(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.pulse),
        ],
      ),
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

class SoccerPattern extends StatelessWidget {
  const SoccerPattern({required this.opacity, super.key});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: SoccerPatternPainter(opacity));
  }
}

class RingPainter extends CustomPainter {
  RingPainter(this.progress, this.color);

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * .1;
    final rect = Offset.zero & size;
    final base = Paint()
      ..color = Colors.white.withValues(alpha: .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final active = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect.deflate(stroke),
      -math.pi / 2,
      math.pi * 2,
      false,
      base,
    );
    canvas.drawArc(
      rect.deflate(stroke),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class BodyMapPainter extends CustomPainter {
  BodyMapPainter(this.risks);

  final List<BodyRisk> risks;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = const Color(0xff2f3c62)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = const Color(0xff202846)
      ..style = PaintingStyle.fill;
    final center = size.width / 2;

    canvas.drawCircle(Offset(center, 28), 15, fill);
    canvas.drawCircle(Offset(center, 28), 15, stroke);

    final torso = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(center, 82), width: 48, height: 78),
      const Radius.circular(18),
    );
    canvas.drawRRect(torso, fill);
    canvas.drawRRect(torso, stroke);

    canvas.drawLine(Offset(center - 27, 58), Offset(center - 40, 132), stroke);
    canvas.drawLine(Offset(center + 27, 58), Offset(center + 40, 132), stroke);
    canvas.drawLine(Offset(center - 14, 121), Offset(center - 17, 184), stroke);
    canvas.drawLine(Offset(center + 14, 121), Offset(center + 17, 184), stroke);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center - 17, 198), width: 22, height: 9),
      stroke,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center + 17, 198), width: 22, height: 9),
      stroke,
    );

    for (final risk in risks) {
      final isRight = risk.label.startsWith('R');
      final isShin = risk.label.contains('Shin');
      final x = center + (isRight ? 17 : -17);
      final y = isShin ? 156 : 130;
      final bar = Paint()
        ..color = risk.color.withValues(alpha: .75)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, y - 15), Offset(x, y + 15), bar);
    }
  }

  @override
  bool shouldRepaint(covariant BodyMapPainter oldDelegate) {
    return oldDelegate.risks != risks;
  }
}

class LineChartPainter extends CustomPainter {
  LineChartPainter(this.points);

  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    final minValue = points.reduce(math.min);
    final maxValue = points.reduce(math.max);
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i / (points.length - 1) * size.width;
      final normalized = (points[i] - minValue) / (maxValue - minValue);
      final y = size.height - normalized * size.height * .82 - 6;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x775fe781), Color(0x005fe781)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.pulse
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class DonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.butt;
    final segments = [
      (AppColors.pulse, .53),
      (AppColors.gold, .34),
      (AppColors.red, .13),
    ];
    var start = -math.pi / 2;
    for (final segment in segments) {
      paint.color = segment.$1;
      final sweep = math.pi * 2 * segment.$2;
      canvas.drawArc(rect.deflate(12), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SoccerPatternPainter extends CustomPainter {
  SoccerPatternPainter(this.opacity);

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = -1; i < 5; i++) {
      canvas.drawCircle(
        Offset(size.width * (.2 + i * .22), size.height * .52),
        30,
        paint,
      );
      canvas.drawLine(
        Offset(size.width * (.1 + i * .22), size.height * .1),
        Offset(size.width * (.26 + i * .22), size.height * .9),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SoccerPatternPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}

BoxDecoration panelDecoration() {
  return BoxDecoration(
    color: AppColors.panel,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppColors.line),
  );
}

class TrainingSession {
  const TrainingSession({
    required this.shortName,
    required this.title,
    required this.date,
    required this.position,
    required this.durationLabel,
    required this.result,
    required this.topSpeed,
    required this.sprints,
    required this.kicks,
    required this.typeIcon,
    required this.events,
  });

  final String shortName;
  final String title;
  final String date;
  final String position;
  final String durationLabel;
  final String result;
  final double topSpeed;
  final int sprints;
  final int kicks;
  final IconData typeIcon;
  final List<TimelineEvent> events;
}

class TimelineEvent {
  const TimelineEvent({
    required this.time,
    required this.title,
    required this.detail,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String time;
  final String title;
  final String detail;
  final String value;
  final IconData icon;
  final Color color;
}

class BodyRisk {
  const BodyRisk(this.label, this.score, this.color);

  final String label;
  final int score;
  final Color color;
}

class MatchSummary {
  const MatchSummary({
    required this.title,
    required this.date,
    required this.minutes,
    required this.position,
    required this.result,
    required this.score,
    required this.distance,
    required this.speed,
    required this.sprints,
    required this.scoreValue,
    required this.color,
  });

  final String title;
  final String date;
  final int minutes;
  final String position;
  final String result;
  final String score;
  final String distance;
  final String speed;
  final int sprints;
  final int scoreValue;
  final Color color;
}

const sessions = [
  TrainingSession(
    shortName: 'Tigers',
    title: 'Eagles FC vs. Tigers U14',
    date: 'May 19, 2026',
    position: 'Right Mid',
    durationLabel: '72:00',
    result: 'WIN 3-1',
    topSpeed: 27.4,
    sprints: 18,
    kicks: 42,
    typeIcon: Icons.sports_soccer_rounded,
    events: [
      TimelineEvent(
        time: '03:12',
        title: 'Opening sprint',
        detail: 'Acceleration burst down right wing',
        value: '24.8 km/h',
        icon: Icons.directions_run_rounded,
        color: AppColors.pulse,
      ),
      TimelineEvent(
        time: '17:45',
        title: 'Shot on target',
        detail: 'Right-foot strike from edge of box',
        value: '61 mph',
        icon: Icons.sports_soccer_rounded,
        color: AppColors.gold,
      ),
      TimelineEvent(
        time: '34:09',
        title: 'High impact landing',
        detail: 'Right shin load peaked above baseline',
        value: '8/10',
        icon: Icons.warning_rounded,
        color: AppColors.red,
      ),
      TimelineEvent(
        time: '51:26',
        title: 'Fastest sprint',
        detail: 'Counterattack recovery run',
        value: '27.4 km/h',
        icon: Icons.speed_rounded,
        color: AppColors.cyan,
      ),
      TimelineEvent(
        time: '68:31',
        title: 'Final third pass',
        detail: 'One-touch assist chance created',
        value: '1 key pass',
        icon: Icons.timeline_rounded,
        color: AppColors.violet,
      ),
    ],
  ),
  TrainingSession(
    shortName: 'Wolves',
    title: 'Eagles FC vs. Wolves U14',
    date: 'May 12, 2026',
    position: 'Right Mid',
    durationLabel: '68:00',
    result: 'DRAW 2-2',
    topSpeed: 25.8,
    sprints: 15,
    kicks: 36,
    typeIcon: Icons.shield_rounded,
    events: [
      TimelineEvent(
        time: '08:18',
        title: 'First pressure run',
        detail: 'Closed down opposing fullback',
        value: '21.2 km/h',
        icon: Icons.directions_run_rounded,
        color: AppColors.pulse,
      ),
      TimelineEvent(
        time: '22:04',
        title: 'Long pass',
        detail: 'Driven ball into attacking channel',
        value: '39 mph',
        icon: Icons.sports_soccer_rounded,
        color: AppColors.gold,
      ),
      TimelineEvent(
        time: '43:30',
        title: 'Agility cut',
        detail: 'Sharp change of direction under load',
        value: '0.72 sec',
        icon: Icons.swap_calls_rounded,
        color: AppColors.cyan,
      ),
      TimelineEvent(
        time: '63:11',
        title: 'Recovery flag',
        detail: 'AI detected right calf fatigue trend',
        value: '7/10',
        icon: Icons.health_and_safety_rounded,
        color: AppColors.red,
      ),
    ],
  ),
  TrainingSession(
    shortName: 'Drills',
    title: 'Technical Training Block',
    date: 'Apr 30, 2026',
    position: 'Speed + Touch',
    durationLabel: '46:00',
    result: 'DRILL',
    topSpeed: 24.1,
    sprints: 22,
    kicks: 84,
    typeIcon: Icons.fitness_center_rounded,
    events: [
      TimelineEvent(
        time: '05:00',
        title: 'Cone sprint set',
        detail: 'Six short accelerations recorded',
        value: '6 sprints',
        icon: Icons.directions_run_rounded,
        color: AppColors.pulse,
      ),
      TimelineEvent(
        time: '18:20',
        title: 'Kick power block',
        detail: 'Average strike speed improved',
        value: '+8%',
        icon: Icons.sports_soccer_rounded,
        color: AppColors.gold,
      ),
      TimelineEvent(
        time: '36:48',
        title: 'Asymmetry check',
        detail: 'Left-right load returned to normal range',
        value: '3/10',
        icon: Icons.balance_rounded,
        color: AppColors.pulse,
      ),
    ],
  ),
];

const yearSessions = [
  MatchSummary(
    title: 'Eagles FC vs. Tigers U14',
    date: 'May 19, 2026',
    minutes: 72,
    position: 'Right Mid',
    result: 'WIN',
    score: '3 - 1',
    distance: '9.4 km',
    speed: '27.4',
    sprints: 18,
    scoreValue: 85,
    color: Color(0xff306b42),
  ),
  MatchSummary(
    title: 'Eagles FC vs. Wolves U14',
    date: 'May 12, 2026',
    minutes: 68,
    position: 'Right Mid',
    result: 'DRAW',
    score: '2 - 2',
    distance: '8.7 km',
    speed: '25.8',
    sprints: 15,
    scoreValue: 78,
    color: Color(0xffc8df45),
  ),
  MatchSummary(
    title: 'Eagles FC vs. Hawks U14',
    date: 'Apr 28, 2026',
    minutes: 75,
    position: 'Right Mid',
    result: 'LOSS',
    score: '1 - 2',
    distance: '10.1 km',
    speed: '28.2',
    sprints: 22,
    scoreValue: 82,
    color: Color(0xff6d9d35),
  ),
  MatchSummary(
    title: 'Eagles FC training combine',
    date: 'Mar 21, 2026',
    minutes: 54,
    position: 'Agility',
    result: 'DRILL',
    score: 'A',
    distance: '5.6 km',
    speed: '26.1',
    sprints: 31,
    scoreValue: 91,
    color: Color(0xff218f8b),
  ),
  MatchSummary(
    title: 'Winter futsal session',
    date: 'Jan 10, 2026',
    minutes: 42,
    position: 'Touch',
    result: 'DRILL',
    score: 'A-',
    distance: '4.2 km',
    speed: '23.7',
    sprints: 12,
    scoreValue: 88,
    color: Color(0xff7254b6),
  ),
  MatchSummary(
    title: 'Eagles FC vs. Stars U14',
    date: 'Sep 14, 2025',
    minutes: 70,
    position: 'Right Mid',
    result: 'WIN',
    score: '2 - 0',
    distance: '8.9 km',
    speed: '26.9',
    sprints: 19,
    scoreValue: 84,
    color: Color(0xff3e7a4d),
  ),
];

class AppColors {
  static const ink = Color(0xff07110c);
  static const deepInk = Color(0xff050d09);
  static const panel = Color(0xff122619);
  static const line = Color(0xff1f3728);
  static const text = Color(0xfff2fff5);
  static const softText = Color(0xffb7cbbb);
  static const muted = Color(0xff718174);
  static const pulse = Color(0xff74e285);
  static const cyan = Color(0xff66d8e5);
  static const gold = Color(0xffffc84f);
  static const red = Color(0xffff6f66);
  static const violet = Color(0xffa77cff);
}
