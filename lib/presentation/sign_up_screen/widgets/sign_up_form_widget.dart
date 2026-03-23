import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

class SignUpFormWidget extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final bool isLoading;
  final String? nameError;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final ValueChanged<String> onChanged;

  const SignUpFormWidget({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isPasswordVisible,
    required this.isConfirmPasswordVisible,
    required this.isLoading,
    this.nameError,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildField(
          theme,
          label: 'Full Name',
          controller: nameController,
          hint: 'Enter your full name',
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          error: nameError,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: 2.h),
        _buildField(
          theme,
          label: 'Email Address',
          controller: emailController,
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          error: emailError,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: 2.h),
        _buildPasswordField(
          theme,
          label: 'Password',
          controller: passwordController,
          hint: 'Create a password (min 6 chars)',
          isVisible: isPasswordVisible,
          onToggle: onTogglePassword,
          error: passwordError,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: 2.h),
        _buildPasswordField(
          theme,
          label: 'Confirm Password',
          controller: confirmPasswordController,
          hint: 'Re-enter your password',
          isVisible: isConfirmPasswordVisible,
          onToggle: onToggleConfirmPassword,
          error: confirmPasswordError,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildField(
    ThemeData theme, {
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? error,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 0.8.h),
        SizedBox(
          height: 6.h,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            enabled: !isLoading,
            onChanged: onChanged,
            textInputAction: textInputAction,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.5.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: error != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: error != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: error != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        error != null
            ? Padding(
                padding: EdgeInsets.only(top: 0.5.h, left: 1.w),
                child: Text(
                  error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildPasswordField(
    ThemeData theme, {
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
    String? error,
    TextInputAction textInputAction = TextInputAction.done,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 0.8.h),
        SizedBox(
          height: 6.h,
          child: TextField(
            controller: controller,
            obscureText: !isVisible,
            enabled: !isLoading,
            onChanged: onChanged,
            textInputAction: textInputAction,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.5.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: error != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: error != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: error != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
              suffixIcon: IconButton(
                onPressed: onToggle,
                icon: CustomIconWidget(
                  iconName: isVisible ? 'visibility_off' : 'visibility',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        error != null
            ? Padding(
                padding: EdgeInsets.only(top: 0.5.h, left: 1.w),
                child: Text(
                  error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
