import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/training_session.dart';
import '../shared/shared_widgets.dart';
import '../theme/app_colors.dart';

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

class SessionTimelineScreen extends StatefulWidget {
  const SessionTimelineScreen({super.key});

  @override
  State<SessionTimelineScreen> createState() => _SessionTimelineScreenState();
}
