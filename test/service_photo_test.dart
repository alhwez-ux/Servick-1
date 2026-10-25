import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:servick/app_scope.dart';
import 'package:servick/data/service_photo.dart';
import 'package:servick/data/shared_store.dart';
import 'package:servick/screens/admin_service_screen.dart';
import 'package:servick/theme/servick_theme.dart';

void main() {
  test('a device photo is cropped to a small square jpeg', () {
    final source = img.Image(width: 40, height: 90);
    img.fill(source, color: img.ColorRgb8(18, 72, 140));
    final png = Uint8List.fromList(img.encodePng(source));
    final jpeg = compressServicePhoto(png);
    expect(jpeg, isNotNull);
    final decoded = img.decodeJpg(jpeg!);
    expect(decoded!.width, servicePhotoEdge);
    expect(decoded.height, servicePhotoEdge);
    expect(compressServicePhoto(Uint8List.fromList(const [1, 2, 3])), isNull);
    expect(isUploadedServicePhoto(servicePhotoDataUri(jpeg)), isTrue);
  });

  test('an uploaded photo is kept and a removed photo stays empty', () async {
    final store = MemorySharedStore();
    final clock = DateTime.utc(2026, 10, 25, 9);
    final model = AppModel(now: () => clock, store: store);
    final jpeg = compressServicePhoto(_samplePng())!;
    final uri = servicePhotoDataUri(jpeg);

    expect(
      model.addService(
        title: 'نقش واجهات',
        subtitle: 'صورة من الجهاز',
        imageData: uri,
      ),
      isNull,
    );
    expect(model.addedServices.single.imageAsset, uri);
    await model.flush();

    final other = AppModel(now: () => clock, store: store);
    await other.hydrate();
    expect(other.addedServices.single.imageAsset, uri);

    expect(other.updateServicePhoto('custom-1', remove: true), isNull);
    expect(other.addedServices.single.imageAsset, isNull);
    await other.flush();

    final third = AppModel(now: () => clock, store: store);
    await third.hydrate();
    expect(third.addedServices.single.imageAsset, isNull);
    expect(third.updateServicePhoto('petrol', remove: true), isNotNull);
  });

  testWidgets('the owner adds a photo from the device and can remove it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final model = AppModel(now: () => DateTime.utc(2026, 10, 25, 9));
    await tester.pumpWidget(
      AppScope(
        model: model,
        child: MaterialApp(
          theme: servickTheme(),
          home: AdminServiceScreen(pickImage: () async => _samplePng()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-service-photo')), findsOneWidget);
    expect(find.byKey(const Key('remove-service-photo')), findsOneWidget);

    await tester.tap(find.byKey(const Key('remove-service-photo')));
    await tester.pump();
    expect(find.byKey(const Key('draft-photo-empty')), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-service-photo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('service-image-draft')), findsOneWidget);
    expect(find.textContaining('صورة من الجهاز'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('service-title')),
      'نقش واجهات',
    );
    await tester.ensureVisible(find.byKey(const Key('save-service')));
    await tester.tap(find.byKey(const Key('save-service')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      model.addedServices.single.imageAsset,
      startsWith(servicePhotoPrefix),
    );
    expect(find.byKey(const Key('add-photo-custom-1')), findsOneWidget);
    expect(find.byKey(const Key('remove-photo-custom-1')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('remove-photo-custom-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('remove-photo-custom-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'إزالة الصورة'));
    await tester.pumpAndSettle();

    expect(model.addedServices.single.imageAsset, isNull);
    expect(find.byKey(const Key('service-image-custom-1')), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('add-photo-custom-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-photo-custom-1')));
    await tester.pumpAndSettle();
    expect(
      model.addedServices.single.imageAsset,
      startsWith(servicePhotoPrefix),
    );
    expect(find.byKey(const Key('service-image-custom-1')), findsOneWidget);
  });
}

Uint8List _samplePng() {
  final source = img.Image(width: 24, height: 36);
  img.fill(source, color: img.ColorRgb8(200, 90, 30));
  return Uint8List.fromList(img.encodePng(source));
}
