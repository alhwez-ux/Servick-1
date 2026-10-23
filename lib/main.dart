import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'models/client_subscription.dart';
import 'models/models.dart';
import 'models/order.dart';
import 'routes.dart';
import 'screens/booking_screen.dart';
import 'screens/client_order_screen.dart';
import 'screens/client_subscription_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/home_screen.dart';
import 'screens/provider_dashboard_screen.dart';
import 'screens/provider_login_screen.dart';
import 'screens/provider_orders_screen.dart';
import 'screens/provider_subscription_screen.dart';
import 'screens/request_details_screen.dart';
import 'screens/requests_screen.dart';
import 'screens/technician_screen.dart';
import 'screens/technicians_screen.dart';
import 'theme/servick_theme.dart';

void main() {
  runApp(ServickApp(model: AppModel()));
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
    ServickRoutes.clientSubscription => _clientPlans(
      settings.arguments! as ClientSubscriptionArgs,
    ),
    ServickRoutes.clientOrder => _clientOrder(
      settings.arguments! as ClientOrderArgs,
    ),
    _ => null,
  };
  if (page == null) return null;
  return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
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

Widget _clientOrder(ClientOrderArgs args) {
  return ClientOrderScreen(
    clientId: args.clientId,
    clientName: args.clientName,
  );
}
