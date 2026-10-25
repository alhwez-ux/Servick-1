import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servick/app_scope.dart';
import 'package:servick/data/admin.dart';
import 'package:servick/main.dart';
import 'package:servick/routes.dart';

Future<void> _openLogin(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(ServickApp(model: AppModel()));
  await tester.pumpAndSettle();
  expect(find.text('دخول مالك التطبيق'), findsNothing);
  tester
      .state<NavigatorState>(find.byType(Navigator))
      .pushNamed(ServickRoutes.adminLogin);
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester, String passcode) async {
  await tester.enterText(find.byKey(const Key('admin-passcode')), passcode);
  await tester.tap(find.byKey(const Key('admin-login')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

void main() {
  test('the owner gate starts locked', () {
    final model = AppModel();
    expect(model.adminUnlocked, isFalse);
    model.unlockAdmin();
    expect(model.adminUnlocked, isTrue);
  });

  testWidgets('an empty passcode stays on the owner login', (tester) async {
    await _openLogin(tester);
    expect(find.text('دخول مالك التطبيق | رابط'), findsOneWidget);
    expect(find.text('منطقة الإدارة العليا'), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-login')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('الرجاء إدخال الرقم السري الخاص بالمالك'), findsOneWidget);
    expect(find.text('دخول مالك التطبيق | رابط'), findsOneWidget);
  });

  testWidgets('a wrong passcode stays on the owner login', (tester) async {
    await _openLogin(tester);
    await _submit(tester, '0000');
    await tester.pump();

    expect(find.text('الرقم السري غير صحيح، حاول مرة أخرى'), findsOneWidget);
    expect(find.text('دخول مالك التطبيق | رابط'), findsOneWidget);
    expect(find.text('لوحة تحكم المالك | رابط'), findsNothing);

    await _submit(tester, demoAdminPasscode);
    await tester.pumpAndSettle();
    expect(find.text('لوحة تحكم المالك | رابط'), findsOneWidget);
    expect(find.text('الرقم السري غير صحيح، حاول مرة أخرى'), findsNothing);
  });

  testWidgets(
    'the demo passcode opens the owner dashboard and replaces login',
    (tester) async {
      await _openLogin(tester);
      await _submit(tester, demoAdminPasscode);
      await tester.pumpAndSettle();

      expect(find.text('لوحة تحكم المالك | رابط'), findsOneWidget);
      expect(find.text('دخول مالك التطبيق | رابط'), findsNothing);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('open-admin-login')), findsOneWidget);
      expect(find.text('دخول مالك التطبيق | رابط'), findsNothing);
    },
  );

  testWidgets('opening the dashboard route without the passcode shows login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ServickApp(model: AppModel()));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed(ServickRoutes.adminDashboard);
    await tester.pumpAndSettle();

    expect(find.text('دخول مالك التطبيق | رابط'), findsOneWidget);
    expect(find.text('لوحة تحكم المالك | رابط'), findsNothing);
  });
}
