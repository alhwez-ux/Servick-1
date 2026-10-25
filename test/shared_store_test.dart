import 'package:flutter_test/flutter_test.dart';
import 'package:servick/app_scope.dart';
import 'package:servick/data/catalog.dart';
import 'package:servick/data/shared_snapshot.dart';
import 'package:servick/data/shared_store.dart';

import 'support/accounts.dart';

void main() {
  test('owner additions and accounts survive on another device', () async {
    final store = MemorySharedStore();
    final clock = DateTime.utc(2026, 10, 24, 9);
    final first = AppModel(now: () => clock, store: store);
    expect(first.providers, isEmpty);

    expect(
      first.registerClient(
        name: 'نورة الشهري',
        phone: '0551112233',
        city: 'أبها',
        password: fixturePassword,
        email: 'noura@example.com',
      ),
      isNull,
    );
    expect(
      first.addService(title: 'صيانة مكيفات', subtitle: 'تعبئة فريون'),
      isNull,
    );
    expect(
      first.addOwnerSuggestion(area: 'addition', text: 'أضف سطحة'),
      isNull,
    );
    final client = first.clientByPhone('0551112233')!;
    expect(
      first.submitClientOrder(
        clientId: client.id,
        clientName: client.name,
        categoryId: 'benz_mech',
        city: 'أبها',
        notes: 'صوت',
      ),
      isNull,
    );
    expect(
      first.changeOwnerPassword(
        current: '7711',
        next: 'secret1',
        email: 'owner@example.com',
      ),
      isNull,
    );
    await first.flush();

    final encoded = store.value!.encode();
    expect(encoded.contains(fixturePassword), isFalse);
    expect(encoded.contains('secret1'), isFalse);
    expect(encoded.contains(client.passwordHash), isTrue);
    expect(encoded.contains('noura@example.com'), isTrue);

    final second = AppModel(now: () => clock, store: store);
    await second.hydrate();
    expect(second.clientAccounts.single.name, 'نورة الشهري');
    expect(second.clientAccounts.single.email, 'noura@example.com');
    expect(second.ownerEmail, 'owner@example.com');
    expect(second.ownerPasswordMatches('7711'), isFalse);
    expect(second.ownerPasswordMatches('secret1'), isTrue);
    expect(second.addedServices.single.title, 'صيانة مكيفات');
    expect(second.ownerSuggestions.single.text, 'أضف سطحة');
    expect(second.orders.single.clientName, 'نورة الشهري');
    expect(
      second.loginClient(phone: '0551112233', password: fixturePassword),
      isNull,
    );

    expect(second.removeService('petrol'), 'لا يمكن حذف الخدمات الأساسية');
    expect(second.removeService(second.addedServices.single.id), isNull);
    expect(
      second.requestAccountDeletion(audience: 'client', accountId: client.id),
      isNull,
    );
    expect(second.clientById(client.id), isNotNull);
    await second.flush();

    final third = AppModel(now: () => clock, store: store);
    await third.hydrate();
    expect(third.addedServices, isEmpty);
    expect(third.pendingDeletions.single.accountName, 'نورة الشهري');
    expect(
      third.approveAccountDeletion(third.pendingDeletions.single.id),
      isNull,
    );
    await third.flush();

    final fourth = AppModel(now: () => clock, store: store);
    await fourth.hydrate();
    expect(fourth.clientAccounts, isEmpty);
    expect(fourth.orders, isEmpty);
    expect(fourth.pendingDeletions, isEmpty);
  });

  test('a corrupt shared document is ignored', () {
    expect(SharedSnapshot.tryParse('not-json'), isNull);
    expect(SharedSnapshot.tryParse('{"kind":"other"}'), isNull);
    final fresh = SharedSnapshot.empty();
    final parsed = SharedSnapshot.tryParse(fresh.encode());
    expect(parsed, isNotNull);
    expect(parsed!.services, isEmpty);
    expect(categories, isNotEmpty);
  });
}
