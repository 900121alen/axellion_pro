import 'package:flutter/material.dart';
import '../presentation/master_dashboard_screen/master_dashboard_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/sign_up_screen/sign_up_screen.dart';
import '../presentation/profile_screen_logout_integration/profile_screen_logout_integration.dart';
import '../presentation/client_profile/client_profile_screen.dart';
import '../presentation/master_profile/master_profile_screen.dart';
import '../presentation/request_status_tracking/request_status_tracking.dart';
import '../presentation/real_time_messaging/real_time_messaging.dart';
import '../presentation/service_request_creation/service_request_creation.dart';
import '../presentation/client_home/client_home.dart';
import '../presentation/admin_dashboard/admin_dashboard.dart';
import '../presentation/my_requests/my_requests_screen.dart';
import '../presentation/my_leads/my_leads_screen.dart';
import '../presentation/available_leads_screen/available_leads_screen.dart';
import '../presentation/client_messages/client_messages_screen.dart';
import '../presentation/master_messages/master_messages_screen.dart';
import '../presentation/service_categories/service_categories_screen.dart';
import '../presentation/client_request_details/client_request_details_screen.dart';
import '../presentation/lead_details_screen/lead_details_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String login = '/login-screen';
  static const String signUp = '/sign-up-screen';

  // Role-based home routes
  static const String clientHome = '/client-home';
  static const String adminDashboard = '/admin-dashboard';

  // Client sub-routes
  static const String serviceRequestCreation = '/service-request-creation';
  static const String requestStatusTracking = '/request-status-tracking';
  static const String myRequests = '/my-requests';
  static const String clientProfile = '/client-profile';
  static const String clientMessages = '/client-messages';
  static const String serviceCategories = '/service-categories';
  static const String clientRequestDetails = '/client-request-details';

  // Master sub-routes
  static const String masterDashboard = '/master-dashboard';
  static const String availableLeads = '/available-leads';
  static const String myLeads = '/my-leads';
  static const String realTimeMessaging = '/real-time-messaging';
  static const String masterProfile = '/master-profile';
  static const String masterMessages = '/master-messages';
  static const String leadDetails = '/lead-details';

  // Shared (kept for backward compatibility)
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    signUp: (context) => const SignUpScreen(),

    // Role-based homes
    clientHome: (context) => const ClientHome(),
    adminDashboard: (context) => const AdminDashboard(),

    // Client sub-routes
    serviceRequestCreation: (context) => const ServiceRequestCreation(),
    requestStatusTracking: (context) => const RequestStatusTracking(),
    myRequests: (context) => const MyRequestsScreen(),
    clientProfile: (context) => const ClientProfileScreen(),
    clientMessages: (context) => const ClientMessagesScreen(),
    serviceCategories: (context) => const ServiceCategoriesScreen(),
    clientRequestDetails: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      final requestId = (args is Map<String, dynamic>)
          ? args['requestId'] as String? ?? ''
          : args?.toString() ?? '';
      return ClientRequestDetailsScreen(requestId: requestId);
    },

    // Master sub-routes
    masterDashboard: (context) => const MasterDashboardScreen(),
    availableLeads: (context) => const AvailableLeadsScreen(),
    myLeads: (context) => const MyLeadsScreen(),
    realTimeMessaging: (context) => const RealTimeMessaging(),
    masterProfile: (context) => const MasterProfileScreen(),
    masterMessages: (context) => const MasterMessagesScreen(),
    leadDetails: (context) => const LeadDetailsScreen(),

    // Shared (backward compatibility)
    profile: (context) => const ProfileScreenLogoutIntegration(),
  };
}
