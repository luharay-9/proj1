import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screens/care_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/timeline_screen.dart';
import 'screens/verify_email_screen.dart';
import 'data/firebase_data_repository.dart';
import 'data/shinguard_ble_service.dart';
import 'models/app_data.dart';
import 'shared/shared_widgets.dart';
import 'theme/app_colors.dart';

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
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _repository = FirebaseDataRepository();
  String? _directoryUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: AppLoading());
        }

        final user = snapshot.data;
        if (user != null && user.emailVerified) {
          return StreamBuilder<UserAppData>(
            stream: _repository.watchUserData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: AppLoading());
              }

              final data = userSnapshot.data;
              if (data == null || !data.onboardingComplete) {
                return const KeyedSubtree(
                  key: ValueKey('onboarding-screen'),
                  child: OnboardingScreen(),
                );
              }

              if (_directoryUid != user.uid) {
                _directoryUid = user.uid;
                unawaited(
                  _repository.ensureCurrentUsernameDirectory().catchError(
                    (_) {},
                  ),
                );
              }

              return const KeyedSubtree(
                key: ValueKey('authenticated-shell'),
                child: ShinPulseShell(),
              );
            },
          );
        }

        if (user != null) {
          return KeyedSubtree(
            key: const ValueKey('verify-email-screen'),
            child: VerifyEmailScreen(
              user: user,
              onVerified: () => setState(() {}),
            ),
          );
        }

        return const KeyedSubtree(
          key: ValueKey('login-screen'),
          child: LoginScreen(),
        );
      },
    );
  }
}

class ShinPulseShell extends StatefulWidget {
  const ShinPulseShell({super.key});

  @override
  State<ShinPulseShell> createState() => _ShinPulseShellState();
}

class _ShinPulseShellState extends State<ShinPulseShell>
    with WidgetsBindingObserver {
  int _tabIndex = 0;
  final _ble = ShinGuardBleService.instance;
  final _repository = FirebaseDataRepository();
  Timer? _backgroundDisconnectTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _backgroundDisconnectTimer?.cancel();
      _backgroundDisconnectTimer = null;
      return;
    }
    if (state == AppLifecycleState.detached) {
      _backgroundDisconnectTimer?.cancel();
      unawaited(_disconnectForInactiveApp());
      return;
    }
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundDisconnectTimer?.cancel();
      _backgroundDisconnectTimer = Timer(
        const Duration(seconds: 8),
        () => unawaited(_disconnectForInactiveApp()),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundDisconnectTimer?.cancel();
    unawaited(_disconnectForInactiveApp());
    super.dispose();
  }

  Future<void> _disconnectForInactiveApp() async {
    await _ble.disconnect(message: 'App inactive; device disconnected');
    try {
      await _repository.markDeviceDisconnected();
    } catch (_) {
      // Logout can remove the authenticated user before shell disposal.
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeDashboard(),
      const SessionTimelineScreen(),
      const PerformanceScreen(),
      const CareScreen(),
      ProfileScreen(),
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
