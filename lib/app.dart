import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'ui/screens/chat_screen.dart';
import 'ui/screens/charts_screen.dart';
import 'ui/screens/settings_screen.dart';

import 'ui/screens/splash_screen.dart';

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ChatScreen()),
        ),
        GoRoute(
          path: '/charts',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ChartsScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsScreen()),
        ),
      ],
    ),
  ],
);

class MoneyApp extends ConsumerWidget {
  const MoneyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: '記帳小幫手',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child, bottomNavigationBar: const AppBottomNav());
  }
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/charts')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/charts');
            break;
          case 2:
            context.go('/settings');
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.forum_rounded),
          selectedIcon: Icon(Icons.forum_rounded),
          label: '記帳',
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics_rounded),
          selectedIcon: Icon(Icons.analytics_rounded),
          label: '圖表',
        ),
        NavigationDestination(
          icon: Icon(Icons.tune_rounded),
          selectedIcon: Icon(Icons.tune_rounded),
          label: '設定',
        ),
      ],
    );
  }
}
