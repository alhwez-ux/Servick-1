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
    ]);
    expect(plansFor(isAdmin: false).map((plan) => plan.priceAmount), [
      20,
      40,
      70,
      120,
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

    expect(find.text('باقات اشتراك العملاء | رابط'), findsOneWidget);
    expect(find.text('باقة المالك الخاصة'), findsNothing);
    expect(find.text('الاشتراك الشهري'), findsOneWidget);
    expect(find.text('اشتراك 3 أشهر'), findsOneWidget);
    expect(find.text('اشتراك 6 أشهر'), findsOneWidget);
    expect(find.text('اشتراك 12 شهراً'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-client-plan')));
    await tester.pump();
    expect(find.text('باقات اشتراك العملاء | رابط'), findsOneWidget);

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
    expect(find.text('باقات اشتراك العملاء | رابط'), findsNothing);
    expect(find.byKey(const Key('client-plan-note')), findsOneWidget);
    expect(find.textContaining('اشتراك 12 شهراً'), findsOneWidget);
    expect(find.textContaining('2027/10/18'), findsOneWidget);
    expect(model.clientSubscription(client.id)?.planId, 'annual');
  });

  testWidgets('the owner preview includes the free package', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final model = AppModel(now: () => DateTime.utc(2026, 10, 23, 12));
    await tester.pumpWidget(ServickApp(model: model));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open-owner-plans')));
    await tester.tap(find.byKey(const Key('open-owner-plans')));
    await tester.pumpAndSettle();

    expect(find.text('باقة المالك الخاصة'), findsOneWidget);
    expect(find.text('0 ريال'), findsNothing);
    expect(find.textContaining('0'), findsWidgets);

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

    expect(find.text('باقات اشتراك العملاء | رابط'), findsNothing);
    expect(model.clientSubscription(demoClientId)?.planId, 'free_admin');
  });
}
