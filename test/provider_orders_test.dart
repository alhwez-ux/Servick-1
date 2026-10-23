import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servick/app_scope.dart';
import 'package:servick/data/providers.dart';
import 'package:servick/main.dart';
import 'package:servick/models/models.dart';

Future<void> _openNearby(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final model = AppModel(now: () => DateTime.utc(2026, 10, 23, 12));
  await tester.pumpWidget(ServickApp(model: model));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('open-provider-login')));
  await tester.tap(find.byKey(const Key('open-provider-login')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('provider-phone')), '0554102201');
  await tester.enterText(
    find.byKey(const Key('provider-password')),
    demoProviderPassword,
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
  return;
}

void main() {
  test('pending orders stay inside the craftsman city until accepted', () {
    final model = AppModel(now: () => DateTime.utc(2026, 10, 23, 12));
    expect(
      model.pendingOrdersIn('خميس مشيط').map((order) => order.clientName),
      ['أبو محمد', 'أم سارة'],
    );
    expect(model.pendingOrdersIn('أبها').map((order) => order.id), [
      'ord-ab-1',
    ]);
    expect(
      model.pendingOrdersIn('أحد رفيدة').single.serviceTitle,
      'كهربائي منازل',
    );

    expect(
      model.acceptOrder(orderId: 'ord-km-1', providerId: 'prov-p-km-1'),
      isNull,
    );
    expect(model.pendingOrdersIn('خميس مشيط').map((order) => order.id), [
      'ord-km-2',
    ]);
    expect(
      model.acceptOrder(orderId: 'ord-km-1', providerId: 'prov-p-km-1'),
      'هذا الطلب لم يعد متاحاً',
    );
    expect(model.pendingOrdersIn('أبها').single.id, 'ord-ab-1');

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
    await _openNearby(tester);

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

    await tester.ensureVisible(find.byKey(const Key('accept-order-ord-km-1')));
    await tester.tap(find.byKey(const Key('accept-order-ord-km-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text('تم قبول الطلب بنجاح. توجه لموقع العميل الآن.'),
      findsOneWidget,
    );
    expect(find.text('أبو محمد'), findsNothing);
    expect(find.text('أم سارة'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('accept-order-ord-km-2')));
    await tester.tap(find.byKey(const Key('accept-order-ord-km-2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('nearby-empty')), findsOneWidget);
    expect(
      find.text('لا توجد طلبات جديدة متاحة حالياً في منطقتك'),
      findsOneWidget,
    );
  });
}
