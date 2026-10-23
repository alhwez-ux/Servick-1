import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servick/app_scope.dart';
import 'package:servick/data/admin.dart';
import 'package:servick/data/providers.dart';
import 'package:servick/main.dart';
import 'package:servick/models/provider.dart';

void main() {
  test('the owner activates an expired craftsman for one year', () {
    final now = DateTime.utc(2026, 10, 23, 12);
    final model = AppModel(now: () => now);

    expect(model.providers, hasLength(2));
    expect(model.orderCount, 4);
    expect(model.expiredProviders.map((account) => account.id), [
      'prov-d-ab-1',
    ]);
    expect(model.providerSession, isNull);

    expect(model.activateProviderSubscription('missing'), 'الحرفي غير موجود');

    final before = model.loginProvider(
      phone: '0554102206',
      password: demoProviderPassword,
    );
    expect(before, isA<ProviderSubscriptionExpired>());
    expect(model.providerSession, isNull);

    expect(model.activateProviderSubscription('prov-d-ab-1'), isNull);
    final khalid = model.providerById('prov-d-ab-1')!;
    expect(khalid.subscriptionStatus, 'active');
    expect(khalid.subscriptionExpiry, now.add(const Duration(days: 365)));
    expect(khalid.isSubscribedAt(now), isTrue);
    expect(model.expiredProviders, isEmpty);
    expect(model.providerSession, isNull);
    expect(model.orderCount, 4);

    final after = model.loginProvider(
      phone: '0554102206',
      password: demoProviderPassword,
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
      expect(find.text('2'), findsWidgets);
      expect(find.text('4'), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(
        find.byKey(const Key('activate-provider-prov-d-ab-1')),
      );
      await tester.tap(find.byKey(const Key('activate-provider-prov-d-ab-1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('تم تفعيل اشتراك الحرفي بنجاح!'), findsOneWidget);
      expect(find.byKey(const Key('admin-empty')), findsOneWidget);
      expect(find.text('خالد أحمد عسيري'), findsNothing);
      expect(model.providerById('prov-d-ab-1')!.subscriptionStatus, 'active');
    },
  );
}
