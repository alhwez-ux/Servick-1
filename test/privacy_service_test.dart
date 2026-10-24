import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servick/app_scope.dart';
import 'package:servick/data/admin.dart';
import 'package:servick/data/providers.dart';
import 'package:servick/data/service_pictures.dart';
import 'package:servick/main.dart';

void main() {
  test('craftsman fee and new service stay inside the session', () {
    final model = AppModel(now: () => DateTime.utc(2026, 10, 23, 12));
    expect(annualSubscriptionFee, 100);
    expect(model.providerAnnualFee, 100);
    expect(model.addService(title: ' ', subtitle: ''), 'اكتب اسم الخدمة');
    expect(model.addService(title: 'صيانة مكيفات', subtitle: ''), isNull);
    expect(model.addedServices.single.title, 'صيانة مكيفات');
    expect(
      model.addedServices.single.imageAsset,
      pictureForTitle('صيانة مكيفات').asset,
    );
    expect(model.serviceCategories.last.id, 'custom-1');
    expect(
      model.addService(title: 'سطحة ليلية', subtitle: 'سحب داخل المدينة'),
      isNull,
    );
    expect(
      model.addedServices.last.imageAsset,
      pictureForTitle('سطحة ليلية').asset,
    );
    expect(
      model.addService(title: 'خدمة خاصة', subtitle: 'بلا كلمة معروفة'),
      isNull,
    );
    expect(
      model.addedServices.last.imageAsset,
      pictureForTitle('خدمة خاصة').asset,
    );
    expect(
      model.addService(title: 'صيانة مكيفات', subtitle: 'مرة ثانية'),
      'هذه الخدمة موجودة',
    );
  });

  testWidgets('the owner adds a service from the dashboard', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final model = AppModel(now: () => DateTime.utc(2026, 10, 23, 12));
    await tester.pumpWidget(ServickApp(model: model));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('open-admin-login')));
    await tester.tap(find.byKey(const Key('open-admin-login')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('admin-passcode')),
      demoAdminPasscode,
    );
    await tester.tap(find.byKey(const Key('admin-login')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.text('إضافة خدمة جديدة'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('open-add-service')));
    await tester.tap(find.byKey(const Key('open-add-service')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('service-title')),
      'صيانة مكيفات',
    );
    await tester.enterText(
      find.byKey(const Key('service-subtitle')),
      'فحص وتعبئة مكيف المركبة',
    );
    await tester.pump();
    expect(find.byKey(const Key('subtitle-count')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('subtitle-count'))).data,
      contains('23/80'),
    );
    expect(find.byKey(const Key('picture-ac')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('save-service')));
    await tester.tap(find.byKey(const Key('save-service')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('تمت إضافة الخدمة وتظهر الآن في الرئيسية'),
      findsOneWidget,
    );

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();
    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('category-custom-1')), findsOneWidget);
    expect(find.text('صيانة مكيفات'), findsOneWidget);
  });

  testWidgets('provider login stays closed without privacy consent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ServickApp(model: AppModel(now: () => DateTime.utc(2026, 10, 23, 12))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-provider')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('provider-phone')),
      '0554102201',
    );
    await tester.enterText(
      find.byKey(const Key('provider-password')),
      demoProviderPassword,
    );
    await tester.ensureVisible(find.byKey(const Key('provider-login')));
    await tester.tap(find.byKey(const Key('provider-login')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('يجب الموافقة على سياسة الخصوصية قبل تسجيل الدخول'),
      findsOneWidget,
    );
    expect(find.text('بوابة الحرفيين والورش'), findsOneWidget);
  });

  testWidgets('the privacy page shows the October 2026 terms', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ServickApp(model: AppModel(now: () => DateTime.utc(2026, 10, 23, 12))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-privacy')));
    await tester.pumpAndSettle();

    expect(find.textContaining('أكتوبر 2026م'), findsOneWidget);
    expect(find.textContaining('خميس مشيط، أبها، أحد رفيدة'), findsOneWidget);
    await tester.scrollUntilVisible(find.textContaining('غير مستردة'), 400);
    await tester.scrollUntilVisible(
      find.textContaining('لا نقوم ببيع أو تأجير بياناتك'),
      400,
    );
    await tester.scrollUntilVisible(
      find.textContaining('قنوات الدعم الفني'),
      400,
    );
    expect(tester.takeException(), isNull);
  });
}
