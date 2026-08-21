import 'dart:async';

import 'package:flutter/material.dart';

import '../data/firebase_data_repository.dart';
import '../data/shinguard_ble_service.dart';
import '../models/app_data.dart';
import '../models/match_summary.dart';
import '../models/measurement_system.dart';
import '../services/session_recording_service.dart';
import '../shared/shared_widgets.dart';
import '../theme/app_colors.dart';
import 'avatar_picker_screen.dart';
import 'insights_screen.dart';
import 'session_setup_screen.dart';

class HomeDashboard extends StatelessWidget {
  HomeDashboard({
    required this.onOpenTimeline,
    required this.onOpenStats,
    super.key,
  });

  final FirebaseDataRepository _repository = FirebaseDataRepository();
  final VoidCallback onOpenTimeline;
  final VoidCallback onOpenStats;

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
                  action: PulseAvatar(
                    avatar: data.avatar,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            AvatarPickerScreen(currentAvatar: data.avatar),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ReadinessCard(readiness: data.readiness),
                const SizedBox(height: 18),
                DeviceConnectionPrompt(
                  device: data.device,
                  repository: _repository,
                ),
                const SizedBox(height: 12),
                SessionControlPanel(),
                const SizedBox(height: 18),
                DashboardMetricRow(
                  metrics: data.metrics.take(3).toList(),
                  measurementSystem: data.athleteProfile.measurementSystem,
                ),
                SectionHeader(
                  title: 'Last Match',
                  action: 'View all',
                  onAction: onOpenStats,
                ),
                if (matchSnapshot.connectionState == ConnectionState.waiting)
                  const SizedBox(height: 148, child: AppLoading())
                else if (latestMatch == null)
                  const SizedBox(
                    height: 148,
                    child: EmptyDataPanel(
                      title: 'No matches synced yet',
                      detail: 'Your latest match will appear here.',
                      icon: Icons.sports_soccer_rounded,
                    ),
                  )
                else
                  MatchPreviewCard(
                    match: latestMatch,
                    measurementSystem: data.athleteProfile.measurementSystem,
                    onTap: onOpenTimeline,
                  ),
                SectionHeader(
                  title: "Today's Tips",
                  action: 'See all',
                  onAction: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TipsScreen(tips: data.tips),
                    ),
                  ),
                ),
                SizedBox(
                  height: 170,
                  child: data.tips.isEmpty
                      ? const EmptyDataPanel(
                          title: 'No daily tips yet',
                          detail:
                              'Tips will appear after match data is synced.',
                          icon: Icons.lightbulb_rounded,
                        )
                      : ListView.separated(
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

class SessionControlPanel extends StatelessWidget {
  SessionControlPanel({super.key});

  final SessionRecordingService _recorder = SessionRecordingService.instance;
  final ShinGuardBleService _ble = ShinGuardBleService.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ShinGuardBleState>(
      stream: _ble.states,
      initialData: _ble.currentState,
      builder: (context, bleSnapshot) {
        final connected =
            (bleSnapshot.data ?? _ble.currentState).status ==
            ShinGuardBleStatus.connected;
        return StreamBuilder<SessionRecordingState>(
          stream: _recorder.states,
          initialData: _recorder.currentState,
          builder: (context, sessionSnapshot) {
            final state = sessionSnapshot.data ?? _recorder.currentState;
            final recording = state.isRecording;
            final canRetrySave =
                state.status == SessionRecordingStatus.error &&
                _recorder.hasUnsavedSession;
            final statusColor = state.status == SessionRecordingStatus.error
                ? AppColors.red
                : recording
                ? AppColors.pulse
                : AppColors.cyan;

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: panelDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconBadge(
                        icon: recording
                            ? Icons.sensors_rounded
                            : Icons.play_circle_outline_rounded,
                        color: statusColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recording ? 'Session in progress' : 'New Session',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              state.message,
                              style: TextStyle(
                                color:
                                    state.status == SessionRecordingStatus.error
                                    ? AppColors.red
                                    : AppColors.muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (recording ||
                      state.status == SessionRecordingStatus.saving) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _LiveSessionStat(
                            label: 'ELAPSED',
                            value: _elapsedLabel(state.elapsed),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _LiveSessionStat(
                            label: 'SPRINTS',
                            value: '${state.sprints}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _LiveSessionStat(
                            label: 'BNO SAMPLES',
                            value: '${state.bnoSamples}',
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: state.isBusy
                        ? null
                        : recording
                        ? _recorder.stopSession
                        : canRetrySave
                        ? _recorder.retrySave
                        : connected
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SessionSetupScreen(),
                            ),
                          )
                        : null,
                    icon: state.isBusy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            recording
                                ? Icons.stop_rounded
                                : canRetrySave
                                ? Icons.sync_rounded
                                : Icons.play_arrow_rounded,
                          ),
                    label: Text(
                      state.status == SessionRecordingStatus.starting
                          ? 'Starting...'
                          : state.status == SessionRecordingStatus.saving
                          ? 'Saving...'
                          : recording
                          ? 'Stop Session'
                          : canRetrySave
                          ? 'Retry Save'
                          : 'Start a Session',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: recording
                          ? AppColors.red
                          : AppColors.pulse,
                      foregroundColor: AppColors.ink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  if (!connected && !recording) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Connect the ShinGuard above to enable recording.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _elapsedLabel(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _LiveSessionStat extends StatelessWidget {
  const _LiveSessionStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.deepInk,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class DeviceConnectionPrompt extends StatefulWidget {
  const DeviceConnectionPrompt({
    required this.device,
    required this.repository,
    super.key,
  });

  final DeviceData device;
  final FirebaseDataRepository repository;

  @override
  State<DeviceConnectionPrompt> createState() => _DeviceConnectionPromptState();
}

class _DeviceConnectionPromptState extends State<DeviceConnectionPrompt>
    with WidgetsBindingObserver {
  final _ble = ShinGuardBleService.instance;
  bool _attemptedAutoConnect = false;
  bool _isPersistingDisconnect = false;
  StreamSubscription<ShinGuardBleState>? _bleStateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bleStateSubscription = _ble.states.listen(_persistLiveConnectionState);
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAutoConnect());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bleStateSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_ble.isConnected &&
        widget.device.remoteId.isNotEmpty) {
      _attemptedAutoConnect = false;
      unawaited(_tryAutoConnect());
    }
  }

  @override
  void didUpdateWidget(covariant DeviceConnectionPrompt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device.remoteId != widget.device.remoteId) {
      _attemptedAutoConnect = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryAutoConnect());
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ShinGuardBleState>(
      stream: _ble.states,
      initialData: _ble.currentState,
      builder: (context, snapshot) {
        final bleState = snapshot.data ?? _ble.currentState;
        final isBusy =
            bleState.status == ShinGuardBleStatus.scanning ||
            bleState.status == ShinGuardBleStatus.connecting;
        final connected = bleState.status == ShinGuardBleStatus.connected;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: panelDecoration(),
          child: Row(
            children: [
              IconBadge(
                icon: connected
                    ? Icons.bluetooth_connected_rounded
                    : Icons.bluetooth_searching_rounded,
                color: connected ? AppColors.pulse : AppColors.cyan,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connected
                          ? 'ShinGuard connected'
                          : isBusy
                          ? 'Connecting ShinGuard'
                          : 'Connect ShinGuard',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bleState.message,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: isBusy ? _ble.cancelConnectionAttempt : _connect,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.pulse,
                  foregroundColor: AppColors.ink,
                ),
                child: Text(
                  isBusy
                      ? 'Cancel'
                      : connected
                      ? 'Reconnect'
                      : 'Connect',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _tryAutoConnect() async {
    if (_attemptedAutoConnect || widget.device.remoteId.isEmpty) {
      return;
    }
    _attemptedAutoConnect = true;
    if (!_isPersistingDisconnect) {
      _isPersistingDisconnect = true;
      unawaited(_markDisconnected());
    }
    final connection = await _ble.autoConnect(widget.device.remoteId);
    if (connection != null) {
      await widget.repository.saveDeviceConnection(
        remoteId: connection.remoteId,
        name: connection.name,
      );
    }
  }

  Future<void> _connect() async {
    if (_ble.isConnected) {
      await _ble.disconnect(message: 'Reconnecting...');
    }
    final connection = await _ble.connectToFirstAvailable();
    if (connection != null) {
      await widget.repository.saveDeviceConnection(
        remoteId: connection.remoteId,
        name: connection.name,
      );
    }
  }

  void _persistLiveConnectionState(ShinGuardBleState state) {
    final disconnected =
        state.status == ShinGuardBleStatus.idle ||
        state.status == ShinGuardBleStatus.error;
    if (!disconnected ||
        widget.device.remoteId.isEmpty ||
        _isPersistingDisconnect) {
      return;
    }
    _isPersistingDisconnect = true;
    unawaited(_markDisconnected());
  }

  Future<void> _markDisconnected() async {
    try {
      await widget.repository.markDeviceDisconnected();
    } catch (_) {
      // Live BLE state remains authoritative if Firebase is temporarily offline.
    } finally {
      _isPersistingDisconnect = false;
    }
  }
}

class DashboardMetricRow extends StatelessWidget {
  const DashboardMetricRow({
    required this.metrics,
    this.measurementSystem = MeasurementSystem.metric,
    super.key,
  });

  final List<DashboardMetric> metrics;
  final MeasurementSystem measurementSystem;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const AppMessage(title: 'No dashboard metrics synced yet');
    }

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < metrics.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                icon: metrics[i].icon,
                label: metrics[i].label,
                value: MeasurementFormatter.dashboardMetric(
                  label: metrics[i].label,
                  value: metrics[i].value,
                  system: measurementSystem,
                ),
                color: metrics[i].color,
              ),
            ),
          ],
        ],
      ),
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
              Expanded(
                child: Text(
                  readiness.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.softText,
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                  style: const TextStyle(
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
                style: const TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Text(
                  '/100',
                  style: const TextStyle(
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
              const Icon(
                Icons.flash_on_rounded,
                color: AppColors.softText,
                size: 14,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  readiness.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.softText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (readiness.recoveryLabel.isNotEmpty) ...[
                const SizedBox(width: 10),
                Text(
                  readiness.recoveryLabel,
                  maxLines: 1,
                  style: const TextStyle(
                    color: AppColors.softText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
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
          const Spacer(),
          _MetricValue(value),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _MetricValue extends StatelessWidget {
  const _MetricValue(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final separator = value.indexOf(' ');
    final number = separator < 0 ? value : value.substring(0, separator);
    final unit = separator < 0 ? '' : value.substring(separator + 1);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          text: number,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          children: [
            if (unit.isNotEmpty)
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                  color: AppColors.softText,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}

class MatchPreviewCard extends StatelessWidget {
  const MatchPreviewCard({
    required this.match,
    required this.onTap,
    this.measurementSystem = MeasurementSystem.metric,
    super.key,
  });

  final MatchSummary match;
  final VoidCallback onTap;
  final MeasurementSystem measurementSystem;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open ${match.title} in Timeline',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
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
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton.filled(
                    tooltip: 'Open in Timeline',
                    onPressed: onTap,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.ink,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
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
                              ' ${MeasurementFormatter.distance(match.distance, measurementSystem)}  ',
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
