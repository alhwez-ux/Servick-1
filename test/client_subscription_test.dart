import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servick/app_scope.dart';
import 'package:servick/data/client_plans.dart';
import 'package:servick/main.dart';

import 'support/accounts.dart';

void main() {
  test('client plans hide the owner package and expiry follows the months', () {
    final now = DateTime.utc(2026, 10, 23, 12);
    final model = AppModel(now: () => now);

    expect(plansFor(isAdmin: false).map((plan) => plan.id), [
      'monthly',
      'quarterly',
      'semi_annual',
      'annual',
      'provider_annual',
    ]);
    expect(plansFor(isAdmin: false).map((plan) => plan.priceAmount), [
      20,
      40,
      70,
      120,
      100,
    ]);
    expect(plansFor(isAdmin: true).first.id, 'free_admin');

    expect(
      model.subscribeClient(
        clientId: 'client-demo',
        planId: 'missing',
        months: 1,
      ),
      'الباقة غير معروفة',
    );

    expect(
      model.subscribeClient(
        clientId: 'client-demo',
        planId: 'monthly',
        months: 1,
      ),
      isNull,
    );
    final monthly = model.clientSubscription('client-demo')!;
    expect(monthly.status, 'active');
    expect(monthly.planId, 'monthly');
    expect(monthly.expiry, now.add(const Duration(days: 30)));
    expect(monthly.isActiveAt(now), isTrue);

    model.subscribeClient(
      clientId: 'client-demo',
      planId: 'annual',
      months: 12,
    );
    expect(
      model.clientSubscription('client-demo')!.expiry,
      now.add(const Duration(days: 360)),
    );

    model.subscribeClient(
      clientId: 'client-demo',
      planId: 'free_admin',
      months: 0,
    );
    expect(
      model.clientSubscription('client-demo')!.expiry,
      now.add(const Duration(days: 3650)),
    );
  });

  testWidgets('a customer activates the yearly plan and returns home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final model = AppModel(now: () => DateTime.utc(2026, 10, 23, 12));
    final client = seedClient(model, signIn: true);
    await tester.pumpWidget(ServickApp(model: model));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('open-client-plans')));
    await tester.tap(find.byKey(const Key('open-client-plans')));
    await tester.pumpAndSettle();

    expect(find.text('اشتراك العملاء | رابط'), findsOneWidget);
    expect(find.text('باقة المالك الخاصة'), findsNothing);
    expect(find.text('الاشتراك الشهري'), findsOneWidget);
    expect(find.text('اشتراك 3 أشهر'), findsOneWidget);
    expect(find.text('اشتراك 6 أشهر'), findsOneWidget);
    expect(find.text('اشتراك 12 شهراً'), findsOneWidget);
    expect(find.text('باقة مزودي الخدمة'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-client-plan')));
    await tester.pump();
    expect(find.text('اشتراك العملاء | رابط'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('plan-annual')));
    await tester.tap(find.byKey(const Key('plan-annual')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('confirm-client-plan')));
    await tester.tap(find.byKey(const Key('confirm-client-plan')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('privacy-checkbox')));
    await tester.tap(find.byKey(const Key('privacy-checkbox')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('accept-privacy')));
    await tester.tap(find.byKey(const Key('accept-privacy')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(
      find.text('تم تفعيل باقتك بنجاح في رابط! مرحباً بك.'),
      findsOneWidget,
    );
    expect(find.text('اشتراك العملاء | رابط'), findsNothing);
    expect(find.byKey(const Key('client-plan-note')), findsOneWidget);
    expect(find.textContaining('اشتراك 12 شهراً'), findsOneWidget);
    expect(find.textContaining('2027/10/18'), findsOneWidget);
    expect(model.clientSubscription(client.id)?.planId, 'annual');
  });

  testWidgets('subscription packages stay public and hide the owner plan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final model = AppModel(now: () => DateTime.utc(2026, 10, 23, 12));
    await tester.pumpWidget(ServickApp(model: model));
    await tester.pumpAndSettle();

    expect(find.text('دخول مالك التطبيق'), findsNothing);
    expect(find.text('اشتراك العملاء'), findsOneWidget);
    expect(find.text('باقات الاشتراك'), findsOneWidget);
    expect(find.byKey(const Key('plans-avatar')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('open-owner-plans')));
    await tester.tap(find.byKey(const Key('open-owner-plans')));
    await tester.pumpAndSettle();

    expect(find.text('باقات الاشتراك | رابط'), findsOneWidget);
    expect(find.text('باقة مزودي الخدمة'), findsOneWidget);
    expect(find.textContaining('عام كامل'), findsOneWidget);
    expect(find.text('باقة المالك الخاصة'), findsNothing);
    expect(find.byKey(const Key('owner-plan-client')), findsNothing);
  });

  testWidgets('the owner assigns the private plan to a chosen client', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 980);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final model = AppModel(now: () => DateTime.utc(2026, 10, 23, 12));
    final client = seedClient(model, name: 'نورة الشهري');
    model.unlockAdmin();
    await tester.pumpWidget(ServickApp(model: model));
    await tester.pumpAndSettle();

    expect(find.text('دخول مالك التطبيق'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('open-owner-plans')));
    await tester.tap(find.byKey(const Key('open-owner-plans')));
    await tester.pumpAndSettle();

    expect(find.text('باقة المالك الخاصة'), findsOneWidget);
    expect(find.text('باقة مزودي الخدمة'), findsOneWidget);
    await tester.tap(find.byKey(const Key('owner-plan-client')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('نورة الشهري · خميس مشيط').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('plan-free_admin')));
    await tester.tap(find.byKey(const Key('plan-free_admin')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('confirm-client-plan')));
    await tester.tap(find.byKey(const Key('confirm-client-plan')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('privacy-checkbox')));
    await tester.tap(find.byKey(const Key('privacy-checkbox')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('accept-privacy')));
    await tester.tap(find.byKey(const Key('accept-privacy')));
    await tester.pumpAndSettle();

    expect(find.text('تم تخصيص الباقة للعميل.'), findsOneWidget);
    expect(model.clientSubscription(client.id)?.planId, 'free_admin');
    expect(model.clientSubscription(demoClientId), isNull);
  });

  testWidgets('client registration has no guidance above the form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ServickApp(model: AppModel()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open-client-register')));
    await tester.tap(find.byKey(const Key('open-client-register')));
    await tester.pumpAndSettle();

    expect(find.text('إنشاء حساب عميل'), findsOneWidget);
    expect(
      find.textContaining('الحساب يُحفظ على الويب ويظهر من أي جهاز تدخل منه'),
      findsNothing,
    );
    expect(find.byKey(const Key('client-name')), findsOneWidget);
  });
}
