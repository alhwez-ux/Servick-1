import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servick/app_scope.dart';
import 'package:servick/main.dart';

import 'support/accounts.dart';
import 'package:servick/models/models.dart';

Future<AppModel> _openNearby(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final model = AppModel(now: () => DateTime.utc(2026, 10, 23, 12));
  seedProvider(
    model,
    name: 'فهد سعيد الشهري',
    phone: '0554102201',
    city: 'خميس مشيط',
    categoryId: 'petrol',
    active: true,
  );
  model.submitClientOrder(
    clientId: 'client-a',
    clientName: 'أبو محمد',
    categoryId: 'benz_mech',
    city: 'خميس مشيط',
    notes: 'صوت',
  );
  model.submitClientOrder(
    clientId: 'client-b',
    clientName: 'أم سارة',
    categoryId: 'car_electric',
    city: 'خميس مشيط',
    notes: 'بطارية',
  );
  await tester.pumpWidget(ServickApp(model: model));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('open-provider-login')));
  await tester.tap(find.byKey(const Key('open-provider-login')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('provider-phone')), '0554102201');
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
  return model;
}

void main() {
  test('pending orders stay inside the craftsman city until accepted', () {
    final model = AppModel(now: () => DateTime.utc(2026, 10, 23, 12));
    final provider = seedProvider(
      model,
      name: 'فهد سعيد الشهري',
      phone: '0554102201',
      city: 'خميس مشيط',
      categoryId: 'petrol',
      active: true,
    );
    model.submitClientOrder(
      clientId: 'client-a',
      clientName: 'أبو محمد',
      categoryId: 'benz_mech',
      city: 'خميس مشيط',
      notes: 'صوت',
    );
    model.submitClientOrder(
      clientId: 'client-b',
      clientName: 'أم سارة',
      categoryId: 'car_electric',
      city: 'خميس مشيط',
      notes: 'بطارية',
    );
    model.submitClientOrder(
      clientId: 'client-c',
      clientName: 'أبو فيصل',
      categoryId: 'diesel_mech',
      city: 'أبها',
      notes: 'دخان',
    );
    model.submitClientOrder(
      clientId: 'client-d',
      clientName: 'أبو ناصر',
      categoryId: 'home_electric',
      city: 'أحد رفيدة',
      notes: 'قاطع',
    );
    final khamis = model.pendingOrdersIn('خميس مشيط').toList();
    expect(khamis.map((order) => order.clientName), ['أم سارة', 'أبو محمد']);
    expect(model.pendingOrdersIn('أبها').single.clientName, 'أبو فيصل');
    expect(
      model.pendingOrdersIn('أحد رفيدة').single.serviceTitle,
      'كهربائي منازل',
    );

    final firstId = khamis.last.id;
    final secondId = khamis.first.id;
    expect(
      model.acceptOrder(orderId: firstId, providerId: provider.id),
      isNull,
    );
    expect(model.pendingOrdersIn('خميس مشيط').map((order) => order.id), [
      secondId,
    ]);
    expect(
      model.acceptOrder(orderId: firstId, providerId: provider.id),
      'هذا الطلب لم يعد متاحاً',
    );
    expect(model.pendingOrdersIn('أبها').single.clientName, 'أبو فيصل');

    model.submit(
      kind: RequestKind.emergency,
      categoryId: 'petrol',
      city: 'خميس مشيط',
      summary: 'السيارة لا تعمل',
      details: 'الموقع: الواحة',
      phone: '0551234567',
      whenLabel: 'فوراً',
      assignNow: false,
    );
    expect(model.pendingOrdersIn('خميس مشيط').first.clientName, 'عميل Servick');
    expect(
      model.acceptOrder(orderId: 'ord-SV-1041', providerId: 'missing'),
      'حساب المزود غير معروف',
    );
  });

  testWidgets('khamis craftsman accepts a nearby order and the list shrinks', (
    tester,
  ) async {
    final model = await _openNearby(tester);
    final mohammad = model.orders.firstWhere(
      (order) => order.clientName == 'أبو محمد',
    );
    final sara = model.orders.firstWhere((order) => order.clientName == 'أم سارة');

    expect(find.text('طلبات الصيانة القريبة (خميس مشيط)'), findsOneWidget);
    expect(find.text('أبو محمد'), findsOneWidget);
    expect(find.text('أم سارة'), findsOneWidget);
    expect(find.text('أبو فيصل'), findsNothing);
    expect(find.textContaining('055'), findsNothing);

    await tester.tap(find.byKey(const Key('provider-notifications')));
    await tester.pumpAndSettle();
    expect(find.text('إشعارات الطلبات الفورية'), findsOneWidget);
    Navigator.of(tester.element(find.text('إشعارات الطلبات الفورية'))).pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(Key('accept-order-${mohammad.id}')));
    await tester.tap(find.byKey(Key('accept-order-${mohammad.id}')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text('تم قبول الطلب بنجاح. توجه لموقع العميل الآن.'),
      findsOneWidget,
    );
    expect(find.text('أبو محمد'), findsNothing);
    expect(find.text('أم سارة'), findsOneWidget);

    await tester.ensureVisible(find.byKey(Key('accept-order-${sara.id}')));
    await tester.tap(find.byKey(Key('accept-order-${sara.id}')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('nearby-empty')), findsOneWidget);
    expect(
      find.text('لا توجد طلبات جديدة متاحة حالياً في منطقتك'),
      findsOneWidget,
    );
  });
}
