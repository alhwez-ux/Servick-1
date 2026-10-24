import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servick/app_scope.dart';
import 'package:servick/data/admin.dart';
import 'package:servick/data/client_plans.dart';

import 'support/accounts.dart';
import 'package:servick/main.dart';
import 'package:servick/routes.dart';

void main() {
  test(
    'the owner edits prices, messages people, and issues a trial invoice',
    () {
      final model = AppModel(now: () => DateTime.utc(2026, 10, 23, 12));
      final account = seedProvider(
        model,
        name: 'فهد سعيد الشهري',
        phone: '0554102201',
        city: 'خميس مشيط',
        categoryId: 'petrol',
        active: true,
      );
      final fahd = model.technicianById(account.technicianId)!;

      expect(model.startingPriceOf(fahd), 0);
      expect(
        model.updateStartingPrice(technicianId: 'missing', raw: '90'),
        'الفني غير موجود',
      );
      expect(
        model.updateStartingPrice(technicianId: fahd.id, raw: 'abc'),
        'أدخل سعراً صحيحاً من 0 إلى 9999',
      );
      expect(
        model.updateStartingPrice(technicianId: fahd.id, raw: '95'),
        isNull,
      );
      expect(model.startingPriceOf(fahd), 95);

      expect(
        model.sendDeskMessage(
          audience: 'provider',
          recipientId: account.id,
          body: '   ',
        ),
        'اكتب نص الرسالة',
      );
      expect(
        model.sendDeskMessage(
          audience: 'provider',
          recipientId: account.id,
          body: ' تم اعتماد ظهورك في خميس مشيط ',
        ),
        isNull,
      );
      expect(
        model
            .messagesFor(audience: 'provider', recipientId: account.id)
            .single
            .body,
        'تم اعتماد ظهورك في خميس مشيط',
      );
      final client = seedClient(model, name: demoClientName, phone: '0552223344');
      expect(model.deskRecipients('client').map((item) => item.name), [
        client.name,
      ]);

      expect(
        model.updateBilling(
          providerFeeRaw: '550',
          planPriceRaws: const {
            'monthly': '35',
            'quarterly': '40',
            'semi_annual': '70',
            'annual': '120',
          },
          prefix: 'SV',
          nextNumberRaw: '1041',
          note: '',
          invoicesEnabled: true,
        ),
        isNull,
      );
      expect(model.providerAnnualFee, 550);
      expect(model.planPriceOf('monthly'), 35);
      expect(model.billing.note, 'فاتورة تجريبية. لا يُخصم مبلغ حقيقي.');

      expect(
        model.subscribeClient(
          clientId: demoClientId,
          planId: 'monthly',
          months: 1,
        ),
        isNull,
      );
      expect(model.invoices.single.number, 'SV-1041');
      expect(model.invoices.single.amount, 35);
      expect(model.invoices.single.partyName, demoClientName);
      expect(model.billing.nextNumber, 1042);

      expect(model.renewSubscription(account.id), isNotNull);
      expect(model.invoices.first.amount, 550);
      expect(model.invoices.first.title, 'اشتراك الحرفي السنوي');
    },
  );

  testWidgets('the owner desk saves a price, a message, and billing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final model = AppModel(now: () => DateTime.utc(2026, 10, 23, 12));
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

    await tester.ensureVisible(find.byKey(const Key('open-admin-desk')));
    await tester.tap(find.byKey(const Key('open-admin-desk')));
    await tester.pumpAndSettle();

    expect(find.text('تعديل الأسعار'), findsOneWidget);
    expect(find.text('مراسلة مزودي الخدمة والعملاء'), findsOneWidget);
    expect(find.text('نظام الفوترة'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(Key('price-field-${account.technicianId}')),
    );
    await tester.enterText(
      find.byKey(Key('price-field-${account.technicianId}')),
      '95',
    );
    await tester.ensureVisible(
      find.byKey(Key('save-price-${account.technicianId}')),
    );
    await tester.tap(find.byKey(Key('save-price-${account.technicianId}')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('تم تحديث سعر البداية'), findsOneWidget);
    expect(model.startingPriceOf(model.technicianById(account.technicianId)!), 95);

    await tester.ensureVisible(find.byKey(const Key('message-body')));
    await tester.enterText(
      find.byKey(const Key('message-body')),
      'تم اعتماد ظهورك في خميس مشيط',
    );
    await tester.ensureVisible(find.byKey(const Key('send-message')));
    await tester.tap(find.byKey(const Key('send-message')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('تم إرسال الرسالة'), findsOneWidget);
    expect(find.text('تم اعتماد ظهورك في خميس مشيط'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('billing-provider-fee')));
    await tester.enterText(
      find.byKey(const Key('billing-provider-fee')),
      '550',
    );
    await tester.ensureVisible(find.byKey(const Key('save-billing')));
    await tester.tap(find.byKey(const Key('save-billing')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('تم حفظ إعدادات الفوترة'), findsOneWidget);
    expect(model.providerAnnualFee, 550);
  });

  testWidgets('the desk route without the passcode shows login', (
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
        .pushNamed(ServickRoutes.adminDesk);
    await tester.pumpAndSettle();

    expect(find.text('دخول مالك التطبيق | Servick'), findsOneWidget);
    expect(find.text('نظام الفوترة'), findsNothing);
  });
}
