import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servick/app_scope.dart';
import 'package:servick/models/models.dart';
import 'package:servick/models/provider.dart';
import 'package:servick/routes.dart';

Future<void> openOwnerLogin(WidgetTester tester) async {
  tester
      .state<NavigatorState>(find.byType(Navigator))
      .pushNamed(ServickRoutes.adminLogin);
  await tester.pumpAndSettle();
}

const fixturePassword = '123456';

ProviderAccount seedProvider(
  AppModel model, {
  required String name,
  required String phone,
  required String city,
  required String categoryId,
  bool active = false,
}) {
  final error = model.registerProvider(
    name: name,
    phone: phone,
    city: city,
    categoryId: categoryId,
    password: fixturePassword,
  );
  expect(error, isNull, reason: error);
  if (active) {
    final created = model.providerByPhone(phone)!;
    expect(model.activateProviderSubscription(created.id), isNull);
  }
  return model.providerByPhone(phone)!;
}

ClientAccount seedClient(
  AppModel model, {
  String name = 'سارة القحطاني',
  String phone = '0551234567',
  String city = 'خميس مشيط',
  bool signIn = false,
}) {
  final error = model.registerClient(
    name: name,
    phone: phone,
    city: city,
    password: fixturePassword,
  );
  expect(error, isNull, reason: error);
  if (signIn) {
    expect(model.loginClient(phone: phone, password: fixturePassword), isNull);
  }
  return model.clientByPhone(phone)!;
}
