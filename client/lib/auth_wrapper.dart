import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/landing_screen.dart';
import 'screens/home_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';
import 'auth_service.dart';
import 'ui/app_theme.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    print('AuthWrapper: Building AuthWrapper widget');
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        print('AuthWrapper: ConnectionState = ${snapshot.connectionState}');
        print('AuthWrapper: HasError = ${snapshot.hasError}');
        print('AuthWrapper: User = ${snapshot.data?.uid ?? 'null'}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('AuthWrapper: Showing loading screen');
          return _buildLoadingScreen();
        }
        
        if (snapshot.hasError) {
          print('AuthWrapper: Error - ${snapshot.error}');
          return const LandingScreen();
        }
        
        final user = snapshot.data;
        if (user == null) {
          print('AuthWrapper: No user - showing landing');
          return const LandingScreen();
        } else {
          print('AuthWrapper: User authenticated - showing app');
          return const AppShell();
        }
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: AnimatedBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.primary,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading your learning journey...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
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

  Future<void> _signOut() async {
    try {
      await AuthService.signOut();
      // Navigation will be handled by the StreamBuilder in AuthWrapper
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final pages = [const HomeScreen(), const ProgressScreen(), const ProfileScreen()];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('PSLE AI Tutor'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  // Navigate to profile or show user info
                  break;
                case 'signout':
                  _signOut();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded),
                    const SizedBox(width: 8),
                    Text(user?.displayName ?? user?.email ?? 'Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primary,
              ),
              child: Center(
                child: Text(
                  _getInitials(user?.displayName ?? user?.email ?? 'U'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0].toUpperCase()}${words[1][0].toUpperCase()}';
    } else {
      return name[0].toUpperCase();
    }
  }
}