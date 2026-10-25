import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servick/app_scope.dart';
import 'package:servick/data/admin.dart';
import 'package:servick/main.dart';
import 'package:servick/routes.dart';

import 'support/accounts.dart';

void main() {
  test('the owner saves a suggestion and can read every order', () {
    final model = AppModel(now: () => DateTime.utc(2026, 10, 23, 12));

    expect(model.orders, isEmpty);
    model.submitClientOrder(
      clientId: 'client-a',
      clientName: 'أبو محمد',
      categoryId: 'benz_mech',
      city: 'خميس مشيط',
      notes: 'صوت في المكينة عند التشغيل قرب طريق الملك فهد',
    );
    expect(model.orders, hasLength(1));
    expect(
      model.addOwnerSuggestion(area: 'missing', text: 'نص'),
      'اختر موضع التعديل',
    );
    expect(
      model.addOwnerSuggestion(area: 'ui', text: '   '),
      'اكتب ما تريد تعديله أو إضافته',
    );
    expect(model.ownerSuggestions, isEmpty);

    expect(
      model.addOwnerSuggestion(area: 'addition', text: '  أضف صورة للفني  '),
      isNull,
    );
    expect(model.ownerSuggestions, hasLength(1));
    expect(model.ownerSuggestions.single.id, 'sug-1');
    expect(model.ownerSuggestions.single.area, 'addition');
    expect(model.ownerSuggestions.single.text, 'أضف صورة للفني');
  });

  testWidgets('the owner reviews details and records a change', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
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
    seedProvider(
      model,
      name: 'خالد أحمد عسيري',
      phone: '0554102206',
      city: 'أبها',
      categoryId: 'diesel',
    );
    model.submitClientOrder(
      clientId: 'client-a',
      clientName: 'أبو محمد',
      categoryId: 'benz_mech',
      city: 'خميس مشيط',
      notes: 'صوت في المكينة عند التشغيل قرب طريق الملك فهد',
    );
    await tester.pumpWidget(ServickApp(model: model));
    await tester.pumpAndSettle();

    await openOwnerLogin(tester);
    await tester.enterText(
      find.byKey(const Key('admin-passcode')),
      demoAdminPasscode,
    );
    await tester.tap(find.byKey(const Key('admin-login')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('open-admin-review')));
    await tester.tap(find.byKey(const Key('open-admin-review')));
    await tester.pumpAndSettle();

    expect(find.text('معاينة التفاصيل'), findsOneWidget);
    expect(find.text('فهد سعيد الشهري'), findsOneWidget);
    expect(find.text('خالد أحمد عسيري'), findsOneWidget);
    expect(find.textContaining('أبو محمد'), findsOneWidget);
    expect(
      find.text('صوت في المكينة عند التشغيل قرب طريق الملك فهد'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('suggestions-empty')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('submit-suggestion')));
    await tester.tap(find.byKey(const Key('submit-suggestion')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('اكتب ما تريد تعديله أو إضافته'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('suggestion-area-addition')),
    );
    await tester.tap(find.byKey(const Key('suggestion-area-addition')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('suggestion-text')),
      'أضف صورة للفني في بطاقة الدليل',
    );
    await tester.ensureVisible(find.byKey(const Key('submit-suggestion')));
    await tester.tap(find.byKey(const Key('submit-suggestion')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('تم حفظ اقتراحك للمراجعة'), findsOneWidget);
    expect(find.text('أضف صورة للفني في بطاقة الدليل'), findsOneWidget);
    expect(find.byKey(const Key('suggestions-empty')), findsNothing);
    expect(model.ownerSuggestions.single.area, 'addition');
  });

  testWidgets('the review route without the passcode shows login', (
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
        .pushNamed(ServickRoutes.adminReview);
    await tester.pumpAndSettle();

    expect(find.text('دخول مالك التطبيق | رابط'), findsOneWidget);
    expect(find.text('معاينة التفاصيل'), findsNothing);
  });
}
