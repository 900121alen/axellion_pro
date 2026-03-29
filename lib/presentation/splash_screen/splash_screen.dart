import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimController;
  late AnimationController _fadeAnimController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _screenFadeAnimation;

  bool _showRetry = false;
  bool _isInitializing = true;
  double _progress = 0.0;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startInitialization();
  }

  void _setupAnimations() {
    _logoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnimController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnimController, curve: Curves.easeIn),
    );
    _screenFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeAnimController, curve: Curves.easeOut),
    );

    _logoAnimController.forward();
  }

  Future<void> _startInitialization() async {
    // Timeout after 5 seconds — stored so it can be cancelled on dispose
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isInitializing) {
        setState(() => _showRetry = true);
      }
    });

    try {
      // Step 1: Check auth status
      await _updateProgress(0.2, 600);
      // Step 2: Load user preferences
      await _updateProgress(0.45, 500);
      // Step 3: Fetch service categories
      await _updateProgress(0.7, 600);
      // Step 4: Prepare cached data
      await _updateProgress(1.0, 500);

      _timeoutTimer?.cancel();

      if (mounted) {
        setState(() => _isInitializing = false);
        await Future.delayed(const Duration(milliseconds: 400));
        _navigateNext();
      }
    } catch (_) {
      _timeoutTimer?.cancel();
      if (mounted) {
        setState(() => _showRetry = true);
      }
    }
  }

  Future<void> _updateProgress(double target, int ms) async {
    await Future.delayed(Duration(milliseconds: ms));
    if (mounted) setState(() => _progress = target);
  }

  Future<void> _navigateNext() async {
    await _fadeAnimController.forward();
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // User is authenticated — fetch role and route accordingly
      try {
        final userId = session.user.id;
        final response = await Supabase.instance.client
            .from('users')
            .select('role')
            .eq('id', userId)
            .maybeSingle();

        final role = response?['role'] as String?;
        if (role == null || role.isEmpty) {
          debugPrint(
            '[Splash] Role missing for user $userId — redirecting to login',
          );
          throw Exception('Role not found for user $userId');
        }
        debugPrint('[Splash] Fetched role: $role for user $userId');
        _navigateByRole(role);
      } catch (e) {
        debugPrint('[Splash] Auth/role error: $e');
        // Fallback to login on error
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/login-screen');
      }
    } else {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushReplacementNamed('/login-screen');
    }
  }

  void _navigateByRole(String role) {
    switch (role) {
      case 'master':
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/master-dashboard');
        break;
      case 'admin':
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/admin-dashboard');
        break;
      default:
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/client-home');
    }
  }

  void _retryInitialization() {
    _timeoutTimer?.cancel();
    setState(() {
      _showRetry = false;
      _isInitializing = true;
      _progress = 0.0;
    });
    _startInitialization();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _logoAnimController.dispose();
    _fadeAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _screenFadeAnimation,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryLight,
                Color(0xFF1E4D8C),
                AppTheme.secondaryLight,
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  _LogoSection(
                    scaleAnimation: _scaleAnimation,
                    fadeAnimation: _fadeAnimation,
                  ),
                  SizedBox(height: 4.h),
                  _TaglineWidget(fadeAnimation: _fadeAnimation),
                  const Spacer(flex: 2),
                  _showRetry
                      ? _RetryWidget(onRetry: _retryInitialization)
                      : _ProgressWidget(progress: _progress),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  final Animation<double> scaleAnimation;
  final Animation<double> fadeAnimation;

  const _LogoSection({
    required this.scaleAnimation,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: Column(
          children: [
            Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'handyman',
                  color: Colors.white,
                  size: 11.w,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Axellion Pro',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              'Pro Services Platform',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaglineWidget extends StatelessWidget {
  final Animation<double> fadeAnimation;

  const _TaglineWidget({required this.fadeAnimation});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Text(
        'Connecting you with trusted service professionals',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w400,
          color: Colors.white.withValues(alpha: 0.7),
          height: 1.5,
        ),
      ),
    );
  }
}

class _ProgressWidget extends StatelessWidget {
  final double progress;

  const _ProgressWidget({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 50.w,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 3,
            ),
          ),
        ),
        SizedBox(height: 1.5.h),
        Text(
          _getProgressLabel(progress),
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  String _getProgressLabel(double p) {
    if (p < 0.25) return 'Checking authentication...';
    if (p < 0.5) return 'Loading preferences...';
    if (p < 0.75) return 'Fetching service categories...';
    if (p < 1.0) return 'Preparing your experience...';
    return 'Ready!';
  }
}

class _RetryWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const _RetryWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Connection timeout. Please check your network.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        SizedBox(height: 2.h),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          label: const Text('Retry', style: TextStyle(color: Colors.white)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white, width: 1.5),
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.2.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}