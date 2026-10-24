import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servick/app_scope.dart';
import 'package:servick/data/client_plans.dart';
import 'package:servick/main.dart';

import 'support/accounts.dart';

void main() {
  test('an urgent order stays pending for the chosen city', () {
    final now = DateTime.utc(2026, 10, 23, 12);
    final model = AppModel(now: () => now);

    expect(
      model.submitClientOrder(
        clientId: demoClientId,
        clientName: demoClientName,
        categoryId: 'missing',
        city: 'أبها',
        notes: 'صوت',
      ),
      'نوع الخدمة غير معروف',
    );
    expect(
      model.submitClientOrder(
        clientId: demoClientId,
        clientName: demoClientName,
        categoryId: 'diesel_mech',
        city: 'نجران',
        notes: 'صوت',
      ),
      'المدينة غير معروفة',
    );
    expect(model.requests, isEmpty);

    expect(
      model.submitClientOrder(
        clientId: demoClientId,
        clientName: '  $demoClientName  ',
        categoryId: 'diesel_mech',
        city: 'أبها',
        notes: '   ',
      ),
      isNull,
    );

    final order = model.pendingOrdersIn('أبها').first;
    expect(order.id, 'ord-c-1');
    expect(order.clientId, demoClientId);
    expect(order.clientName, demoClientName);
    expect(order.categoryId, 'diesel_mech');
    expect(order.serviceTitle, 'ميكانيكي سيارات ديزل');
    expect(order.notes, 'بدون ملاحظات إضافية');
    expect(order.status, 'pending');
    expect(order.createdAt, now);
    expect(model.pendingOrdersIn('خميس مشيط'), isEmpty);
  });

  testWidgets('sending an order without a specialty stays on the form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final model = AppModel();
    seedClient(model, name: demoClientName, signIn: true);
    await tester.pumpWidget(ServickApp(model: model));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open-client-order')));
    await tester.tap(find.byKey(const Key('open-client-order')));
    await tester.pumpAndSettle();

    expect(find.text('طلب خدمة صيانة عاجلة | Servick'), findsOneWidget);
    expect(find.text('ميكانيكي سيارات بنزين'), findsOneWidget);
    expect(find.text('كهربائي منازل'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('submit-client-order')));
    await tester.tap(find.byKey(const Key('submit-client-order')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text('الرجاء اختيار نوع الخدمة المطلوبة أولاً'),
      findsOneWidget,
    );
    expect(find.text('طلب خدمة صيانة عاجلة | Servick'), findsOneWidget);
  });

  testWidgets(
    'the customer publishes an order and the local craftsman sees it',
    (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final model = AppModel(now: () => DateTime.utc(2026, 10, 23, 12));
      seedClient(model, name: demoClientName, signIn: true);
      seedProvider(
        model,
        name: 'فهد سعيد الشهري',
        phone: '0554102201',
        city: 'خميس مشيط',
        categoryId: 'petrol',
        active: true,
      );
      await tester.pumpWidget(ServickApp(model: model));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('open-client-order')));
      await tester.tap(find.byKey(const Key('open-client-order')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('order-cat-chinese_mech')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('order-notes')),
        'صوت في الجير',
      );
      await tester.ensureVisible(find.byKey(const Key('submit-client-order')));
      await tester.tap(find.byKey(const Key('submit-client-order')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('privacy-checkbox')));
      await tester.tap(find.byKey(const Key('privacy-checkbox')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('accept-privacy')));
      await tester.tap(find.byKey(const Key('accept-privacy')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('تم إرسال طلبك بنجاح'), findsOneWidget);
      expect(
        find.text(
          'تم نشر طلبك إلى أقرب الحرفيين المتاحين في منطقتك. سيتم إشعارك فور قبول الحرفي للطلب وتوجهه إليك.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('order-success-ok')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('open-client-order')), findsOneWidget);

      final published = model.pendingOrdersIn('خميس مشيط').first;
      expect(published.serviceTitle, 'ميكانيكي سيارات صينية');
      expect(published.notes, 'صوت في الجير');
      expect(published.clientName, demoClientName);
      expect(published.status, 'pending');

      await tester.ensureVisible(find.byKey(const Key('open-provider-login')));
      await tester.tap(find.byKey(const Key('open-provider-login')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('provider-phone')),
        '0554102201',
      );
      await tester.enterText(
        find.byKey(const Key('provider-password')),
        fixturePassword,
      );
      await tester.ensureVisible(find.byKey(const Key('provider-privacy')));
      await tester.tap(find.byKey(const Key('provider-privacy')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('provider-login')));
      await tester.tap(find.byKey(const Key('provider-login')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('open-nearby-orders')));
      await tester.tap(find.byKey(const Key('open-nearby-orders')));
      await tester.pumpAndSettle();

      expect(find.text(demoClientName), findsOneWidget);
      expect(find.text('ميكانيكي سيارات صينية'), findsOneWidget);
      expect(find.textContaining('صوت في الجير'), findsOneWidget);
      expect(find.byKey(Key('accept-order-${published.id}')), findsOneWidget);
    },
  );
}
