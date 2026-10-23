import 'package:flutter/widgets.dart';

import 'data/admin.dart';
import 'data/catalog.dart';
import 'data/orders.dart';
import 'data/order_categories.dart';
import 'data/phone.dart';
import 'data/providers.dart';
import 'data/client_plans.dart';
import 'models/client_subscription.dart';
import 'models/desk.dart';
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
  final List<ProviderRating> _ratings = [];
  final List<OwnerSuggestion> _suggestions = [];
  final Map<String, int> _startingPrices = {};
  final List<DeskMessage> _messages = [];
  final List<ServickInvoice> _invoices = [];
  BillingConfig _billing = const BillingConfig(
    providerAnnualFee: annualSubscriptionFee,
    planPrices: {},
    invoicePrefix: 'SV',
    nextNumber: 1041,
    note: 'فاتورة تجريبية. لا يُخصم مبلغ حقيقي.',
    invoicesEnabled: true,
  );
  int _sequence = 1040;
  int _clientOrderSequence = 0;
  int _suggestionSequence = 0;
  int _messageSequence = 0;
  bool _adminUnlocked = false;

  String get city => _city;

  DateTime get now => _now();

  List<ProviderAccount> get providers => List.unmodifiable(_providers);

  int get orderCount => _orders.length;

  List<ServiceOrder> get orders => List.unmodifiable(_orders);

  List<OwnerSuggestion> get ownerSuggestions => List.unmodifiable(_suggestions);

  BillingConfig get billing => _billing;

  int get providerAnnualFee => _billing.providerAnnualFee;

  List<DeskMessage> get deskMessages => List.unmodifiable(_messages);

  List<ServickInvoice> get invoices => List.unmodifiable(_invoices);

  int startingPriceOf(Technician technician) {
    return _startingPrices[technician.id] ?? technician.startingPrice;
  }

  int planPriceOf(String planId) {
    return _billing.planPrices[planId] ??
        clientPlanById(planId)?.priceAmount ??
        0;
  }

  List<DeskMessage> messagesFor({
    required String audience,
    required String recipientId,
  }) {
    return _messages
        .where(
          (message) =>
              message.audience == audience &&
              message.recipientId == recipientId,
        )
        .toList();
  }

  List<DeskRecipient> deskRecipients(String audience) {
    if (audience == 'provider') {
      return [
        for (final account in _providers)
          DeskRecipient(
            id: account.id,
            audience: 'provider',
            name: findTechnician(account.technicianId)?.name ?? 'حرفي بدون اسم',
            detail: account.phone,
          ),
      ];
    }
    final recipients = <DeskRecipient>[
      const DeskRecipient(
        id: demoClientId,
        audience: 'client',
        name: demoClientName,
        detail: 'العميل الحالي في الجلسة',
      ),
    ];
    final seen = <String>{demoClientName};
    for (final order in _orders) {
      if (!seen.add(order.clientName)) continue;
      recipients.add(
        DeskRecipient(
          id: 'client-name-${order.clientName}',
          audience: 'client',
          name: order.clientName,
          detail: order.city,
        ),
      );
    }
    return recipients;
  }

  List<ProviderAccount> get expiredProviders {
    return _providers
        .where((account) => account.subscriptionStatus == 'expired')
        .toList();
  }

  ProviderAccount? get providerSession => _session;

  bool get adminUnlocked => _adminUnlocked;

  void unlockAdmin() {
    if (_adminUnlocked) return;
    _adminUnlocked = true;
    notifyListeners();
  }

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
    final technician = findTechnician(renewed.technicianId);
    _issueInvoice(
      partyName: technician?.name ?? 'مزود الخدمة',
      title: 'اشتراك الحرفي السنوي',
      amount: providerAnnualFee,
    );
    notifyListeners();
    return renewed;
  }

  String? updateStartingPrice({
    required String technicianId,
    required String raw,
  }) {
    if (findTechnician(technicianId) == null) return 'الفني غير موجود';
    final amount = int.tryParse(raw.trim());
    if (amount == null || amount < 0 || amount > 9999) {
      return 'أدخل سعراً صحيحاً من 0 إلى 9999';
    }
    _startingPrices[technicianId] = amount;
    notifyListeners();
    return null;
  }

  String? updateBilling({
    required String providerFeeRaw,
    required Map<String, String> planPriceRaws,
    required String prefix,
    required String nextNumberRaw,
    required String note,
    required bool invoicesEnabled,
  }) {
    final fee = int.tryParse(providerFeeRaw.trim());
    if (fee == null || fee < 0 || fee > 9999) {
      return 'أدخل رسوم اشتراك الحرفي من 0 إلى 9999';
    }
    final prices = <String, int>{};
    for (final plan in clientPlans.where((plan) => !plan.adminOnly)) {
      final amount = int.tryParse(planPriceRaws[plan.id]?.trim() ?? '');
      if (amount == null || amount < 0 || amount > 9999) {
        return 'أدخل سعر باقة ${plan.title} من 0 إلى 9999';
      }
      prices[plan.id] = amount;
    }
    final trimmedPrefix = prefix.trim();
    if (trimmedPrefix.isEmpty || trimmedPrefix.length > 8) {
      return 'اكتب بادئة الفاتورة في ثمانية أحرف على الأكثر';
    }
    final nextNumber = int.tryParse(nextNumberRaw.trim());
    if (nextNumber == null || nextNumber < 1 || nextNumber > 999999) {
      return 'أدخل رقم الفاتورة التالية من 1 إلى 999999';
    }
    final trimmedNote = note.trim().isEmpty
        ? 'فاتورة تجريبية. لا يُخصم مبلغ حقيقي.'
        : note.trim();
    _billing = BillingConfig(
      providerAnnualFee: fee,
      planPrices: prices,
      invoicePrefix: trimmedPrefix,
      nextNumber: nextNumber,
      note: trimmedNote,
      invoicesEnabled: invoicesEnabled,
    );
    notifyListeners();
    return null;
  }

  String? sendDeskMessage({
    required String audience,
    required String recipientId,
    required String body,
  }) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return 'اكتب نص الرسالة';
    DeskRecipient? recipient;
    for (final candidate in deskRecipients(audience)) {
      if (candidate.id == recipientId) {
        recipient = candidate;
        break;
      }
    }
    if (recipient == null) return 'اختر مستلماً من القائمة';
    _messageSequence += 1;
    _messages.insert(
      0,
      DeskMessage(
        id: 'msg-$_messageSequence',
        audience: audience,
        recipientId: recipient.id,
        recipientName: recipient.name,
        body: trimmed,
        createdAt: _now(),
      ),
    );
    notifyListeners();
    return null;
  }

  void _issueInvoice({
    required String partyName,
    required String title,
    required int amount,
  }) {
    if (!_billing.invoicesEnabled) return;
    final number = _billing.nextNumber;
    _invoices.insert(
      0,
      ServickInvoice(
        id: 'inv-$number',
        number: '${_billing.invoicePrefix}-$number',
        partyName: partyName,
        title: title,
        amount: amount,
        createdAt: _now(),
      ),
    );
    _billing = _billing.copyWith(nextNumber: number + 1);
  }

  String? addOwnerSuggestion({required String area, required String text}) {
    if (!ownerSuggestionAreas.containsKey(area)) return 'اختر موضع التعديل';
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'اكتب ما تريد تعديله أو إضافته';
    _suggestionSequence += 1;
    _suggestions.insert(
      0,
      OwnerSuggestion(
        id: 'sug-$_suggestionSequence',
        area: area,
        text: trimmed,
        createdAt: _now(),
      ),
    );
    notifyListeners();
    return null;
  }

  String? activateProviderSubscription(String providerId) {
    final index = _providers.indexWhere((account) => account.id == providerId);
    if (index < 0) return 'الحرفي غير موجود';
    final activated = _providers[index].copyWith(
      subscriptionStatus: 'active',
      subscriptionExpiry: _now().add(
        const Duration(days: annualSubscriptionDays),
      ),
    );
    _providers[index] = activated;
    if (_session?.id == providerId) _session = activated;
    notifyListeners();
    return null;
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

  ServiceRequest? requestById(String id) {
    for (final request in requests) {
      if (request.id == id) return request;
    }
    return null;
  }

  ProviderRating? ratingForRequest(String requestId) {
    for (final rating in _ratings) {
      if (rating.requestId == requestId) return rating;
    }
    return null;
  }

  double displayRating(Technician technician) {
    final extra = [
      for (final rating in _ratings)
        if (rating.technicianId == technician.id) rating,
    ];
    if (extra.isEmpty) return technician.rating;
    final added = extra.fold<int>(0, (sum, rating) => sum + rating.stars);
    final total = technician.rating * technician.jobs + added;
    return total / (technician.jobs + extra.length);
  }

  int displayJobs(Technician technician) {
    final extra = _ratings
        .where((rating) => rating.technicianId == technician.id)
        .length;
    return technician.jobs + extra;
  }

  CustomerReview displayReview(Technician technician) {
    ProviderRating? latest;
    for (final rating in _ratings) {
      if (rating.technicianId != technician.id) continue;
      if (latest == null || rating.createdAt.isAfter(latest.createdAt)) {
        latest = rating;
      }
    }
    if (latest == null) return technician.review;
    return CustomerReview(
      author: latest.author,
      text: latest.comment,
      stars: latest.stars,
    );
  }

  String? submitRating({
    required String requestId,
    required int stars,
    required String comment,
    String author = 'عميل Servick',
  }) {
    if (stars < 1 || stars > 5) return 'اختر تقييماً من نجمة إلى خمس';
    final request = requestById(requestId);
    if (request == null) return 'الطلب غير موجود';
    final technicianId = request.technicianId;
    if (technicianId == null) return 'لا يوجد مقدم خدمة مرتبط بهذا الطلب';
    if (request.status == RequestStatus.waiting) {
      return 'التقييم متاح بعد توجيه فني';
    }
    if (ratingForRequest(requestId) != null) return 'تم تقييم هذا الطلب من قبل';
    _ratings.add(
      ProviderRating(
        requestId: requestId,
        technicianId: technicianId,
        stars: stars,
        comment: comment.trim().isEmpty ? 'بدون تعليق' : comment.trim(),
        author: author.trim().isEmpty ? 'عميل Servick' : author.trim(),
        createdAt: _now(),
      ),
    );
    notifyListeners();
    return null;
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
    _issueInvoice(
      partyName: clientId == demoClientId ? demoClientName : clientId,
      title: plan.title,
      amount: planPriceOf(plan.id),
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
