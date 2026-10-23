import 'package:flutter/widgets.dart';

import 'data/catalog.dart';
import 'data/orders.dart';
import 'data/order_categories.dart';
import 'data/phone.dart';
import 'data/providers.dart';
import 'data/client_plans.dart';
import 'models/client_subscription.dart';
import 'models/models.dart';
import 'models/order.dart';
import 'models/provider.dart';

class AppModel extends ChangeNotifier {
  AppModel({
    DateTime Function()? now,
    String? city,
    List<ProviderAccount>? providers,
    List<ServiceOrder>? orders,
  }) : _now = now ?? DateTime.now,
       _city = city ?? cities.first,
       _providers = List<ProviderAccount>.from(
         providers ?? demoProviders((now ?? DateTime.now)()),
       ),
       _orders = List<ServiceOrder>.from(
         orders ?? demoOrders((now ?? DateTime.now)()),
       );

  final DateTime Function() _now;
  String _city;
  final List<ServiceRequest> requests = [];
  final List<ProviderAccount> _providers;
  final List<ServiceOrder> _orders;
  ProviderAccount? _session;
  final Map<String, ClientSubscription> _clients = {};
  int _sequence = 1040;
  int _clientOrderSequence = 0;

  String get city => _city;

  DateTime get now => _now();

  List<ProviderAccount> get providers => List.unmodifiable(_providers);

  ProviderAccount? get providerSession => _session;

  ClientSubscription? clientSubscription(String clientId) => _clients[clientId];

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
    if (technicianId == null) {
      _orders.insert(
        0,
        ServiceOrder(
          id: 'ord-${request.id}',
          clientName: 'عميل Servick',
          serviceTitle: categoryById(categoryId).title,
          notes: request.details.isEmpty ? request.summary : request.details,
          city: city,
          createdAt: request.createdAt,
          status: 'pending',
          requestId: request.id,
        ),
      );
    }
    notifyListeners();
    return request;
  }

  String? submitClientOrder({
    required String clientId,
    required String clientName,
    required String categoryId,
    required String city,
    required String notes,
  }) {
    if (!cities.contains(city)) return 'المدينة غير معروفة';
    final category = orderCategoryById(categoryId);
    if (category == null) return 'نوع الخدمة غير معروف';
    if (clientId.trim().isEmpty || clientName.trim().isEmpty) {
      return 'بيانات العميل غير مكتملة';
    }
    final trimmed = notes.trim().isEmpty ? 'بدون ملاحظات إضافية' : notes.trim();
    _clientOrderSequence += 1;
    _orders.insert(
      0,
      ServiceOrder(
        id: 'ord-c-$_clientOrderSequence',
        clientId: clientId.trim(),
        clientName: clientName.trim(),
        categoryId: category.id,
        serviceTitle: category.title,
        notes: trimmed,
        city: city,
        createdAt: _now(),
        status: 'pending',
      ),
    );
    notifyListeners();
    return null;
  }

  List<ServiceOrder> pendingOrdersIn(String city) {
    return _orders
        .where((order) => order.city == city && order.status == 'pending')
        .toList();
  }

  String? acceptOrder({required String orderId, required String providerId}) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0) return 'الطلب غير موجود';
    final order = _orders[index];
    if (order.status != 'pending') return 'هذا الطلب لم يعد متاحاً';
    final account = providerById(providerId);
    if (account == null) return 'حساب المزود غير معروف';
    _orders[index] = order.copyWith(status: 'accepted', providerId: providerId);
    final requestId = order.requestId;
    if (requestId != null) {
      acceptRequest(requestId: requestId, technicianId: account.technicianId);
    }
    notifyListeners();
    return null;
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

  String? subscribeClient({
    required String clientId,
    required String planId,
    required int months,
  }) {
    if (clientId.trim().isEmpty) return 'معرّف العميل غير معروف';
    final plan = clientPlanById(planId);
    if (plan == null || plan.months != months) return 'الباقة غير معروفة';
    final expiry = months == 0
        ? _now().add(const Duration(days: 3650))
        : _now().add(Duration(days: months * 30));
    _clients[clientId] = ClientSubscription(
      clientId: clientId,
      status: 'active',
      planId: planId,
      expiry: expiry,
    );
    notifyListeners();
    return null;
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
