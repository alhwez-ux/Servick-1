import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'models/client_subscription.dart';
import 'models/models.dart';
import 'models/order.dart';
import 'routes.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_desk_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_review_screen.dart';
import 'screens/admin_service_screen.dart';
import 'screens/booking_screen.dart';
import 'data/shared_store.dart';
import 'screens/client_auth_screen.dart';
import 'screens/client_order_screen.dart';
import 'screens/client_subscription_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/home_screen.dart';
import 'screens/provider_dashboard_screen.dart';
import 'screens/provider_login_screen.dart';
import 'screens/provider_register_screen.dart';
import 'screens/provider_orders_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/provider_subscription_screen.dart';
import 'screens/request_details_screen.dart';
import 'screens/requests_screen.dart';
import 'screens/technician_screen.dart';
import 'screens/technicians_screen.dart';
import 'theme/servick_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final model = AppModel(store: HttpSharedStore());
  try {
    await model.hydrate().timeout(const Duration(seconds: 8));
  } catch (_) {
    model.noteSyncFailure();
  }
  runApp(ServickApp(model: model));
}

class ServickApp extends StatelessWidget {
  const ServickApp({super.key, required this.model});

  final AppModel model;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      model: model,
      child: MaterialApp(
        title: 'سيرفيسك | Servick',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: servickTheme(),
        scrollBehavior: const ServickScrollBehavior(),
        home: const ClientHomeScreen(),
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }
}

Route<void>? _onGenerateRoute(RouteSettings settings) {
  final page = switch (settings.name) {
    ServickRoutes.technicians => TechniciansScreen(
      categoryId: settings.arguments! as String,
    ),
    ServickRoutes.technician => TechnicianScreen(
      technicianId: settings.arguments! as String,
    ),
    ServickRoutes.booking => BookingScreen(
      technicianId: settings.arguments! as String,
    ),
    ServickRoutes.emergency => const EmergencyScreen(),
    ServickRoutes.requests => const RequestsScreen(),
    ServickRoutes.request => _details(settings.arguments! as RequestRouteArgs),
    ServickRoutes.providerLogin => const ProviderLoginScreen(),
    ServickRoutes.providerRegister => const ProviderRegisterScreen(),
    ServickRoutes.providerRenew => ProviderSubscriptionScreen(
      providerId: settings.arguments! as String,
    ),
    ServickRoutes.providerSubscription => ProviderSubscriptionScreen(
      providerId: settings.arguments! as String,
    ),
    ServickRoutes.providerDashboard => const ProviderDashboardScreen(),
    ServickRoutes.providerOrders => _orders(
      settings.arguments! as ProviderOrdersArgs,
    ),
    ServickRoutes.clientAuth => ClientAuthScreen(
      register: settings.arguments is ClientAuthArgs
          ? (settings.arguments! as ClientAuthArgs).register
          : true,
    ),
    ServickRoutes.clientSubscription => _clientPlans(
      settings.arguments! as ClientSubscriptionArgs,
    ),
    ServickRoutes.clientOrder => _clientOrder(
      settings.arguments! as ClientOrderArgs,
    ),
    ServickRoutes.adminLogin => const AdminLoginScreen(),
    ServickRoutes.adminDashboard => const _AdminEntry(),
    ServickRoutes.adminReview => const _AdminReviewEntry(),
    ServickRoutes.adminDesk => const _AdminDeskEntry(),
    ServickRoutes.adminService => const _AdminServiceEntry(),
    ServickRoutes.privacy => const PrivacyPolicyScreen(),
    _ => null,
  };
  if (page == null) return null;
  return PageRouteBuilder<void>(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

Widget _details(RequestRouteArgs args) {
  return RequestDetailsScreen(request: args.request, justSent: args.justSent);
}

Widget _orders(ProviderOrdersArgs args) {
  return ProviderOrdersScreen(
    providerId: args.providerId,
    providerCity: args.providerCity,
  );
}

Widget _clientPlans(ClientSubscriptionArgs args) {
  return ClientSubscriptionScreen(
    clientId: args.clientId,
    isAdmin: args.isAdmin,
  );
}

class _AdminEntry extends StatelessWidget {
  const _AdminEntry();

  @override
  Widget build(BuildContext context) {
    if (!AppScope.of(context).adminUnlocked) return const AdminLoginScreen();
    return const AdminDashboardScreen();
  }
}

class _AdminReviewEntry extends StatelessWidget {
  const _AdminReviewEntry();

  @override
  Widget build(BuildContext context) {
    if (!AppScope.of(context).adminUnlocked) return const AdminLoginScreen();
    return const AdminReviewScreen();
  }
}

class _AdminDeskEntry extends StatelessWidget {
  const _AdminDeskEntry();

  @override
  Widget build(BuildContext context) {
    if (!AppScope.of(context).adminUnlocked) return const AdminLoginScreen();
    return const AdminDeskScreen();
  }
}

class _AdminServiceEntry extends StatelessWidget {
  const _AdminServiceEntry();

  @override
  Widget build(BuildContext context) {
    if (!AppScope.of(context).adminUnlocked) return const AdminLoginScreen();
    return const AdminServiceScreen();
  }
}

Widget _clientOrder(ClientOrderArgs args) {
  return ClientOrderScreen(
    clientId: args.clientId,
    clientName: args.clientName,
  );
}
