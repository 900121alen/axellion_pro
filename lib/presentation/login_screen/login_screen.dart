import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import './widgets/login_header_widget.dart';
import './widgets/login_footer_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.length >= 6;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _validateForm() {
    String? emailErr;
    String? passErr;

    if (_emailController.text.trim().isEmpty) {
      emailErr = 'Email is required';
    } else if (!_isValidEmail(_emailController.text.trim())) {
      emailErr = 'Enter a valid email address';
    }
    if (_passwordController.text.isEmpty) {
      passErr = 'Password is required';
    } else if (_passwordController.text.length < 6) {
      passErr = 'Password must be at least 6 characters';
    }

    setState(() {
      _emailError = emailErr;
      _passwordError = passErr;
    });

    return emailErr == null && passErr == null;
  }

  Future<void> _handleLogin() async {
    if (!_validateForm()) {
      if (!kIsWeb) HapticFeedback.lightImpact();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authResponse = await Supabase.instance.client.auth
          .signInWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (authResponse.user == null) {
        throw Exception('Login failed. Please try again.');
      }

      final userId = authResponse.user!.id;
      debugPrint('[Login] ✅ Auth user.id = $userId');

      final userRecord = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      debugPrint('[Login] 📦 public.users row for id=$userId → $userRecord');

      if (userRecord == null) {
        throw Exception(
          'No user profile found for id=$userId. The public.users row may not have been created during sign up.',
        );
      }

      final role = userRecord['role'] as String?;
      debugPrint('[Login] 🎭 Fetched role = $role');

      if (role == null || role.isEmpty) {
        throw Exception(
          'Role is missing in public.users for id=$userId. Cannot determine user type.',
        );
      }

      if (!kIsWeb) HapticFeedback.mediumImpact();

      if (mounted) {
        setState(() => _isLoading = false);
        _navigateByRole(role);
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar(e.message);
      }
    } catch (e) {
      debugPrint('[Login] ❌ Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar(e.toString().replaceAll('Exception: ', ''));
      }
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleForgotPassword() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Supabase.instance.client.auth.resetPasswordForEmail(email);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset link sent to your email.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleSignUp() {
    Navigator.of(context, rootNavigator: true).pushNamed('/sign-up-screen');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 2.h),
                  const LoginHeaderWidget(),
                  SizedBox(height: 4.h),
                  _buildEmailField(theme),
                  SizedBox(height: 2.h),
                  _buildPasswordField(theme),
                  SizedBox(height: 1.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _handleForgotPassword,
                      child: Text(
                        'Forgot Password?',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  _buildLoginButton(theme),
                  SizedBox(height: 3.h),
                  LoginFooterWidget(onSignUp: _handleSignUp),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 0.8.h),
        SizedBox(
          height: 6.h,
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Enter your email',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.5.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _emailError != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _emailError != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _emailError != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        _emailError != null
            ? Padding(
                padding: EdgeInsets.only(top: 0.5.h, left: 1.w),
                child: Text(
                  _emailError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildPasswordField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 0.8.h),
        SizedBox(
          height: 6.h,
          child: TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            enabled: !_isLoading,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleLogin(),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.5.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _passwordError != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _passwordError != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _passwordError != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        _passwordError != null
            ? Padding(
                padding: EdgeInsets.only(top: 0.5.h, left: 1.w),
                child: Text(
                  _passwordError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildLoginButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: ElevatedButton(
        onPressed: (_isFormValid && !_isLoading) ? _handleLogin : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          disabledBackgroundColor: theme.colorScheme.primary.withValues(
            alpha: 0.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : Text(
                'Sign In',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
