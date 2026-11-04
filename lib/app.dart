import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/strings.dart';
import 'features/home_screen.dart';
import 'features/onboarding_screen.dart';
import 'state/app_state.dart';

class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    const seed = Color(0xFF1B7F5C);
    return MaterialApp(
      title: S.t('app_title'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: seed,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: state.onboarded ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}
