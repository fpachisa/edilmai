import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/landing_screen.dart';
import 'screens/enhanced_home_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/create_learner_screen.dart';
import 'auth_service.dart';
import 'ui/app_theme.dart';
import 'state/app_mode.dart';
import 'state/active_learner.dart';
import 'api_client.dart';
import 'config.dart';

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
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _bootstrapLearner();
  }

  Future<void> _bootstrapLearner() async {
    // If we already have an active learner, nothing to do
    if (ActiveLearner.instance.id != null) {
      setState(() => _initialized = true);
      return;
    }
    try {
      final api = ApiClient(kDefaultApiBase);
      final learners = await api.listLearners();
      if (!mounted) return;
      if (learners.isEmpty) {
        // Route to create learner, then continue
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateLearnerScreen()));
      } else {
        final first = learners.first as Map<String, dynamic>;
        ActiveLearner.instance.setActive(id: first['learner_id'] as String, name: (first['name'] as String?) ?? 'Your Learner');
      }
    } catch (_) {
      // If call fails, allow app to continue; Home will show errors as needed
    } finally {
      if (mounted) setState(() => _initialized = true);
    }
  }

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
    final pages = [const EnhancedHomeScreen(), const ProgressScreen(), const ProfileScreen()];
    
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator())) ;
    }
    return AnimatedBuilder(
      animation: AppModeController.instance,
      builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: Text(
          AppModeController.instance.isLearner ? 'PSLE AI Tutor — Learner' : 'PSLE AI Tutor — Parent',
        ),
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
                case 'switch_mode':
                  final toParent = AppModeController.instance.isLearner;
                  AppModeController.instance.toggle();
                  setState(() {
                    _tab = toParent ? 1 : 0; // Parent→Progress, Learner→Learn
                  });
                  break;
                case 'create_learner':
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateLearnerScreen()));
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
              PopupMenuItem(
                value: 'switch_mode',
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded),
                    const SizedBox(width: 8),
                    Text(AppModeController.instance.isLearner ? 'Switch to Parent Mode' : 'Switch to Learner Mode'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'create_learner',
                child: Row(
                  children: [
                    Icon(Icons.person_add_alt_1_rounded),
                    SizedBox(width: 8),
                    Text("Add Child's Account"),
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
    ));
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
