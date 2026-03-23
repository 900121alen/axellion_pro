import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import './services/supabase_service.dart';
import './widgets/custom_error_widget.dart';
import 'core/app_export.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('CRITICAL ERROR: Failed to initialize Supabase: $e');

    // Launch a fallback error screen instead of the main app
    runApp(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Critical Configuration Error.\nCould not connect to the database.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );

    return; // Abort further execution
  }

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // In debug mode, always show the error widget so developers can fix it
      return CustomErrorWidget(errorDetails: details);
    }

    // In release mode, use the hide-after-delay logic
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 5 seconds to allow error widget on new screens
      Future.delayed(const Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }

    return const SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          title: 'axellion_pro',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.initial,
          // Strip query parameters from route names on Flutter Web
          // (preview environments append ?_cb=... for cache-busting)
          onGenerateRoute: (settings) {
            final rawName = settings.name ?? '/';
            final cleanName = rawName.contains('?')
                ? rawName.substring(0, rawName.indexOf('?'))
                : rawName;
            final builder = AppRoutes.routes[cleanName];
            if (builder != null) {
              return MaterialPageRoute(
                builder: builder,
                settings: RouteSettings(
                  name: cleanName,
                  arguments: settings.arguments,
                ),
              );
            }
            return null;
          },
        );
      },
    );
  }
}
