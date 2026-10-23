import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'models/models.dart';
import 'routes.dart';
import 'screens/booking_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/home_screen.dart';
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
    _ => null,
  };
  if (page == null) return null;
  return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
}

Widget _details(RequestRouteArgs args) {
  return RequestDetailsScreen(request: args.request, justSent: args.justSent);
}
