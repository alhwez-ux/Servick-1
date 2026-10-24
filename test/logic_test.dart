import 'package:flutter_test/flutter_test.dart';
import 'package:servick/app_scope.dart';
import 'package:servick/data/catalog.dart';
import 'package:servick/data/format.dart';
import 'package:servick/data/matching.dart';
import 'package:servick/data/phone.dart';
import 'package:servick/models/models.dart';

Technician _person({
  required String id,
  required String categoryId,
  required String city,
  required bool available,
  required int etaMinutes,
  required double rating,
  required int jobs,
}) {
  return Technician(
    id: id,
    name: id,
    categoryId: categoryId,
    city: city,
    rating: rating,
    jobs: jobs,
    years: 5,
    available: available,
    etaMinutes: etaMinutes,
    startingPrice: 80,
    phone: '0550000000',
    about: 'فحص',
    services: const [],
    review: const CustomerReview(author: 'عميل', text: 'جيد'),
  );
}

final _people = [
  _person(
    id: 'p-km-1',
    categoryId: 'petrol',
    city: 'خميس مشيط',
    available: true,
    etaMinutes: 25,
    rating: 4.8,
    jobs: 10,
  ),
  _person(
    id: 'p-km-2',
    categoryId: 'petrol',
    city: 'خميس مشيط',
    available: true,
    etaMinutes: 40,
    rating: 4.6,
    jobs: 8,
  ),
  _person(
    id: 'd-ab-1',
    categoryId: 'diesel',
    city: 'أبها',
    available: false,
    etaMinutes: 20,
    rating: 4.4,
    jobs: 4,
  ),
  _person(
    id: 'a-km-1',
    categoryId: 'auto_elec',
    city: 'خميس مشيط',
    available: true,
    etaMinutes: 12,
    rating: 4.9,
    jobs: 12,
  ),
];

void main() {
  test('the platform starts without seeded accounts', () {
    final model = AppModel();
    expect(model.providers, isEmpty);
    expect(model.technicians, isEmpty);
    expect(model.clientAccounts, isEmpty);
    expect(model.orderCount, 0);

    final categoryIds = categories.map((category) => category.id).toSet();
    for (final issue in roadsideIssues) {
      expect(issue.categoryIds, isNotEmpty);
      for (final id in issue.categoryIds) {
        expect(categoryIds, contains(id));
      }
    }
  });

  test('chinese mechanics are not listed in Ahad Rufaidah', () {
    expect(
      techniciansFor(
        people: _people,
        categoryId: 'chinese',
        city: 'أحد رفيدة',
      ),
      isEmpty,
    );
  });

  test('battery emergency in Khamis picks the nearest electrician', () {
    final technician = nearestAvailable(
      people: _people,
      city: 'خميس مشيط',
      categoryIds: const ['auto_elec', 'petrol'],
    );
    expect(technician?.id, 'a-km-1');
  });

  test('busy diesel technician in Abha is skipped', () {
    expect(
      nearestAvailable(
        people: _people,
        city: 'أبها',
        categoryIds: const ['diesel'],
      ),
      isNull,
    );
  });

  test('rating order puts the higher score first', () {
    final list = techniciansFor(
      people: _people,
      categoryId: 'petrol',
      city: 'خميس مشيط',
      order: TechnicianSort.rating,
    );
    expect(list.first.id, 'p-km-1');
    expect(list.last.id, 'p-km-2');
  });

  test('saudi mobiles accept local and international forms', () {
    expect(validateSaudiMobile('055'), isNotNull);
    expect(validateSaudiMobile('0551234567'), isNull);
    expect(validateSaudiMobile('+966551234567'), isNull);
    expect(validateSaudiMobile('055 123 4567'), isNull);
    expect(normalizeSaudiMobile('+966 55 123 4567'), '0551234567');
    expect(normalizeSaudiMobile('0551234567'), '0551234567');
  });

  test('times and phones stay left-to-right inside Arabic text', () {
    expect(
      formatRiyadh(DateTime.utc(2026, 10, 23, 14, 5)),
      '23 أكتوبر · \u202A17:05\u202C',
    );
    expect(formatPhone('0554102213'), '\u202A055 410 2213\u202C');
    expect(
      formatSubscriptionDate(DateTime.utc(2026, 10, 23, 21)),
      '\u202A2026/10/24\u202C',
    );
  });

  test('requests are numbered and newest stays first', () {
    final model = AppModel(now: () => DateTime.utc(2026, 10, 23, 14, 30));
    final first = model.submit(
      kind: RequestKind.emergency,
      categoryId: 'auto_elec',
      city: 'خميس مشيط',
      summary: 'بطارية',
      details: 'الموقع: النخيل',
      phone: '0551234567',
      whenLabel: 'فوراً',
      assignNow: true,
      technicianId: 'a-km-1',
    );
    final second = model.submit(
      kind: RequestKind.booking,
      categoryId: 'petrol',
      city: 'أبها',
      summary: 'صوت في المكينة',
      details: 'صوت في المكينة',
      phone: '+966551112233',
      whenLabel: 'غداً',
      assignNow: false,
      technicianId: 'p-ab-1',
    );

    expect(first.id, 'SV-1041');
    expect(first.phone, '0551234567');
    expect(first.status, RequestStatus.assigned);
    expect(second.id, 'SV-1042');
    expect(second.phone, '0551112233');
    expect(second.status, RequestStatus.waiting);
    expect(model.requests.map((request) => request.id), ['SV-1042', 'SV-1041']);
  });
}
