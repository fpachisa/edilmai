import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/landing_screen.dart';
import 'screens/enhanced_home_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/create_learner_screen.dart';
import 'screens/user_registration_screen.dart';
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
    print('AuthWrapper: Building AuthWrapper widget at ${DateTime.now()}');
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        print('AuthWrapper: StreamBuilder triggered at ${DateTime.now()}');
        print('AuthWrapper: ConnectionState = ${snapshot.connectionState}');
        print('AuthWrapper: HasError = ${snapshot.hasError}');
        print('AuthWrapper: HasData = ${snapshot.hasData}');
        print('AuthWrapper: User = ${snapshot.data?.uid ?? 'null'}');
        print('AuthWrapper: Data type = ${snapshot.data.runtimeType}');
        print('AuthWrapper: Full user object = ${snapshot.data}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('AuthWrapper: Showing loading screen - waiting for auth state');
          return _buildLoadingScreen(context);
        }
        
        if (snapshot.hasError) {
          print('AuthWrapper: Error - ${snapshot.error}');
          return const LandingScreen();
        }
        
        final user = snapshot.data;
        if (user == null) {
          print('AuthWrapper: No user - showing landing screen');
          return const LandingScreen();
        } else {
          print('AuthWrapper: User authenticated - checking profile for ${user.uid}');
          print('AuthWrapper: About to return ProfileChecker widget');
          return const ProfileChecker();
        }
      },
    );
  }

  Widget _buildLoadingScreen(BuildContext context) {
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
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
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
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading your learning journey...',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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

class ProfileChecker extends StatefulWidget {
  const ProfileChecker({super.key});

  @override
  State<ProfileChecker> createState() => _ProfileCheckerState();
}

class _ProfileCheckerState extends State<ProfileChecker> {
  bool _loading = true;
  bool _hasProfile = false;

  @override
  void initState() {
    super.initState();
    _checkUserProfile();
  }

  Future<void> _checkUserProfile() async {
    try {
      print('ProfileChecker: Starting profile check...');
      final api = ApiClient(kDefaultApiBase);
      final profile = await api.getUserProfile().timeout(Duration(seconds: 10));
      print('ProfileChecker: Profile check succeeded: $profile');
      // If we get here without exception, user has a profile
      setState(() {
        _hasProfile = true;
        _loading = false;
      });
      print('ProfileChecker: Set hasProfile = true');
    } catch (e) {
      // User doesn't have a profile - try to auto-create from Google Sign-In
      print('ProfileChecker: Profile check failed - error: $e');
      print('ProfileChecker: Error type: ${e.runtimeType}');
      print('ProfileChecker: Error details: ${e.toString()}');
      
      // Try to auto-create profile for Google users
      final currentUser = AuthService.currentUser;
      if (currentUser != null && currentUser.displayName != null && currentUser.email != null) {
        print('ProfileChecker: Auto-creating profile for Google user: ${currentUser.displayName}');
        try {
          final api = ApiClient(kDefaultApiBase);
          await api.createUserProfile(
            email: currentUser.email!,
            name: currentUser.displayName!,
            role: 'parent'
          );
          print('ProfileChecker: Auto-created profile successfully');
          // Profile created, user now has profile
          if (mounted) {
            setState(() {
              _hasProfile = true;
              _loading = false;
            });
          }
          return;
        } catch (createError) {
          print('ProfileChecker: Auto-create failed: $createError');
          // Fall through to show registration form
        }
      }
      
      // Auto-create failed or not Google user, show registration form
      if (mounted) {
        setState(() {
          _hasProfile = false;
          _loading = false;
        });
      }
      print('ProfileChecker: Set hasProfile = false - showing registration');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('ProfileChecker: build() called - loading: $_loading, hasProfile: $_hasProfile');
    
    if (_loading) {
      print('ProfileChecker: Showing loading screen');
      return _buildLoadingScreen(context);
    }
    
    if (_hasProfile) {
      print('ProfileChecker: Has profile - showing AppShell');
      return const AppShell();
    } else {
      print('ProfileChecker: No profile - showing UserRegistrationScreen');
      return const UserRegistrationScreen();
    }
  }

  Widget _buildLoadingScreen(BuildContext context) {
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
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Setting up your profile...',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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
