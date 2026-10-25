import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servick/app_scope.dart';
import 'package:servick/data/format.dart';
import 'package:servick/data/password_hash.dart';
import 'package:servick/main.dart';

import 'support/accounts.dart';

import 'package:servick/models/models.dart';
import 'package:servick/models/provider.dart';

AppModel _model() {
  return AppModel(now: () => DateTime.utc(2026, 10, 23, 12));
}

Future<void> _openPortal(WidgetTester tester, AppModel model) async {
  await tester.pumpWidget(ServickApp(model: model));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('open-provider-login')));
  await tester.tap(find.byKey(const Key('open-provider-login')));
  await tester.pumpAndSettle();
}

Future<void> _signIn(WidgetTester tester, String phone, String password) async {
  await tester.enterText(find.byKey(const Key('provider-phone')), phone);
  await tester.enterText(find.byKey(const Key('provider-password')), password);
  await tester.ensureVisible(find.byKey(const Key('provider-privacy')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('provider-privacy')));
  await tester.pump();
  await tester.ensureVisible(find.byKey(const Key('provider-login')));
  await tester.tap(find.byKey(const Key('provider-login')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  test('subscription stays closed unless status is active and unexpired', () {
    final now = DateTime.utc(2026, 10, 23, 12);
    final model = AppModel(now: () => now);
    final active = seedProvider(
      model,
      name: 'فهد سعيد الشهري',
      phone: '0554102201',
      city: 'خميس مشيط',
      categoryId: 'petrol',
      active: true,
    );
    final expired = seedProvider(
      model,
      name: 'خالد أحمد عسيري',
      phone: '0554102206',
      city: 'أبها',
      categoryId: 'diesel',
    );

    expect(active.isSubscribedAt(now), isTrue);
    expect(expired.isSubscribedAt(now), isFalse);
    expect(
      ProviderAccount(
        id: 'x',
        technicianId: 'tech-x',
        phone: '0550000000',
        passwordHash: hashPassword('123456', 'salt'),
        passwordSalt: 'salt',
        subscriptionStatus: 'active',
        subscriptionExpiry: null,
      ).isSubscribedAt(now),
      isFalse,
    );

    expect(
      model.loginProvider(phone: '055 000 0000', password: fixturePassword),
      isA<ProviderLoginFailure>(),
    );
    expect(
      model.loginProvider(phone: '0554102201', password: 'wrong'),
      isA<ProviderLoginFailure>(),
    );
    expect(model.providerSession, isNull);

    final blocked = model.loginProvider(
      phone: '0554102206',
      password: fixturePassword,
    );
    expect(blocked, isA<ProviderSubscriptionExpired>());
    expect(model.providerSession, isNull);

    final opened = model.loginProvider(
      phone: '+966554102201',
      password: fixturePassword,
    );
    expect(opened, isA<ProviderLoginSuccess>());
    expect(model.providerSession?.technicianId, active.technicianId);
  });

  test('renewal opens the account and jobs stay inside the craft', () {
    final model = _model();
    final expired = seedProvider(
      model,
      name: 'خالد أحمد عسيري',
      phone: '0554102206',
      city: 'أبها',
      categoryId: 'diesel',
    );
    final active = seedProvider(
      model,
      name: 'فهد سعيد الشهري',
      phone: '0554102201',
      city: 'خميس مشيط',
      categoryId: 'petrol',
      active: true,
    );
    model.submit(
      kind: RequestKind.booking,
      categoryId: 'petrol',
      city: 'خميس مشيط',
      summary: 'تغيير زيت',
      details: 'تغيير زيت',
      phone: '0551234567',
      whenLabel: 'اليوم',
      assignNow: false,
    );
    model.submit(
      kind: RequestKind.booking,
      categoryId: 'diesel',
      city: 'أبها',
      summary: 'دخان ديزل',
      details: 'دخان ديزل',
      phone: '0551234567',
      whenLabel: 'غداً',
      assignNow: false,
    );

    final renewed = model.renewSubscription(expired.id);
    expect(renewed?.isSubscribedAt(model.now), isTrue);
    expect(model.providerSession?.id, expired.id);
    expect(model.jobsFor(renewed!).map((request) => request.summary), [
      'دخان ديزل',
    ]);

    final jobs = model.jobsFor(active);
    expect(jobs.single.summary, 'تغيير زيت');
    expect(
      model.acceptRequest(
        requestId: jobs.single.id,
        technicianId: active.technicianId,
      ),
      isTrue,
    );
    expect(
      model.requests
          .firstWhere((request) => request.id == jobs.single.id)
          .status,
      RequestStatus.assigned,
    );
    expect(
      model.completeRequest(
        requestId: jobs.single.id,
        technicianId: expired.technicianId,
      ),
      isFalse,
    );
    expect(
      model.completeRequest(
        requestId: jobs.single.id,
        technicianId: active.technicianId,
      ),
      isTrue,
    );
    expect(
      model.requests
          .firstWhere((request) => request.id == jobs.single.id)
          .status,
      RequestStatus.completed,
    );
  });

  testWidgets('empty fields stay on the login screen', (tester) async {
    await _openPortal(tester, _model());
    await tester.ensureVisible(find.byKey(const Key('provider-login')));
    await tester.tap(find.byKey(const Key('provider-login')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('الرجاء إدخال رقم الجوال وكلمة المرور'), findsOneWidget);
    expect(find.text('بوابة مقدمي الخدمات'), findsOneWidget);
    expect(find.text('تسجيل مقدم خدمة'), findsOneWidget);
  });

  testWidgets('active craftsman reaches the job board', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final model = _model();
    seedProvider(
      model,
      name: 'فهد سعيد الشهري',
      phone: '0554102201',
      city: 'خميس مشيط',
      categoryId: 'petrol',
      active: true,
    );
    model.submit(
      kind: RequestKind.booking,
      categoryId: 'petrol',
      city: 'خميس مشيط',
      summary: 'تغيير زيت في النخيل',
      details: 'تغيير زيت في النخيل',
      phone: '0551234567',
      whenLabel: 'اليوم',
      assignNow: false,
    );
    await _openPortal(tester, model);
    await _signIn(tester, '0554102201', fixturePassword);

    expect(find.byKey(const Key('provider-dashboard')), findsOneWidget);
    expect(find.text('فهد سعيد الشهري'), findsOneWidget);
    expect(find.text('تغيير زيت في النخيل'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('accept-SV-1041')));
    await tester.tap(find.byKey(const Key('accept-SV-1041')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('complete-SV-1041')));
    await tester.tap(find.byKey(const Key('complete-SV-1041')));
    await tester.pump();

    expect(find.text('مكتمل'), findsOneWidget);
    expect(model.requests.single.status, RequestStatus.completed);
  });

  testWidgets('expired subscription renews from the subscription screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final model = _model();
    seedProvider(
      model,
      name: 'خالد أحمد عسيري',
      phone: '0554102206',
      city: 'أبها',
      categoryId: 'diesel',
    );
    await _openPortal(tester, model);
    await _signIn(tester, '0554102206', fixturePassword);

    expect(find.text('اشتراكك السنوي منتهي'), findsOneWidget);
    expect(model.providerSession, isNull);

    await tester.tap(find.text('تجديد الاشتراك الآن'));
    await tester.pumpAndSettle();
    expect(find.text('اشتراكك السنوي منتهي أو غير مفعل'), findsOneWidget);
    expect(find.text('سداد رسوم التجديد وتفعيل الحساب'), findsOneWidget);
    expect(
      find.textContaining(
        formatSubscriptionDate(
          model.providerByPhone('0554102206')!.subscriptionExpiry!,
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('renew-subscription')));
    await tester.pumpAndSettle();
    expect(find.text('تأكيد تجديد الاشتراك السنوي'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-payment')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text('تم تجديد اشتراكك السنوي بنجاح! شكراً لانضمامك لـ Servick'),
      findsOneWidget,
    );
    expect(find.text('حسابك مفعل وجاهز لاستقبال الطلبات'), findsOneWidget);
    expect(find.textContaining('2027/10/23'), findsOneWidget);
    expect(model.providerSession?.subscriptionStatus, 'active');

    ScaffoldMessenger.of(
      tester.element(find.byKey(const Key('renew-subscription'))),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('open-dashboard-from-subscription')),
    );
    await tester.tap(find.byKey(const Key('open-dashboard-from-subscription')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('provider-dashboard')), findsOneWidget);
    expect(find.text('خالد أحمد عسيري'), findsOneWidget);
  });
}
