import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servick/app_scope.dart';
import 'package:servick/data/admin.dart';
import 'package:servick/data/external_url.dart';
import 'package:servick/data/mail.dart';
import 'package:servick/data/whatsapp.dart';
import 'package:servick/main.dart';

import 'support/accounts.dart';

void main() {
  test('whatsapp chat uses the recipient mobile', () {
    expect(
      whatsAppChatUrl('0555748375', 'مرحبا'),
      'https://wa.me/966555748375?text=${Uri.encodeComponent('مرحبا')}',
    );
    expect(whatsAppChatUrl('خميس مشيط', 'مرحبا'), isNull);
    expect(whatsAppBusinessDisplay, '0555748375');
  });

  test('accounts change passwords and recover them by email', () async {
    final model = AppModel(
      now: () => DateTime.utc(2026, 10, 25, 8),
      temporaryPassword: () => 'TEMP1234',
      mailer: (_) async => true,
    );
    final provider = seedProvider(
      model,
      name: 'فهد سعيد الشهري',
      phone: '0554102201',
      city: 'خميس مشيط',
      categoryId: 'petrol',
      active: true,
    );
    final client = seedClient(model, phone: '0552223344');

    expect(
      model.changeClientPassword(
        clientId: client.id,
        current: fixturePassword,
        next: 'abc',
        email: 'sara@example.com',
      ),
      'كلمة المرور ستة أحرف على الأقل',
    );
    expect(
      model.changeClientPassword(
        clientId: client.id,
        current: fixturePassword,
        next: 'client1',
        email: 'sara@example.com',
      ),
      isNull,
    );
    expect(
      model.loginClient(phone: '0552223344', password: fixturePassword),
      isNotNull,
    );
    expect(model.loginClient(phone: '0552223344', password: 'client1'), isNull);

    expect(
      model.changeProviderPassword(
        providerId: provider.id,
        current: '000000',
        next: 'provider1',
        email: 'fahd@example.com',
      ),
      'كلمة المرور الحالية غير صحيحة',
    );
    expect(
      model.changeProviderPassword(
        providerId: provider.id,
        current: fixturePassword,
        next: 'provider1',
        email: 'sara@example.com',
      ),
      'هذا البريد مسجّل من قبل',
    );
    expect(
      model.changeProviderPassword(
        providerId: provider.id,
        current: fixturePassword,
        next: 'provider1',
        email: 'fahd@example.com',
      ),
      isNull,
    );
    expect(
      model.providerByPhone('0554102201')!.matchesPassword(fixturePassword),
      isFalse,
    );
    expect(
      model.providerByPhone('0554102201')!.matchesPassword('provider1'),
      isTrue,
    );

    expect(model.ownerPasswordMatches(demoAdminPasscode), isTrue);
    expect(
      model.changeOwnerPassword(
        current: demoAdminPasscode,
        next: 'owner11',
        email: 'owner@example.com',
      ),
      isNull,
    );
    expect(model.ownerUsesDemoPasscode, isFalse);
    expect(model.ownerPasswordMatches(demoAdminPasscode), isFalse);
    expect(model.ownerPasswordMatches('owner11'), isTrue);

    final missing = await model.resetPasswordByEmail(
      audience: 'client',
      email: 'missing@example.com',
    );
    expect(missing.error, 'لا يوجد حساب بهذا البريد');

    final ownerMissing = await model.resetPasswordByEmail(
      audience: 'owner',
      email: 'other@example.com',
    );
    expect(ownerMissing.error, 'لا يوجد حساب بهذا البريد');

    final mailed = await model.resetPasswordByEmail(
      audience: 'client',
      email: 'Sara@Example.com',
    );
    expect(mailed.mailed, isTrue);
    expect(mailed.temporary, isNull);
    expect(
      model.loginClient(phone: '0552223344', password: 'TEMP1234'),
      isNull,
    );
    expect(
      model.loginClient(phone: '0552223344', password: 'client1'),
      isNotNull,
    );
  });

  test('a failed mailer still reveals the temporary password', () async {
    final model = AppModel(
      now: () => DateTime.utc(2026, 10, 25, 8),
      temporaryPassword: () => 'TEMP1234',
      mailer: (_) async => throw StateError('mail down'),
    );
    expect(
      model.changeOwnerPassword(
        current: demoAdminPasscode,
        next: 'owner11',
        email: 'owner@example.com',
      ),
      isNull,
    );
    final result = await model.resetPasswordByEmail(
      audience: 'owner',
      email: 'owner@example.com',
    );
    expect(result.mailed, isFalse);
    expect(result.temporary, 'TEMP1234');
    expect(model.ownerPasswordMatches('owner11'), isFalse);
    expect(model.ownerPasswordMatches('TEMP1234'), isTrue);

    final empty = AppModel(now: () => DateTime.utc(2026, 10, 25, 8));
    final blocked = await empty.resetPasswordByEmail(
      audience: 'owner',
      email: 'owner@example.com',
    );
    expect(
      blocked.error,
      'لا يوجد بريد مسجّل للمالك. أضفه من لوحة التحكم بعد الدخول.',
    );
    expect(empty.ownerPasswordMatches(demoAdminPasscode), isTrue);
  });

  test('the mail payload stays short and addressed', () {
    const mail = PasswordMail(
      to: 'owner@example.com',
      subject: 'كلمة المرور المؤقتة | رابط',
      text: 'كلمة المرور المؤقتة',
    );
    expect(mail.to, 'owner@example.com');
    expect(mail.subject.length, lessThan(121));
    expect(mail.text.length, lessThan(2001));
  });

  testWidgets('the owner replaces the demo passcode from the dashboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final model = AppModel(now: () => DateTime.utc(2026, 10, 25, 8));
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

    await tester.ensureVisible(find.byKey(const Key('password-panel-owner')));
    await tester.tap(find.byKey(const Key('password-panel-owner')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('password-email-owner')),
      'owner@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password-current-owner')),
      demoAdminPasscode,
    );
    await tester.enterText(
      find.byKey(const Key('password-next-owner')),
      'owner11',
    );
    await tester.ensureVisible(find.byKey(const Key('save-password-owner')));
    await tester.tap(find.byKey(const Key('save-password-owner')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('تم حفظ كلمة المرور والبريد'), findsOneWidget);
    expect(model.ownerPasswordMatches('owner11'), isTrue);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open-admin-login')));
    await tester.tap(find.byKey(const Key('open-admin-login')));
    await tester.pumpAndSettle();
    expect(find.textContaining(demoAdminPasscode), findsNothing);
    await tester.enterText(find.byKey(const Key('admin-passcode')), 'owner11');
    await tester.tap(find.byKey(const Key('admin-login')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('لوحة تحكم المالك | رابط'), findsOneWidget);
  });

  testWidgets('client recovery shows the temporary password when mail fails', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final model = AppModel(
      now: () => DateTime.utc(2026, 10, 25, 8),
      temporaryPassword: () => 'TEMP1234',
      mailer: (_) async => false,
    );
    expect(
      model.registerClient(
        name: 'سارة القحطاني',
        phone: '0551234567',
        city: 'خميس مشيط',
        password: fixturePassword,
        email: 'sara@example.com',
      ),
      isNull,
    );
    await tester.pumpWidget(ServickApp(model: model));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open-client-login')));
    await tester.tap(find.byKey(const Key('open-client-login')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('forgot-password-client')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('recovery-email')),
      'sara@example.com',
    );
    await tester.tap(find.byKey(const Key('send-recovery')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('TEMP1234'), findsOneWidget);
    expect(
      model.loginClient(phone: '0551234567', password: fixturePassword),
      isNotNull,
    );
    expect(
      model.loginClient(phone: '0551234567', password: 'TEMP1234'),
      isNull,
    );
  });

  testWidgets('the owner opens WhatsApp chats for some and all recipients', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    captureExternalUrls = true;
    openedExternalUrls.clear();
    addTearDown(() {
      captureExternalUrls = false;
      openedExternalUrls.clear();
    });

    final model = AppModel(now: () => DateTime.utc(2026, 10, 25, 8));
    final first = seedProvider(
      model,
      name: 'فهد سعيد الشهري',
      phone: '0554102201',
      city: 'خميس مشيط',
      categoryId: 'petrol',
      active: true,
    );
    final second = seedProvider(
      model,
      name: 'سالم محمد عسيري',
      phone: '0554102202',
      city: 'أبها',
      categoryId: 'auto_elec',
      active: true,
    );
    seedClient(model, name: 'سارة القحطاني', phone: '0552223344');

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

    expect(find.text('واتساب الأعمال'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('send-whatsapp')));
    await tester.tap(find.byKey(const Key('send-whatsapp')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('اكتب نص الرسالة'), findsOneWidget);

    await tester.ensureVisible(find.byKey(Key('whatsapp-target-${first.id}')));
    await tester.tap(find.byKey(Key('whatsapp-target-${first.id}')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('whatsapp-body')),
      'موعد الصيانة غداً',
    );
    await tester.ensureVisible(find.byKey(const Key('send-whatsapp')));
    await tester.tap(find.byKey(const Key('send-whatsapp')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(openedExternalUrls, [
      whatsAppChatUrl('0554102201', 'موعد الصيانة غداً'),
    ]);
    expect(find.textContaining('0555748375'), findsWidgets);

    await tester.ensureVisible(
      find.byKey(const Key('whatsapp-audience-client')),
    );
    await tester.tap(find.byKey(const Key('whatsapp-audience-client')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('whatsapp-all')));
    await tester.tap(find.byKey(const Key('whatsapp-all')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('send-whatsapp')));
    await tester.tap(find.byKey(const Key('send-whatsapp')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      openedExternalUrls.last,
      whatsAppChatUrl('0552223344', 'موعد الصيانة غداً'),
    );
    expect(openedExternalUrls, hasLength(2));
    expect(find.byKey(Key('whatsapp-target-${second.id}')), findsNothing);
  });
}
