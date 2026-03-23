import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class LoginFormWidget extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final bool isPasswordVisible;
  final bool isLoading;
  final String? phoneError;
  final String? passwordError;
  final VoidCallback onTogglePassword;
  final VoidCallback onForgotPassword;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onPasswordChanged;

  const LoginFormWidget({
    super.key,
    required this.phoneController,
    required this.passwordController,
    required this.formKey,
    required this.isPasswordVisible,
    required this.isLoading,
    this.phoneError,
    this.passwordError,
    required this.onTogglePassword,
    required this.onForgotPassword,
    required this.onPhoneChanged,
    required this.onPasswordChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhoneField(theme, context),
          SizedBox(height: 2.h),
          _buildPasswordField(theme, context),
          SizedBox(height: 1.h),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : onForgotPassword,
              child: Text(
                'Forgot Password?',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField(ThemeData theme, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 0.8.h),
        Row(
          children: [
            Container(
              height: 6.h,
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor,
                border: Border.all(
                  color: phoneError != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🇮🇳', style: TextStyle(fontSize: 14.sp)),
                  SizedBox(width: 1.w),
                  Text(
                    '+91',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: SizedBox(
                height: 6.h,
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  enabled: !isLoading,
                  onChanged: onPhoneChanged,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.5.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: phoneError != null
                            ? theme.colorScheme.error
                            : theme.colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: phoneError != null
                            ? theme.colorScheme.error
                            : theme.colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: phoneError != null
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        phoneError != null
            ? Padding(
                padding: EdgeInsets.only(top: 0.5.h, left: 1.w),
                child: Text(
                  phoneError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildPasswordField(ThemeData theme, BuildContext context) {
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
            controller: passwordController,
            obscureText: !isPasswordVisible,
            enabled: !isLoading,
            onChanged: onPasswordChanged,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Enter password',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.5.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: passwordError != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: passwordError != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: passwordError != null
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
              suffixIcon: IconButton(
                onPressed: onTogglePassword,
                icon: CustomIconWidget(
                  iconName: isPasswordVisible ? 'visibility_off' : 'visibility',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        passwordError != null
            ? Padding(
                padding: EdgeInsets.only(top: 0.5.h, left: 1.w),
                child: Text(
                  passwordError!,
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
