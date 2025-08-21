import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/app_theme.dart';
import 'theme/new_theme.dart';
import 'state/game_state.dart';
import 'config.dart';
import 'auth_service.dart';
import 'auth_wrapper.dart';
import 'screens/auth_screen.dart';
import 'services/firestore_service.dart';

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
    return MaterialApp(
      title: 'PSLE AI Tutor',
      theme: NewAppTheme.light(),
      darkTheme: NewAppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const AuthWrapper(),
      routes: {
        '/auth': (context) => const AuthScreen(),
      },
    );
  }
}
