import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servick/app_scope.dart';
import 'package:servick/data/admin.dart';
import 'package:servick/main.dart';
import 'package:servick/models/provider.dart';

import 'support/accounts.dart';

void main() {
  test('the owner activates an expired craftsman for one year', () {
    final now = DateTime.utc(2026, 10, 23, 12);
    final model = AppModel(now: () => now);
    final expired = seedProvider(
      model,
      name: 'خالد أحمد عسيري',
      phone: '0554102206',
      city: 'أبها',
      categoryId: 'diesel',
    );

    expect(model.providers, hasLength(1));
    expect(model.orderCount, 0);
    expect(model.expiredProviders.map((account) => account.id), [expired.id]);
    expect(model.providerSession, isNull);

    expect(model.activateProviderSubscription('missing'), 'مقدم الخدمة غير موجود');

    final before = model.loginProvider(
      phone: '0554102206',
      password: fixturePassword,
    );
    expect(before, isA<ProviderSubscriptionExpired>());
    expect(model.providerSession, isNull);

    expect(model.activateProviderSubscription(expired.id), isNull);
    final khalid = model.providerById(expired.id)!;
    expect(khalid.subscriptionStatus, 'active');
    expect(khalid.subscriptionExpiry, now.add(const Duration(days: 365)));
    expect(khalid.isSubscribedAt(now), isTrue);
    expect(model.expiredProviders, isEmpty);
    expect(model.providerSession, isNull);
    expect(model.orderCount, 0);

    final after = model.loginProvider(
      phone: '0554102206',
      password: fixturePassword,
    );
    expect(after, isA<ProviderLoginSuccess>());
  });

  testWidgets(
    'the owner dashboard lists the expired craftsman then clears it',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final model = AppModel(now: () => DateTime.utc(2026, 10, 23, 12));
      final expired = seedProvider(
        model,
        name: 'خالد أحمد عسيري',
        phone: '0554102206',
        city: 'أبها',
        categoryId: 'diesel',
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

      expect(find.text('لوحة تحكم المالك | Servick Admin'), findsOneWidget);
      expect(find.text('خالد أحمد عسيري'), findsOneWidget);
      expect(find.textContaining('أبها'), findsOneWidget);
      expect(find.textContaining('055'), findsWidgets);
      expect(find.byKey(const Key('stat-providers')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('stat-providers'))).data,
        '1',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('stat-orders'))).data,
        '0',
      );
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(
        find.byKey(Key('activate-provider-${expired.id}')),
      );
      await tester.tap(find.byKey(Key('activate-provider-${expired.id}')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('تم تفعيل اشتراك مقدم الخدمة بنجاح!'), findsOneWidget);
      expect(find.byKey(const Key('admin-empty')), findsOneWidget);
      expect(find.byKey(Key('activate-provider-${expired.id}')), findsNothing);
      expect(model.providerById(expired.id)!.subscriptionStatus, 'active');
    },
  );

  testWidgets('a pending deletion stays readable on a narrow dashboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final model = AppModel(now: () => DateTime.utc(2026, 10, 23, 12));
    final client = seedClient(model, name: 'نورة الشهري', phone: '0551112233');
    expect(
      model.requestAccountDeletion(audience: 'client', accountId: client.id),
      isNull,
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

    expect(find.text('لوحة تحكم المالك | Servick Admin'), findsOneWidget);
    expect(find.text('نورة الشهري'), findsWidgets);
    expect(find.text('موافقة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
