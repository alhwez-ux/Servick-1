import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:servick/app_scope.dart';
import 'package:servick/data/catalog.dart';
import 'package:servick/main.dart';
import 'package:servick/models/models.dart';

void main() {
  test('a customer rating updates the craftsman average once', () {
    final now = DateTime.utc(2026, 10, 23, 12);
    final model = AppModel(now: () => now);
    final fahd = findTechnician('p-km-1')!;

    final waiting = model.submit(
      kind: RequestKind.booking,
      categoryId: 'petrol',
      city: 'خميس مشيط',
      summary: 'بانتظار',
      details: 'بانتظار',
      phone: '0551111111',
      whenLabel: 'اليوم',
      assignNow: false,
      technicianId: 'p-km-1',
    );
    expect(
      model.submitRating(requestId: waiting.id, stars: 5, comment: 'جيد'),
      'التقييم متاح بعد توجيه فني',
    );

    final request = model.submit(
      kind: RequestKind.booking,
      categoryId: 'petrol',
      city: 'خميس مشيط',
      summary: 'صوت في المكينة',
      details: 'صوت في المكينة',
      phone: '0551111111',
      whenLabel: 'اليوم',
      assignNow: true,
      technicianId: fahd.id,
    );

    expect(
      model.submitRating(requestId: request.id, stars: 0, comment: 'جيد'),
      'اختر تقييماً من نجمة إلى خمس',
    );
    expect(
      model.submitRating(requestId: 'missing', stars: 4, comment: 'جيد'),
      'الطلب غير موجود',
    );
    expect(
      model.submitRating(requestId: request.id, stars: 5, comment: '   '),
      isNull,
    );

    final saved = model.ratingForRequest(request.id)!;
    expect(saved.stars, 5);
    expect(saved.comment, 'بدون تعليق');
    expect(saved.author, 'عميل Servick');
    expect(saved.createdAt, now);
    expect(
      model.submitRating(requestId: request.id, stars: 4, comment: 'مرة ثانية'),
      'تم تقييم هذا الطلب من قبل',
    );
    expect(model.displayJobs(fahd), fahd.jobs + 1);
    expect(
      model.displayRating(fahd),
      closeTo((fahd.rating * fahd.jobs + 5) / (fahd.jobs + 1), 0.0001),
    );
    expect(model.displayReview(fahd).text, 'بدون تعليق');
    expect(model.displayReview(fahd).stars, 5);
  });

  testWidgets('the customer rates the assigned craftsman after an emergency', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final model = AppModel(now: () => DateTime.utc(2026, 10, 23, 12));
    await tester.pumpWidget(ServickApp(model: model));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-emergency')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('بطارية'));
    await tester.enterText(
      find.byKey(const Key('emergency-place')),
      'طريق الملك فهد عند محطة النخيل',
    );
    await tester.enterText(
      find.byKey(const Key('emergency-phone')),
      '0551234567',
    );
    await tester.ensureVisible(find.byKey(const Key('send-emergency')));
    await tester.tap(find.byKey(const Key('send-emergency')));
    await tester.pumpAndSettle();

    expect(find.text('قيّم مقدم الخدمة'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('submit-rating')));
    await tester.tap(find.byKey(const Key('submit-rating')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('اختر تقييماً من نجمة إلى خمس'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('rating-star-5')));
    await tester.tap(find.byKey(const Key('rating-star-5')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('rating-comment')),
      'وصل بسرعة وصلح البطارية',
    );
    await tester.ensureVisible(find.byKey(const Key('submit-rating')));
    await tester.tap(find.byKey(const Key('submit-rating')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('تم حفظ تقييمك لمقدم الخدمة'), findsOneWidget);
    expect(find.text('تم حفظ تقييمك'), findsOneWidget);
    expect(find.text('وصل بسرعة وصلح البطارية'), findsOneWidget);

    await tester.ensureVisible(find.text('بدر محمد الشهري'));
    await tester.tap(find.text('بدر محمد الشهري'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('latest-review-text')), findsOneWidget);
    expect(find.text('وصل بسرعة وصلح البطارية'), findsOneWidget);
    expect(find.text('5 من 5'), findsWidgets);
    final badr = findTechnician(model.requests.first.technicianId)!;
    expect(model.displayJobs(badr), badr.jobs + 1);
  });
}
