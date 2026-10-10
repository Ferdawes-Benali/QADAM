import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/strings.dart';
import 'core/theme.dart';
import 'features/feet/feet_screen.dart';
import 'features/glucose/glucose_screen.dart';
import 'features/home/home_screen.dart';
import 'features/learn/learn_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_screen.dart';
import 'state/app_state.dart';

class QadamApp extends StatelessWidget {
  const QadamApp({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return MaterialApp(
      title: 'Qadam',
      debugShowCheckedModeBanner: false,
      theme: QadamTheme.light(),
      // Derja ('aeb') and MSA ('ar') both render right-to-left with Arabic Material labels.
      locale: s.lang == 'fr' ? const Locale('fr') : const Locale('ar'),
      supportedLocales: const [Locale('fr'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: s.profile == null ? const OnboardingScreen() : const MainShell(),
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

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().t;
    final pages = [
      HomeScreen(onOpenTab: (i) => setState(() => _tab = i)),
      const GlucoseScreen(),
      const FeetScreen(),
      const LearnScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_rounded), label: t(K.home)),
          NavigationDestination(icon: const Icon(Icons.water_drop_rounded), label: t(K.glucose)),
          NavigationDestination(icon: const Icon(Icons.directions_walk_rounded), label: t(K.feet)),
          NavigationDestination(icon: const Icon(Icons.school_rounded), label: t(K.learn)),
          NavigationDestination(icon: const Icon(Icons.person_rounded), label: t(K.me)),
        ],
      ),
    );
  }
}
