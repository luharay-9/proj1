import 'package:flutter/material.dart';

import '../models/app_data.dart';
import '../shared/shared_widgets.dart';
import '../theme/app_colors.dart';

class TipsScreen extends StatelessWidget {
  const TipsScreen({required this.tips, super.key});

  final List<TipData> tips;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Tips")),
      body: tips.isEmpty
          ? const EmptyDataPanel(
              title: 'No daily tips yet',
              detail: 'Tips will appear after match data is synced.',
              icon: Icons.lightbulb_rounded,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
              itemCount: tips.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final tip = tips[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: panelDecoration(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconBadge(icon: tip.icon, color: tip.color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tip.tag,
                              style: TextStyle(
                                color: tip.color,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tip.title,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({required this.achievements, super.key});

  final List<AchievementData> achievements;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: achievements.isEmpty
          ? const EmptyDataPanel(
              title: 'No achievements unlocked yet',
              detail: 'New achievements will appear here.',
              icon: Icons.emoji_events_rounded,
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: panelDecoration(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.pulse.withValues(alpha: .16),
                        child: Icon(achievement.icon, color: AppColors.pulse),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        achievement.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
