import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import './widgets/sign_up_form_widget.dart';
import './widgets/role_selector_widget.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String _selectedRole = 'client';

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.length >= 6 &&
      _confirmPasswordController.text.isNotEmpty;

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _validateForm() {
    String? nameErr;
    String? emailErr;
    String? passErr;
    String? confirmErr;

    if (_nameController.text.trim().isEmpty) {
      nameErr = 'Full name is required';
    }
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
    if (_confirmPasswordController.text.isEmpty) {
      confirmErr = 'Please confirm your password';
    } else if (_confirmPasswordController.text != _passwordController.text) {
      confirmErr = 'Passwords do not match';
    }

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _passwordError = passErr;
      _confirmPasswordError = confirmErr;
    });

    return nameErr == null &&
        emailErr == null &&
        passErr == null &&
        confirmErr == null;
  }

  Future<void> _handleSignUp() async {
    if (!_validateForm()) {
      if (!kIsWeb) HapticFeedback.lightImpact();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final name = _nameController.text.trim();
      final role = _selectedRole;

      debugPrint('[SignUp] 🚀 Starting sign up for email=$email role=$role');

      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Sign up failed. Please try again.');
      }

      final userId = authResponse.user!.id;
      debugPrint('[SignUp] ✅ Auth user created. user.id = $userId');
      debugPrint('[SignUp] 🎭 Selected role before insert: $role');

      // Use upsert to handle cases where a DB trigger may have pre-inserted a row
      // onConflict: 'id' ensures we overwrite any auto-inserted row with the correct role
      await Supabase.instance.client.from('users').upsert({
        'id': userId,
        'email': email,
        'name': name,
        'role': role,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'phone_verified': false,
      }, onConflict: 'id');

      debugPrint('[SignUp] ✅ public.users upserted with id=$userId role=$role');

      // Verify the row was written correctly
      final verifyRecord = await Supabase.instance.client
          .from('users')
          .select('id, role')
          .eq('id', userId)
          .maybeSingle();
      debugPrint('[SignUp] 🔍 Verification read → $verifyRecord');

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
      debugPrint('[SignUp] ❌ Error: $e');
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
        ).pushNamedAndRemoveUntil('/master-dashboard', (route) => false);
        break;
      default:
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamedAndRemoveUntil('/client-home', (route) => false);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Create Account',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 2.h),
                  _buildHeader(theme),
                  SizedBox(height: 3.h),
                  SignUpFormWidget(
                    nameController: _nameController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    isPasswordVisible: _isPasswordVisible,
                    isConfirmPasswordVisible: _isConfirmPasswordVisible,
                    isLoading: _isLoading,
                    nameError: _nameError,
                    emailError: _emailError,
                    passwordError: _passwordError,
                    confirmPasswordError: _confirmPasswordError,
                    onTogglePassword: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                    onToggleConfirmPassword: () => setState(
                      () => _isConfirmPasswordVisible =
                          !_isConfirmPasswordVisible,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 3.h),
                  RoleSelectorWidget(
                    selectedRole: _selectedRole,
                    onRoleChanged: (role) =>
                        setState(() => _selectedRole = role),
                    isLoading: _isLoading,
                  ),
                  SizedBox(height: 3.h),
                  _buildCreateAccountButton(theme),
                  SizedBox(height: 2.h),
                  _buildLoginLink(theme),
                  SizedBox(height: 3.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Join ServicePro',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          'Create your account to get started',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 6.h,
      child: ElevatedButton(
        onPressed: (_isFormValid && !_isLoading) ? _handleSignUp : null,
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
                'Create Account',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        GestureDetector(
          onTap: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Sign In',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
