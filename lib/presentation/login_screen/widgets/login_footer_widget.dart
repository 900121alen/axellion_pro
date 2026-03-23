import 'package:flutter/material.dart';

class LoginFooterWidget extends StatelessWidget {
  final VoidCallback onSignUp;

  const LoginFooterWidget({super.key, required this.onSignUp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'New user? ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        GestureDetector(
          onTap: onSignUp,
          child: Text(
            'Sign Up',
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
