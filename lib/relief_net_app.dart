import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/session_controller.dart';

class ReliefNetApp extends StatelessWidget {
  const ReliefNetApp({super.key});

  static const brandTeal = Color(0xFF0F766E);
  static const brandDeep = Color(0xFF0B1220);
  static const accent = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    final baseDark = ColorScheme.fromSeed(
      seedColor: brandTeal,
      brightness: Brightness.dark,
    );

    final colorScheme = baseDark.copyWith(
      primary: brandTeal,
      secondary: accent,
      surface: const Color(0xFF111827),
    );

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: brandDeep,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface.withValues(alpha: 0.92),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );

    return AnimatedBuilder(
      animation: SessionController.instance,
      builder: (context, _) {
        final session = SessionController.instance;
        Widget home;
        if (!session.ready) {
          home = Scaffold(
            backgroundColor: brandDeep,
            body: Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            ),
          );
        } else if (session.showLoginGate) {
          home = const LoginScreen();
        } else {
          home = const HomeScreen();
        }

        return MaterialApp(
          title: 'ReliefNet',
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: home,
        );
      },
    );
  }
}
