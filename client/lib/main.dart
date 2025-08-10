import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/app_theme.dart';
import 'state/game_state.dart';
import 'config.dart';
import 'auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lazy init AuthService inside ApiClient interceptor, but call here to surface failures early
  if (kUseFirebaseAuth) {
    try {
      await AuthService.init();
    } catch (e) {
      // Continue; calls will fail if auth required but not configured
      // ignore: avoid_print
      print('Firebase init error: $e');
    }
  }
  // Load local game state (web localStorage if available)
  try {
    await GameStateController.instance.load();
  } catch (e) {
    // ignore
  }
  runApp(const EdilApp());
}

class EdilApp extends StatelessWidget {
  const EdilApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.theme();
    return MaterialApp(
      title: 'EDIL AI Tutor',
      theme: theme,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [const HomeScreen(), const ProgressScreen(), const ProfileScreen()];
    return Scaffold(
      appBar: AppBar(title: const Text('EDIL AI Tutor')),
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.school_rounded), label: 'Learn'),
          NavigationDestination(icon: Icon(Icons.insights_rounded), label: 'Progress'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
        onDestinationSelected: (i) => setState(() => _tab = i),
      ),
    );
  }
}
