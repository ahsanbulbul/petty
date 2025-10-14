import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

// ThemeMode provider
final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

class PettyApp extends ConsumerWidget {
  const PettyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Petty - Pet App',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: const LoginScreen(),
    );
  }
}
