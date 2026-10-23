import 'package:flutter_test/flutter_test.dart';
import 'package:servick/app_scope.dart';
import 'package:servick/data/catalog.dart';
import 'package:servick/data/format.dart';
import 'package:servick/data/matching.dart';
import 'package:servick/data/phone.dart';
import 'package:servick/models/models.dart';

void main() {
  test('catalog stays inside the launch cities and categories', () {
    final categoryIds = categories.map((category) => category.id).toSet();
    final technicianIds = <String>{};
    final phones = <String>{};

    for (final technician in technicians) {
      expect(categoryIds, contains(technician.categoryId));
      expect(cities, contains(technician.city));
      expect(technician.phone, matches(RegExp(r'^05\d{8}$')));
      expect(technician.rating, inInclusiveRange(1, 5));
      technicianIds.add(technician.id);
      phones.add(technician.phone);
    }

    expect(technicianIds.length, technicians.length);
    expect(phones.length, technicians.length);

    for (final issue in roadsideIssues) {
      expect(issue.categoryIds, isNotEmpty);
      for (final id in issue.categoryIds) {
        expect(categoryIds, contains(id));
      }
    }
  });

  test('chinese mechanics are not listed in Ahad Rufaidah', () {
    expect(techniciansFor(categoryId: 'chinese', city: 'أحد رفيدة'), isEmpty);
  });

  test('battery emergency in Khamis picks the nearest electrician', () {
    final technician = nearestAvailable(
      city: 'خميس مشيط',
      categoryIds: const ['auto_elec', 'petrol'],
    );
    expect(technician?.id, 'a-km-1');
  });

  test('busy diesel technician in Abha is skipped', () {
    expect(
      nearestAvailable(city: 'أبها', categoryIds: const ['diesel']),
      isNull,
    );
  });

  test('rating order puts the higher score first', () {
    final list = techniciansFor(
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
