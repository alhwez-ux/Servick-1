import 'package:flutter/widgets.dart';

import 'data/phone.dart';
import 'models/models.dart';

class AppModel extends ChangeNotifier {
  AppModel({DateTime Function()? now, String? city})
    : _now = now ?? DateTime.now,
      _city = city ?? cities.first;

  final DateTime Function() _now;
  String _city;
  final List<ServiceRequest> requests = [];
  int _sequence = 1040;

  String get city => _city;

  void setCity(String value) {
    if (value == _city || !cities.contains(value)) return;
    _city = value;
    notifyListeners();
  }

  ServiceRequest submit({
    required RequestKind kind,
    required String categoryId,
    required String city,
    required String summary,
    required String details,
    required String phone,
    required String whenLabel,
    required bool assignNow,
    String? technicianId,
  }) {
    final normalized = normalizeSaudiMobile(phone);
    assert(
      validateSaudiMobile(normalized) == null,
      'Phone number is not a Saudi mobile',
    );
    _sequence += 1;
    final request = ServiceRequest(
      id: 'SV-$_sequence',
      kind: kind,
      categoryId: categoryId,
      technicianId: technicianId,
      city: city,
      summary: summary.trim(),
      details: details.trim(),
      phone: normalized,
      whenLabel: whenLabel,
      createdAt: _now(),
      status: assignNow ? RequestStatus.assigned : RequestStatus.waiting,
    );
    requests.insert(0, request);
    notifyListeners();
    return request;
  }
}

class AppScope extends InheritedNotifier<AppModel> {
  const AppScope({super.key, required AppModel model, required super.child})
    : super(notifier: model);

  static AppModel of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this context');
    return scope!.notifier!;
  }
}
