import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servick/main.dart';
import 'package:servick/app_scope.dart';

import 'support/accounts.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(ServickApp(model: AppModel()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home shows the emergency card and every service', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('عطل طارئ على الطريق؟'), findsOneWidget);
    expect(find.text('طلب طوارئ'), findsOneWidget);
    expect(find.text('اختر نوع الخدمة المطلوبة:'), findsOneWidget);
    expect(find.bySemanticsLabel('شعار رابط'), findsOneWidget);
    expect(find.byKey(const Key('service-image-petrol')), findsOneWidget);
    expect(find.byKey(const Key('service-image-home_elec')), findsOneWidget);

    for (final id in [
      'petrol',
      'diesel',
      'chinese',
      'equipment',
      'auto_elec',
      'home_elec',
    ]) {
      expect(find.byKey(Key('category-$id')), findsOneWidget);
    }
  });

  testWidgets('narrow and wide home layouts stay within the screen', (
    tester,
  ) async {
    for (final size in const [Size(360, 780), Size(1280, 800)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pumpApp(tester);
      expect(find.text('طلب طوارئ'), findsOneWidget);
    }
  });

  testWidgets('changing city reveals the empty chinese category', (
    tester,
  ) async {
    await _pumpApp(tester);

    await tester.tap(find.byKey(const Key('city-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أحد رفيدة').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('category-chinese')));
    await tester.tap(find.byKey(const Key('category-chinese')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('empty-technicians')), findsOneWidget);
    expect(find.textContaining('ميكانيكي صيني'), findsWidgets);
  });

  testWidgets('emergency request matches the nearest technician', (
    tester,
  ) async {
    final model = AppModel();
    seedClient(model, signIn: true);
    seedProvider(
      model,
      name: 'بدر محمد الشهري',
      phone: '0554102211',
      city: 'خميس مشيط',
      categoryId: 'auto_elec',
      active: true,
    );
    await tester.pumpWidget(ServickApp(model: model));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('open-emergency')));
    await tester.tap(find.byKey(const Key('open-emergency')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('بطارية'));
    await tester.tap(find.text('بطارية'));
    await tester.enterText(
      find.byKey(const Key('emergency-place')),
      'طريق الملك فهد عند محطة النخيل',
    );
    await tester.enterText(
      find.byKey(const Key('emergency-phone')),
      '0551234567',
    );
    await tester.ensureVisible(find.byKey(const Key('send-emergency')));
    await tester.tap(find.byKey(const Key('send-emergency')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('privacy-checkbox')));
    await tester.tap(find.byKey(const Key('privacy-checkbox')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('accept-privacy')));
    await tester.tap(find.byKey(const Key('accept-privacy')));
    await tester.pumpAndSettle();

    expect(find.text('SV-1041'), findsOneWidget);
    expect(find.text('بدر محمد الشهري'), findsOneWidget);
    expect(find.text('تم توجيه الطلب'), findsOneWidget);
  });

  testWidgets('emergency form asks for the missing fields', (tester) async {
    await _pumpApp(tester);
    await tester.ensureVisible(find.byKey(const Key('open-emergency')));
    await tester.tap(find.byKey(const Key('open-emergency')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('send-emergency')));
    await tester.tap(find.byKey(const Key('send-emergency')));
    await tester.pumpAndSettle();

    expect(find.text('اختر نوع العطل'), findsOneWidget);
    expect(find.text('اكتب أقرب معلم للموقع'), findsOneWidget);
    expect(find.text('أدخل جوالاً سعودياً يبدأ بـ 05'), findsOneWidget);
  });

  testWidgets('booking a mechanic stores the request', (tester) async {
    final model = AppModel();
    seedClient(model, signIn: true);
    final account = seedProvider(
      model,
      name: 'فهد سعيد الشهري',
      phone: '0554102201',
      city: 'خميس مشيط',
      categoryId: 'petrol',
      active: true,
    );
    await tester.pumpWidget(ServickApp(model: model));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('category-petrol')));
    await tester.tap(find.byKey(const Key('category-petrol')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('tech-${account.technicianId}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اطلب هذا الفني'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('booking-details')),
      'صوت طقطقة عند تشغيل المكينة',
    );
    await tester.enterText(
      find.byKey(const Key('booking-phone')),
      '0559876543',
    );
    await tester.ensureVisible(find.byKey(const Key('send-booking')));
    await tester.tap(find.byKey(const Key('send-booking')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('privacy-checkbox')));
    await tester.tap(find.byKey(const Key('privacy-checkbox')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('accept-privacy')));
    await tester.tap(find.byKey(const Key('accept-privacy')));
    await tester.pumpAndSettle();

    expect(find.text('تم إرسال طلبك'), findsOneWidget);
    expect(find.text('SV-1041'), findsOneWidget);
    expect(find.text('فهد سعيد الشهري'), findsWidgets);
  });
}
