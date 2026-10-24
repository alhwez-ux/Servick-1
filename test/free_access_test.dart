import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servick/app_scope.dart';
import 'package:servick/data/admin.dart';
import 'package:servick/data/format.dart';
import 'package:servick/data/providers.dart';
import 'package:servick/main.dart';
import 'package:servick/models/desk.dart';
import 'package:servick/models/provider.dart';

void main() {
  test(
    'the owner sets free months and the warning lands a week before the end',
    () {
      var clock = DateTime.utc(2026, 10, 23, 12);
      final model = AppModel(now: () => clock);
      final unpaid = model.providers.firstWhere(
        (account) => account.id == 'prov-d-ab-1',
      );
      final paid = model.providers.firstWhere(
        (account) => account.id == 'prov-p-km-1',
      );

      expect(
        model.providerComplimentaryPhase(unpaid),
        ComplimentaryPhase.inactive,
      );
      expect(
        model.updateFreeMonths(providerRaw: '0', clientRaw: '25'),
        'أدخل المدة المجانية للعميل من 0 إلى 24 شهراً',
      );
      expect(model.updateFreeMonths(providerRaw: '1', clientRaw: '2'), isNull);

      final providerEnd = clock.add(const Duration(days: 30));
      final clientEnd = clock.add(const Duration(days: 60));
      expect(model.complimentaryEnd(forProvider: true), providerEnd);
      expect(model.complimentaryEnd(forProvider: false), clientEnd);
      expect(model.providerComplimentaryPhase(unpaid), ComplimentaryPhase.open);
      expect(
        model.providerComplimentaryPhase(paid),
        ComplimentaryPhase.inactive,
      );
      expect(
        model.clientComplimentaryPhase('client-demo'),
        ComplimentaryPhase.open,
      );
      expect(model.clientServiceBlock('client-demo'), isNull);

      expect(
        model.loginProvider(
          phone: '0554102206',
          password: demoProviderPassword,
        ),
        isA<ProviderLoginSuccess>(),
      );

      clock = providerEnd.subtract(const Duration(days: 7));
      expect(
        model.providerComplimentaryPhase(model.providerById('prov-d-ab-1')!),
        ComplimentaryPhase.warning,
      );
      model.ensureComplimentaryNotice(
        audience: 'provider',
        recipientId: 'prov-d-ab-1',
      );
      expect(
        model
            .messagesFor(audience: 'provider', recipientId: 'prov-d-ab-1')
            .single
            .body,
        complimentaryWarningText,
      );

      clock = providerEnd;
      expect(
        model.providerComplimentaryPhase(model.providerById('prov-d-ab-1')!),
        ComplimentaryPhase.ended,
      );
      expect(
        model.loginProvider(
          phone: '0554102206',
          password: demoProviderPassword,
        ),
        isA<ProviderFreePeriodEnded>(),
      );

      clock = clientEnd;
      expect(model.clientServiceBlock('client-demo'), complimentaryEndedText);
      expect(
        model.subscribeClient(
          clientId: 'client-demo',
          planId: 'monthly',
          months: 1,
        ),
        isNull,
      );
      expect(
        model.clientComplimentaryPhase('client-demo'),
        ComplimentaryPhase.inactive,
      );
      expect(model.clientServiceBlock('client-demo'), isNull);
    },
  );

  testWidgets('the owner saves the free months from the dashboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.utc(2026, 10, 23, 12);
    final model = AppModel(now: () => now);
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

    await tester.ensureVisible(find.byKey(const Key('free-provider-months')));
    await tester.enterText(find.byKey(const Key('free-provider-months')), '1');
    await tester.enterText(find.byKey(const Key('free-client-months')), '3');
    await tester.ensureVisible(find.byKey(const Key('save-free-months')));
    await tester.tap(find.byKey(const Key('save-free-months')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('تم حفظ المدة المجانية'), findsOneWidget);
    final providerEnd = formatSubscriptionDate(
      now.add(const Duration(days: 30)),
    );
    final clientEnd = formatSubscriptionDate(now.add(const Duration(days: 90)));
    expect(find.textContaining(providerEnd), findsOneWidget);
    expect(find.textContaining(clientEnd), findsOneWidget);
    expect(model.billing.providerFreeMonths, 1);
    expect(model.billing.clientFreeMonths, 3);
  });
}
