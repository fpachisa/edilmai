import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ui/app_theme.dart';
import '../auth_service.dart';
import '../auth_wrapper.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {
  
  bool _isSignUp = true;
  bool _loading = false;
  String? _errorMessage;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      print('AuthScreen: Starting Google Sign-in');
      final userCredential = await AuthService.signInWithGoogle();
      print('AuthScreen: Google Sign-in result: ${userCredential?.user?.uid ?? 'null'}');
      if (userCredential?.user != null && mounted) {
        print('AuthScreen: Sign-in successful, setting loading false');
        print('AuthScreen: Current user after sign-in: ${AuthService.currentUser?.uid}');
        
        // Manual navigation since AuthWrapper stream isn't working
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AppShell()),
        );
      }
    } on AuthException catch (e) {
      print('AuthScreen: AuthException - ${e.message}');
      setState(() {
        _errorMessage = e.message;
        _loading = false;
      });
    } catch (e) {
      print('AuthScreen: General exception - $e');
      setState(() {
        _errorMessage = 'Google sign-in failed. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await AuthService.signInWithApple();
      if (userCredential?.user != null && mounted) {
        // Manual navigation since AuthWrapper stream isn't working
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AppShell()),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Apple sign-in failed. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential;
      
      if (_isSignUp) {
        userCredential = await AuthService.createAccountWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          displayName: _nameController.text.isNotEmpty ? _nameController.text.trim() : null,
        );
      } else {
        userCredential = await AuthService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (userCredential.user != null && mounted) {
        // Manual navigation since AuthWrapper stream isn't working
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AppShell()),
        );
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication failed. Please try again.';
        _loading = false;
      });
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    AnimatedBuilder(
                      animation: _fadeController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                _buildSocialSignInButtons(),
                                const SizedBox(height: 32),
                                _buildDivider(),
                                const SizedBox(height: 32),
                                _buildEmailForm(),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  _buildErrorMessage(),
                                ],
                                const SizedBox(height: 32),
                                _buildToggleAuthMode(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    _buildPrivacyNote(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.primary,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.4),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isSignUp ? 'Create Your Account' : 'Welcome Back!',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp 
                    ? 'Start your personalized PSLE Maths journey'
                    : 'Continue your learning adventure',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSocialSignInButtons() {
    return Column(
      children: [
        _SocialSignInButton(
          onTap: _loading ? null : _signInWithGoogle,
          icon: Icons.account_circle,
          label: _isSignUp ? 'Continue with Google' : 'Sign in with Google',
          color: Colors.redAccent,
          loading: _loading,
        ),
        const SizedBox(height: 12),
        if (Theme.of(context).platform == TargetPlatform.iOS)
          _SocialSignInButton(
            onTap: _loading ? null : _signInWithApple,
            icon: Icons.apple,
            label: _isSignUp ? 'Continue with Apple' : 'Sign in with Apple',
            color: Colors.white,
            loading: _loading,
          ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Glass(
      radius: 24,
      child: Column(
        children: [
          if (_isSignUp) ...[
            TextField(
              controller: _nameController,
              enabled: !_loading,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_rounded),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _emailController,
            enabled: !_loading,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_rounded),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            enabled: !_loading,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_rounded),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: AppGradients.primary,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _loading ? null : _signInWithEmail,
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _loading
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          )
                        : Text(
                            _isSignUp ? 'Create Account' : 'Sign In',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Glass(
      radius: 16,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleAuthMode() {
    return TextButton(
      onPressed: _loading ? null : _toggleAuthMode,
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white70),
          children: [
            TextSpan(
              text: _isSignUp 
                  ? 'Already have an account? '
                  : 'Don\'t have an account? ',
            ),
            TextSpan(
              text: _isSignUp ? 'Sign In' : 'Sign Up',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPrivacyNote() {
    return Glass(
      radius: 16,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.security_rounded,
            color: Colors.white.withOpacity(0.7),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your data is secure and will only be used to personalize your learning experience.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialSignInButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final String label;
  final Color color;
  final bool loading;

  const _SocialSignInButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.color,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Glass(
        radius: 28,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: loading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}