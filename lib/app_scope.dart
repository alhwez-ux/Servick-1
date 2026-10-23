import 'package:flutter/widgets.dart';

import 'data/catalog.dart';
import 'data/phone.dart';
import 'data/providers.dart';
import 'models/models.dart';
import 'models/provider.dart';

class AppModel extends ChangeNotifier {
  AppModel({
    DateTime Function()? now,
    String? city,
    List<ProviderAccount>? providers,
  }) : _now = now ?? DateTime.now,
       _city = city ?? cities.first,
       _providers = List<ProviderAccount>.from(
         providers ?? demoProviders((now ?? DateTime.now)()),
       );

  final DateTime Function() _now;
  String _city;
  final List<ServiceRequest> requests = [];
  final List<ProviderAccount> _providers;
  ProviderAccount? _session;
  int _sequence = 1040;

  String get city => _city;

  DateTime get now => _now();

  List<ProviderAccount> get providers => List.unmodifiable(_providers);

  ProviderAccount? get providerSession => _session;

  ProviderAccount? providerById(String id) {
    for (final account in _providers) {
      if (account.id == id) return account;
    }
    return null;
  }

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

  ProviderLoginResult loginProvider({
    required String phone,
    required String password,
  }) {
    final normalized = normalizeSaudiMobile(phone);
    ProviderAccount? account;
    for (final candidate in _providers) {
      if (candidate.phone == normalized) {
        account = candidate;
        break;
      }
    }
    if (account == null) {
      return const ProviderLoginFailure('رقم الجوال غير مسجل كمزود خدمة');
    }
    if (account.password != password) {
      return const ProviderLoginFailure('كلمة المرور غير صحيحة');
    }
    if (!account.isSubscribedAt(_now())) {
      return ProviderSubscriptionExpired(account);
    }
    _session = account;
    notifyListeners();
    return ProviderLoginSuccess(account);
  }

  void logoutProvider() {
    if (_session == null) return;
    _session = null;
    notifyListeners();
  }

  ProviderAccount? renewSubscription(String providerId) {
    final index = _providers.indexWhere((account) => account.id == providerId);
    if (index < 0) return null;
    final renewed = _providers[index].copyWith(
      subscriptionStatus: 'active',
      subscriptionExpiry: _now().add(
        const Duration(days: annualSubscriptionDays),
      ),
    );
    _providers[index] = renewed;
    _session = renewed;
    notifyListeners();
    return renewed;
  }

  List<ServiceRequest> jobsFor(ProviderAccount account) {
    final technician = findTechnician(account.technicianId);
    return requests.where((request) {
      if (request.technicianId == account.technicianId) return true;
      if (request.technicianId != null || technician == null) return false;
      return request.status == RequestStatus.waiting &&
          request.city == technician.city &&
          request.categoryId == technician.categoryId;
    }).toList();
  }

  bool acceptRequest({
    required String requestId,
    required String technicianId,
  }) {
    final index = requests.indexWhere((request) => request.id == requestId);
    if (index < 0) return false;
    final request = requests[index];
    if (request.status == RequestStatus.completed) return false;
    if (request.technicianId != null && request.technicianId != technicianId) {
      return false;
    }
    requests[index] = request.copyWith(
      technicianId: technicianId,
      status: RequestStatus.assigned,
    );
    notifyListeners();
    return true;
  }

  bool completeRequest({
    required String requestId,
    required String technicianId,
  }) {
    final index = requests.indexWhere((request) => request.id == requestId);
    if (index < 0) return false;
    final request = requests[index];
    if (request.technicianId != technicianId) return false;
    if (request.status != RequestStatus.assigned) return false;
    requests[index] = request.copyWith(status: RequestStatus.completed);
    notifyListeners();
    return true;
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
