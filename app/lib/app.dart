import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'features/assistant/assistant_screen.dart';
import 'features/feet/feet_screen.dart';
import 'features/glucose/glucose_screen.dart';
import 'features/home/home_screen.dart';
import 'features/lock/lock_screen.dart';
import 'features/more/more_screen.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'state/app_state.dart';

class QadamApp extends StatefulWidget {
  const QadamApp({super.key});
  @override
  State<QadamApp> createState() => _QadamAppState();
}

class _QadamAppState extends State<QadamApp> {
  late final AppLifecycleListener _life;
  DateTime? _pausedAt;
  final _nav = GlobalKey<NavigatorState>();
  Phase? _shownPhase;

  @override
  void initState() {
    super.initState();
    // Privacy: the app locks itself after 5 minutes in the background.
    _life = AppLifecycleListener(
      onPause: () => _pausedAt = DateTime.now(),
      onResume: () {
        final s = context.read<AppState>();
        if (_pausedAt != null && DateTime.now().difference(_pausedAt!).inMinutes >= 5 && s.phase == Phase.ready) {
          s.lockNow();
        }
        _pausedAt = null;
      },
    );
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    // Lock / erase swap the home screen; screens pushed on top of it (settings, results, dialogs) must go too,
    // otherwise they stay visible above the lock screen.
    if (_shownPhase != null && _shownPhase != s.phase) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _nav.currentState?.popUntil((r) => r.isFirst));
    }
    _shownPhase = s.phase;
    return MaterialApp(
      navigatorKey: _nav,
      title: 'Qadam',
      debugShowCheckedModeBanner: false,
      theme: QadamTheme.light(),
      // Derja ('aeb') and Modern Standard Arabic ('ar') both use Arabic Material labels and right-to-left layout.
      locale: s.lang == 'fr' ? const Locale('fr') : const Locale('ar'),
      supportedLocales: const [Locale('fr'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: switch (s.phase) {
        Phase.onboarding => const OnboardingFlow(),
        Phase.locked => const LockScreen(),
        Phase.ready => const MainShell(),
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  void _go(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pages = [
      HomeScreen(onOpenTab: _go),
      const FeetScreen(),
      const GlucoseScreen(),
      const AssistantScreen(),
      const MoreScreen(),
    ];
    final openAlerts = s.hubAlerts.where((a) => a.status != 'dismissed' && a.level == 'red').length;
    return Scaffold(
      body: SafeArea(bottom: false, child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _go,
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: s.t('nav.home')),
          NavigationDestination(
              icon: const Icon(Icons.directions_walk_rounded), label: s.t('nav.feet')),
          NavigationDestination(
              icon: const Icon(Icons.water_drop_outlined), selectedIcon: const Icon(Icons.water_drop_rounded), label: s.t('nav.glucose')),
          NavigationDestination(
              icon: const Icon(Icons.forum_outlined), selectedIcon: const Icon(Icons.forum_rounded), label: s.t('nav.assistant')),
          NavigationDestination(
              icon: Badge(isLabelVisible: openAlerts > 0, label: Text('$openAlerts'), child: const Icon(Icons.menu_rounded)),
              label: s.t('nav.more')),
        ],
      ),
    );
  }
}
