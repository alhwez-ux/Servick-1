import 'dart:math';

import 'package:flutter/material.dart';

import 'data/admin.dart';
import 'data/mail.dart';
import 'data/catalog.dart';
import 'data/matching.dart' as matching;
import 'data/order_categories.dart';
import 'data/password_hash.dart';
import 'data/phone.dart';
import 'data/providers.dart';
import 'data/service_photo.dart';
import 'data/service_pictures.dart';
import 'data/shared_snapshot.dart';
import 'data/shared_store.dart';
import 'data/client_plans.dart';
import 'models/client_subscription.dart';
import 'models/desk.dart';
import 'models/models.dart';
import 'models/order.dart';
import 'models/provider.dart';
import 'models/supervisor.dart';

class AppModel extends ChangeNotifier {
  AppModel({
    DateTime Function()? now,
    String? city,
    List<ProviderAccount>? providers,
    List<Technician>? technicians,
    List<ServiceOrder>? orders,
    SharedStore? store,
    Future<bool> Function(PasswordMail mail)? mailer,
    String Function()? temporaryPassword,
  }) : _now = now ?? DateTime.now,
       _mailer = mailer ?? postPasswordMail,
       _temporaryPassword = temporaryPassword ?? _randomPassword,
       _city = city ?? cities.first,
       _providers = List<ProviderAccount>.from(providers ?? const []),
       _technicians = List<Technician>.from(technicians ?? const []),
       _orders = List<ServiceOrder>.from(orders ?? const []),
       _store = store ?? MemorySharedStore();

  final DateTime Function() _now;
  final SharedStore _store;
  final Future<bool> Function(PasswordMail mail) _mailer;
  final String Function() _temporaryPassword;
  SharedSnapshot _base = SharedSnapshot.empty();
  Future<void>? _saveChain;
  String? syncError;
  String _city;
  final List<ServiceRequest> requests = [];
  final List<ProviderAccount> _providers;
  final List<Technician> _technicians;
  final List<ClientAccount> _clientAccounts = [];
  final List<ServiceOrder> _orders;
  final List<AccountDeletionRequest> _deletionRequests = [];
  ProviderAccount? _session;
  ClientAccount? _clientSession;
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
  int _serviceSequence = 0;
  int _clientSequence = 0;
  int _providerSequence = 0;
  int _technicianSequence = 0;
  int _deletionSequence = 0;
  String? _adminRole;
  final List<SupervisorAccount> _supervisors = [];
  var _supervisorSequence = 0;
  bool _clientPrivacyAccepted = false;
  bool _providerPrivacyAccepted = false;
  final List<ServiceCategory> _extraCategories = [];
  String _ownerEmail = '';
  String _ownerPasswordHash = '';
  String _ownerPasswordSalt = '';

  String get ownerEmail => _ownerEmail;

  bool get ownerUsesDemoPasscode =>
      _ownerPasswordHash.isEmpty || _ownerPasswordSalt.isEmpty;

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
            name:
                technicianById(account.technicianId)?.name ??
                'مقدم خدمة بدون اسم',
            detail: account.phone,
          ),
      ];
    }
    final recipients = <DeskRecipient>[
      for (final account in _clientAccounts)
        DeskRecipient(
          id: account.id,
          audience: 'client',
          name: account.name,
          detail: account.phone,
        ),
    ];
    final seen = {for (final account in _clientAccounts) account.id};
    for (final order in _orders) {
      final id = order.clientId;
      if (id == null || !seen.add(id)) continue;
      recipients.add(
        DeskRecipient(
          id: id,
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

  ClientAccount? get clientSession => _clientSession;

  List<ClientAccount> get clientAccounts => List.unmodifiable(_clientAccounts);

  List<Technician> get technicians => List.unmodifiable(_technicians);

  List<AccountDeletionRequest> get deletionRequests =>
      List.unmodifiable(_deletionRequests);

  List<AccountDeletionRequest> get pendingDeletions => _deletionRequests
      .where((request) => request.status == 'pending')
      .toList();

  bool get adminUnlocked => _adminRole != null;

  bool get isOwner => _adminRole == 'owner';

  List<SupervisorAccount> get supervisors => List.unmodifiable(_supervisors);

  bool get clientPrivacyAccepted => _clientPrivacyAccepted;

  bool get providerPrivacyAccepted => _providerPrivacyAccepted;

  List<ServiceCategory> get serviceCategories => [
    ...categories,
    ..._extraCategories,
  ];

  List<ServiceCategory> get addedServices =>
      List.unmodifiable(_extraCategories);

  List<Technician> get listedTechnicians => [
    for (final technician in _technicians)
      if (_isListed(technician)) technician,
  ];

  Technician? technicianById(String? id) => lookupTechnician(id, _technicians);

  List<Technician> techniciansFor({
    required String categoryId,
    required String city,
    matching.TechnicianSort order = matching.TechnicianSort.nearest,
  }) {
    return matching.techniciansFor(
      people: listedTechnicians,
      categoryId: categoryId,
      city: city,
      order: order,
      ratingOf: displayRating,
    );
  }

  int technicianCount({
    required String categoryId,
    required String city,
    bool availableOnly = false,
  }) {
    return matching.technicianCount(
      people: listedTechnicians,
      categoryId: categoryId,
      city: city,
      availableOnly: availableOnly,
    );
  }

  List<Technician> availableInCity(String city) {
    return matching.availableInCity(listedTechnicians, city);
  }

  Technician? nearestAvailable({
    required String city,
    required List<String> categoryIds,
  }) {
    return matching.nearestAvailable(
      people: listedTechnicians,
      city: city,
      categoryIds: categoryIds,
    );
  }

  List<({String city, int count})> otherCitiesWithTechnicians({
    required String categoryId,
    required String currentCity,
  }) {
    return matching.otherCitiesWithTechnicians(
      people: listedTechnicians,
      categoryId: categoryId,
      currentCity: currentCity,
    );
  }

  bool _isListed(Technician technician) {
    if (!technician.available) return false;
    final account = providerByTechnician(technician.id);
    if (account == null) return false;
    if (account.isSubscribedAt(_now())) return true;
    final phase = providerComplimentaryPhase(account);
    return phase == ComplimentaryPhase.open ||
        phase == ComplimentaryPhase.warning;
  }

  ServiceCategory? categoryOf(String id) {
    for (final category in serviceCategories) {
      if (category.id == id) return category;
    }
    return null;
  }

  void acceptPrivacy({required String audience}) {
    if (audience == 'provider') {
      _providerPrivacyAccepted = true;
    } else {
      _clientPrivacyAccepted = true;
    }
    notifyListeners();
  }

  String? addService({
    required String title,
    required String subtitle,
    String? pictureId,
    String? imageData,
    bool withoutImage = false,
  }) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return 'اكتب اسم الخدمة';
    if (cleanTitle.length > 40) return 'اسم الخدمة أطول من أربعين حرفاً';
    final duplicate = serviceCategories.any(
      (category) => category.title == cleanTitle,
    );
    if (duplicate) return 'هذه الخدمة موجودة';
    final cleanSubtitle = subtitle.trim().isEmpty
        ? 'خدمة أضافها المالك'
        : subtitle.trim();
    if (cleanSubtitle.length > serviceSubtitleMaxLength) {
      return 'الوصف أطول من ثمانين حرفاً';
    }
    final imageError = _photoChoice(imageData);
    if (imageData != null && imageError != null) return imageError;
    _serviceSequence += 1;
    const colors = <Color>[
      Color(0xFF1E3A8A),
      Color(0xFF0F766E),
      Color(0xFFB45309),
      Color(0xFF7C3AED),
    ];
    const icons = <IconData>[
      Icons.home_repair_service,
      Icons.handyman,
      Icons.build_circle,
      Icons.plumbing,
    ];
    final slot = (_serviceSequence - 1) % colors.length;
    final picture = pictureId == null
        ? pictureForTitle(cleanTitle)
        : servicePictureById(pictureId);
    final String? image;
    if (imageData != null) {
      image = imageData;
    } else if (withoutImage) {
      image = null;
    } else {
      image = picture.asset;
    }
    _extraCategories.add(
      ServiceCategory(
        id: 'custom-$_serviceSequence',
        title: cleanTitle,
        subtitle: cleanSubtitle,
        icon: icons[slot],
        color: colors[slot],
        imageAsset: image,
      ),
    );
    _touch();
    return null;
  }

  String? updateServicePhoto(
    String id, {
    String? imageData,
    bool remove = false,
  }) {
    if (categories.any((category) => category.id == id)) {
      return 'لا يمكن تغيير صورة الخدمات الأساسية من هنا';
    }
    final index = _extraCategories.indexWhere((category) => category.id == id);
    if (index < 0) return 'الخدمة غير موجودة';
    final current = _extraCategories[index];
    final String? next;
    if (remove) {
      next = null;
    } else {
      final imageError = _photoChoice(imageData);
      if (imageError != null) return imageError;
      next = imageData;
    }
    _extraCategories[index] = ServiceCategory(
      id: current.id,
      title: current.title,
      subtitle: current.subtitle,
      icon: current.icon,
      color: current.color,
      imageAsset: next,
    );
    _touch();
    return null;
  }

  String? _photoChoice(String? imageData) {
    if (imageData == null || !isUploadedServicePhoto(imageData)) {
      return 'الصورة غير صالحة';
    }
    if (imageData.length > maxServicePhotoUriLength) {
      return 'الصورة أكبر من الحجم المناسب';
    }
    if (servicePhotoBytes(imageData) == null) return 'الصورة غير صالحة';
    return null;
  }

  String? removeService(String id) {
    if (categories.any((category) => category.id == id)) {
      return 'لا يمكن حذف الخدمات الأساسية';
    }
    final removed = _extraCategories.length;
    _extraCategories.removeWhere((category) => category.id == id);
    if (_extraCategories.length == removed) return 'الخدمة غير موجودة';
    _touch();
    return null;
  }

  void unlockAdmin({String role = 'owner'}) {
    _adminRole = role;
    notifyListeners();
    _enqueue(_refresh);
  }

  /// Owner and supervisors sign in from the main login.
  /// Returns `owner` or `supervisor` on success, an error when the phone
  /// belongs to staff but the password does not, and null for other phones.
  String? loginPortal({required String phone, required String password}) {
    final phoneError = validateSaudiMobile(phone);
    if (phoneError != null) return phoneError;
    final normalized = normalizeSaudiMobile(phone);
    if (normalized == ownerMobile) {
      if (!ownerPasswordMatches(password)) return 'كلمة المرور غير صحيحة';
      unlockAdmin(role: 'owner');
      return 'owner';
    }
    final supervisor = supervisorByPhone(normalized);
    if (supervisor == null) return null;
    if (!supervisor.matchesPassword(password)) return 'كلمة المرور غير صحيحة';
    unlockAdmin(role: 'supervisor');
    return 'supervisor';
  }

  SupervisorAccount? supervisorByPhone(String phone) {
    final normalized = normalizeSaudiMobile(phone);
    for (final account in _supervisors) {
      if (account.phone == normalized) return account;
    }
    return null;
  }

  String? addSupervisor({
    required String name,
    required String phone,
    required String password,
    String email = '',
  }) {
    if (_adminRole == 'supervisor') return 'إضافة المشرفين للمالك فقط';
    final cleanName = name.trim();
    if (cleanName.isEmpty) return 'اكتب الاسم';
    if (cleanName.length > 40) return 'الاسم أطول من أربعين حرفاً';
    final phoneError = validateSaudiMobile(phone);
    if (phoneError != null) return phoneError;
    if (password.trim().length < 6) return 'كلمة المرور ستة أحرف على الأقل';
    final cleanEmail = foldEmail(email);
    if (cleanEmail.isNotEmpty) {
      final emailError = validateAccountEmail(cleanEmail);
      if (emailError != null) return emailError;
      if (_emailTaken(cleanEmail)) return 'هذا البريد مسجّل من قبل';
    }
    final normalized = normalizeSaudiMobile(phone);
    if (_phoneTaken(normalized)) return 'هذا الجوال مسجّل من قبل';
    _supervisorSequence += 1;
    final salt = newSalt();
    _supervisors.add(
      SupervisorAccount(
        id: 'sup-$_supervisorSequence',
        name: cleanName,
        phone: normalized,
        passwordHash: hashPassword(password.trim(), salt),
        passwordSalt: salt,
        email: cleanEmail,
        createdAt: _now(),
      ),
    );
    _touch();
    return null;
  }

  String? removeSupervisor(String id) {
    if (_adminRole == 'supervisor') return 'حذف المشرفين للمالك فقط';
    final removed = _supervisors.length;
    _supervisors.removeWhere((account) => account.id == id);
    if (_supervisors.length == removed) return 'المشرف غير موجود';
    _touch();
    return null;
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
    String? clientId,
    String clientName = 'عميل رابط',
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
      clientId: clientId,
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
          clientId: clientId,
          clientName: clientName,
          serviceTitle: categoryOf(categoryId)?.title ?? categoryId,
          notes: request.details.isEmpty ? request.summary : request.details,
          city: city,
          createdAt: request.createdAt,
          status: 'pending',
          requestId: request.id,
        ),
      );
    }
    _touch();
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
    _touch();
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
    _touch();
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
    if (!account.matchesPassword(password)) {
      return const ProviderLoginFailure('كلمة المرور غير صحيحة');
    }
    if (!account.isSubscribedAt(_now())) {
      final phase = providerComplimentaryPhase(account);
      if (phase == ComplimentaryPhase.open ||
          phase == ComplimentaryPhase.warning) {
        _session = account;
        notifyListeners();
        return ProviderLoginSuccess(account);
      }
      if (phase == ComplimentaryPhase.ended) {
        return ProviderFreePeriodEnded(account);
      }
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
    final technician = technicianById(renewed.technicianId);
    _issueInvoice(
      partyName: technician?.name ?? 'مزود الخدمة',
      title: 'اشتراك مقدم الخدمة السنوي',
      amount: providerAnnualFee,
    );
    _touch();
    return renewed;
  }

  String? updateStartingPrice({
    required String technicianId,
    required String raw,
  }) {
    if (technicianById(technicianId) == null) return 'الفني غير موجود';
    final amount = int.tryParse(raw.trim());
    if (amount == null || amount < 0 || amount > 9999) {
      return 'أدخل سعراً صحيحاً من 0 إلى 9999';
    }
    _startingPrices[technicianId] = amount;
    _touch();
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
      return 'أدخل رسوم اشتراك مقدم الخدمة من 0 إلى 9999';
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
      providerFreeMonths: _billing.providerFreeMonths,
      clientFreeMonths: _billing.clientFreeMonths,
      providerFreeAnchor: _billing.providerFreeAnchor,
      clientFreeAnchor: _billing.clientFreeAnchor,
    );
    _touch();
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
    _touch();
    return null;
  }

  bool ownerPasswordMatches(String raw) {
    final password = raw.trim();
    if (_ownerPasswordHash.isEmpty || _ownerPasswordSalt.isEmpty) {
      return password == demoAdminPasscode;
    }
    return hashPassword(password, _ownerPasswordSalt) == _ownerPasswordHash;
  }

  String? changeClientPassword({
    required String clientId,
    required String current,
    required String next,
    String? email,
  }) {
    final index = _clientAccounts.indexWhere(
      (account) => account.id == clientId,
    );
    if (index < 0) return 'الحساب غير موجود';
    return _replaceClient(
      index,
      _nextCredentials(
        account: _clientAccounts[index],
        current: current,
        next: next,
        email: email,
      ),
    );
  }

  String? changeProviderPassword({
    required String providerId,
    required String current,
    required String next,
    String? email,
  }) {
    final index = _providers.indexWhere((account) => account.id == providerId);
    if (index < 0) return 'الحساب غير موجود';
    final account = _providers[index];
    if (!account.matchesPassword(current)) {
      return 'كلمة المرور الحالية غير صحيحة';
    }
    if (next.trim().length < 6) return 'كلمة المرور ستة أحرف على الأقل';
    final emailError = _emailUpdate(account.email, email);
    if (emailError != null) return emailError;
    final salt = newSalt();
    final updated = account.copyWith(
      passwordHash: hashPassword(next.trim(), salt),
      passwordSalt: salt,
      email: email == null ? account.email : foldEmail(email),
    );
    _providers[index] = updated;
    if (_session?.id == updated.id) _session = updated;
    _touch();
    return null;
  }

  String? changeOwnerPassword({
    required String current,
    required String next,
    String? email,
  }) {
    if (!ownerPasswordMatches(current)) return 'كلمة المرور الحالية غير صحيحة';
    if (next.trim().length < 6) return 'كلمة المرور ستة أحرف على الأقل';
    final emailError = _emailUpdate(_ownerEmail, email);
    if (emailError != null) return emailError;
    final salt = newSalt();
    _ownerPasswordSalt = salt;
    _ownerPasswordHash = hashPassword(next.trim(), salt);
    if (email != null) _ownerEmail = foldEmail(email);
    _touch();
    return null;
  }

  Future<PasswordResetResult> resetPasswordByEmail({
    required String audience,
    required String email,
  }) async {
    final clean = foldEmail(email);
    final emailError = validateAccountEmail(clean);
    if (emailError != null) {
      return PasswordResetResult(error: emailError);
    }
    final temporary = _temporaryPassword();
    final salt = newSalt();
    final hash = hashPassword(temporary, salt);
    if (audience == 'owner') {
      if (_ownerEmail.isEmpty) {
        return const PasswordResetResult(
          error: 'لا يوجد بريد مسجّل للمالك. أضفه من لوحة التحكم بعد الدخول.',
        );
      }
      if (foldEmail(_ownerEmail) != clean) {
        return const PasswordResetResult(error: 'لا يوجد حساب بهذا البريد');
      }
      _ownerPasswordSalt = salt;
      _ownerPasswordHash = hash;
    } else if (audience == 'provider') {
      final index = _providers.indexWhere(
        (account) => foldEmail(account.email) == clean,
      );
      if (index < 0) {
        return const PasswordResetResult(error: 'لا يوجد حساب بهذا البريد');
      }
      final updated = _providers[index].copyWith(
        passwordHash: hash,
        passwordSalt: salt,
      );
      _providers[index] = updated;
      if (_session?.id == updated.id) _session = updated;
    } else {
      final index = _clientAccounts.indexWhere(
        (account) => foldEmail(account.email) == clean,
      );
      if (index < 0) {
        return const PasswordResetResult(error: 'لا يوجد حساب بهذا البريد');
      }
      final updated = _clientAccounts[index].copyWith(
        passwordHash: hash,
        passwordSalt: salt,
      );
      _clientAccounts[index] = updated;
      if (_clientSession?.id == updated.id) _clientSession = updated;
    }
    _touch();
    var mailed = false;
    try {
      mailed = await _mailer(
        PasswordMail(
          to: clean,
          subject: 'كلمة المرور المؤقتة | رابط',
          text:
              'كلمة المرور المؤقتة لحسابك في رابط: $temporary\nغيّرها بعد الدخول.',
        ),
      );
    } catch (_) {
      mailed = false;
    }
    return PasswordResetResult(
      mailed: mailed,
      temporary: mailed ? null : temporary,
    );
  }

  String? _replaceClient(int index, Object result) {
    if (result is String) return result;
    final updated = result as ClientAccount;
    _clientAccounts[index] = updated;
    if (_clientSession?.id == updated.id) _clientSession = updated;
    _touch();
    return null;
  }

  Object _nextCredentials({
    required ClientAccount account,
    required String current,
    required String next,
    String? email,
  }) {
    if (!account.matchesPassword(current)) {
      return 'كلمة المرور الحالية غير صحيحة';
    }
    if (next.trim().length < 6) return 'كلمة المرور ستة أحرف على الأقل';
    final emailError = _emailUpdate(account.email, email);
    if (emailError != null) return emailError;
    final salt = newSalt();
    return account.copyWith(
      passwordHash: hashPassword(next.trim(), salt),
      passwordSalt: salt,
      email: email == null ? account.email : foldEmail(email),
    );
  }

  String? _emailUpdate(String current, String? email) {
    if (email == null) return null;
    final clean = foldEmail(email);
    if (clean.isEmpty) return 'اكتب البريد الإلكتروني';
    final error = validateAccountEmail(clean);
    if (error != null) return error;
    if (foldEmail(current) == clean) return null;
    if (_emailTaken(clean)) return 'هذا البريد مسجّل من قبل';
    return null;
  }

  bool _emailTaken(String email) {
    final clean = foldEmail(email);
    if (clean.isEmpty) return false;
    if (foldEmail(_ownerEmail) == clean) return true;
    for (final account in _clientAccounts) {
      if (foldEmail(account.email) == clean) return true;
    }
    for (final account in _providers) {
      if (foldEmail(account.email) == clean) return true;
    }
    for (final account in _supervisors) {
      if (foldEmail(account.email) == clean) return true;
    }
    return false;
  }

  String? removeDeskMessage(String id) {
    final removed = _messages.length;
    _messages.removeWhere((message) => message.id == id);
    if (_messages.length == removed) return 'الرسالة غير موجودة';
    _touch();
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
    _touch();
    return null;
  }

  String? removeOwnerSuggestion(String id) {
    final removed = _suggestions.length;
    _suggestions.removeWhere((suggestion) => suggestion.id == id);
    if (_suggestions.length == removed) return 'الاقتراح غير موجود';
    _touch();
    return null;
  }

  String? activateProviderSubscription(String providerId) {
    final index = _providers.indexWhere((account) => account.id == providerId);
    if (index < 0) return 'مقدم الخدمة غير موجود';
    final activated = _providers[index].copyWith(
      subscriptionStatus: 'active',
      subscriptionExpiry: _now().add(
        const Duration(days: annualSubscriptionDays),
      ),
    );
    _providers[index] = activated;
    if (_session?.id == providerId) _session = activated;
    _touch();
    return null;
  }

  List<ServiceRequest> jobsFor(ProviderAccount account) {
    final technician = technicianById(account.technicianId);
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
    _touch();
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
    String author = 'عميل رابط',
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
        author: author.trim().isEmpty ? 'عميل رابط' : author.trim(),
        createdAt: _now(),
      ),
    );
    _touch();
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
    _touch();
    return true;
  }

  DateTime? complimentaryEnd({required bool forProvider}) {
    final months = forProvider
        ? _billing.providerFreeMonths
        : _billing.clientFreeMonths;
    final anchor = forProvider
        ? _billing.providerFreeAnchor
        : _billing.clientFreeAnchor;
    if (months <= 0 || anchor == null) return null;
    return anchor.add(Duration(days: months * freeMonthDays));
  }

  ComplimentaryPhase complimentaryPhase({
    required bool paid,
    required DateTime? end,
  }) {
    if (paid || end == null) return ComplimentaryPhase.inactive;
    final now = _now();
    if (!now.isBefore(end)) return ComplimentaryPhase.ended;
    final warningStart = end.subtract(
      const Duration(days: complimentaryWarningDays),
    );
    if (!now.isBefore(warningStart)) return ComplimentaryPhase.warning;
    return ComplimentaryPhase.open;
  }

  ComplimentaryPhase providerComplimentaryPhase(ProviderAccount account) {
    return complimentaryPhase(
      paid: account.isSubscribedAt(_now()),
      end: complimentaryEnd(forProvider: true),
    );
  }

  ComplimentaryPhase clientComplimentaryPhase(String clientId) {
    final subscription = _clients[clientId];
    return complimentaryPhase(
      paid: subscription != null && subscription.isActiveAt(_now()),
      end: complimentaryEnd(forProvider: false),
    );
  }

  String? clientServiceBlock(String clientId) {
    if (clientComplimentaryPhase(clientId) != ComplimentaryPhase.ended) {
      return null;
    }
    return complimentaryEndedText;
  }

  String? updateFreeMonths({
    required String providerRaw,
    required String clientRaw,
  }) {
    final providerMonths = int.tryParse(providerRaw.trim());
    final clientMonths = int.tryParse(clientRaw.trim());
    if (providerMonths == null || providerMonths < 0 || providerMonths > 24) {
      return 'أدخل المدة المجانية لمقدم الخدمة من 0 إلى 24 شهراً';
    }
    if (clientMonths == null || clientMonths < 0 || clientMonths > 24) {
      return 'أدخل المدة المجانية للعميل من 0 إلى 24 شهراً';
    }
    final now = _now();
    final providerAnchor = providerMonths == 0
        ? null
        : providerMonths == _billing.providerFreeMonths &&
              _billing.providerFreeAnchor != null
        ? _billing.providerFreeAnchor
        : now;
    final clientAnchor = clientMonths == 0
        ? null
        : clientMonths == _billing.clientFreeMonths &&
              _billing.clientFreeAnchor != null
        ? _billing.clientFreeAnchor
        : now;
    _billing = BillingConfig(
      providerAnnualFee: _billing.providerAnnualFee,
      planPrices: _billing.planPrices,
      invoicePrefix: _billing.invoicePrefix,
      nextNumber: _billing.nextNumber,
      note: _billing.note,
      invoicesEnabled: _billing.invoicesEnabled,
      providerFreeMonths: providerMonths,
      clientFreeMonths: clientMonths,
      providerFreeAnchor: providerAnchor,
      clientFreeAnchor: clientAnchor,
    );
    _touch();
    return null;
  }

  void ensureComplimentaryNotice({
    required String audience,
    required String recipientId,
  }) {
    final ComplimentaryPhase phase;
    if (audience == 'provider') {
      final account = providerById(recipientId);
      if (account == null) return;
      phase = providerComplimentaryPhase(account);
    } else {
      phase = clientComplimentaryPhase(recipientId);
    }
    if (phase != ComplimentaryPhase.warning) return;
    final id = 'free-warn-$audience-$recipientId';
    if (_messages.any((message) => message.id == id)) return;
    final name = audience == 'provider'
        ? technicianById(providerById(recipientId)?.technicianId)?.name ??
              'مقدم الخدمة'
        : clientById(recipientId)?.name ??
              (recipientId == demoClientId ? demoClientName : 'العميل');
    _messages.insert(
      0,
      DeskMessage(
        id: id,
        audience: audience,
        recipientId: recipientId,
        recipientName: name,
        body: complimentaryWarningText,
        createdAt: _now(),
      ),
    );
    _touch();
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
      partyName: _clientLabel(clientId),
      title: plan.title,
      amount: planPriceOf(plan.id),
    );
    _touch();
    return null;
  }

  String _clientLabel(String clientId) {
    return clientById(clientId)?.name ??
        (clientId == demoClientId ? demoClientName : clientId);
  }

  ClientAccount? clientById(String id) {
    for (final account in _clientAccounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  ClientAccount? clientByPhone(String phone) {
    final normalized = normalizeSaudiMobile(phone);
    for (final account in _clientAccounts) {
      if (account.phone == normalized) return account;
    }
    return null;
  }

  ProviderAccount? providerByPhone(String phone) {
    final normalized = normalizeSaudiMobile(phone);
    for (final account in _providers) {
      if (account.phone == normalized) return account;
    }
    return null;
  }

  ProviderAccount? providerByTechnician(String technicianId) {
    for (final account in _providers) {
      if (account.technicianId == technicianId) return account;
    }
    return null;
  }

  bool _phoneTaken(String phone) {
    final normalized = normalizeSaudiMobile(phone);
    if (normalized == ownerMobile) return true;
    return clientByPhone(phone) != null ||
        providerByPhone(phone) != null ||
        supervisorByPhone(phone) != null;
  }

  String? registerClient({
    required String name,
    required String phone,
    required String city,
    required String password,
    String email = '',
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return 'اكتب الاسم';
    if (cleanName.length > 40) return 'الاسم أطول من أربعين حرفاً';
    final phoneError = validateSaudiMobile(phone);
    if (phoneError != null) return phoneError;
    if (!cities.contains(city)) return 'المدينة غير معروفة';
    if (password.trim().length < 6) return 'كلمة المرور ستة أحرف على الأقل';
    final cleanEmail = foldEmail(email);
    if (cleanEmail.isNotEmpty) {
      final emailError = validateAccountEmail(cleanEmail);
      if (emailError != null) return emailError;
      if (_emailTaken(cleanEmail)) return 'هذا البريد مسجّل من قبل';
    }
    final normalized = normalizeSaudiMobile(phone);
    if (_phoneTaken(normalized)) return 'هذا الجوال مسجّل من قبل';
    _clientSequence += 1;
    final salt = newSalt();
    _clientAccounts.add(
      ClientAccount(
        id: 'client-$_clientSequence',
        name: cleanName,
        phone: normalized,
        city: city,
        passwordHash: hashPassword(password.trim(), salt),
        passwordSalt: salt,
        createdAt: _now(),
        email: cleanEmail,
      ),
    );
    _touch();
    return null;
  }

  String? loginClient({required String phone, required String password}) {
    final account = clientByPhone(phone);
    if (account == null) return 'رقم الجوال غير مسجّل';
    if (!account.matchesPassword(password)) return 'كلمة المرور غير صحيحة';
    _clientSession = account;
    if (cities.contains(account.city)) _city = account.city;
    notifyListeners();
    return null;
  }

  void logoutClient() {
    if (_clientSession == null) return;
    _clientSession = null;
    notifyListeners();
  }

  String? registerProvider({
    required String name,
    required String phone,
    required String city,
    required String categoryId,
    required String password,
    String about = '',
    String email = '',
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return 'اكتب الاسم';
    if (cleanName.length > 40) return 'الاسم أطول من أربعين حرفاً';
    final phoneError = validateSaudiMobile(phone);
    if (phoneError != null) return phoneError;
    if (!cities.contains(city)) return 'المدينة غير معروفة';
    if (categoryOf(categoryId) == null) return 'نوع الخدمة غير معروف';
    if (password.trim().length < 6) return 'كلمة المرور ستة أحرف على الأقل';
    final cleanEmail = foldEmail(email);
    if (cleanEmail.isNotEmpty) {
      final emailError = validateAccountEmail(cleanEmail);
      if (emailError != null) return emailError;
      if (_emailTaken(cleanEmail)) return 'هذا البريد مسجّل من قبل';
    }
    final normalized = normalizeSaudiMobile(phone);
    if (_phoneTaken(normalized)) return 'هذا الجوال مسجّل من قبل';
    _providerSequence += 1;
    _technicianSequence += 1;
    final salt = newSalt();
    final technicianId = 'tech-$_technicianSequence';
    _technicians.add(
      Technician(
        id: technicianId,
        name: cleanName,
        categoryId: categoryId,
        city: city,
        rating: 0,
        jobs: 0,
        years: 0,
        available: true,
        etaMinutes: 30,
        startingPrice: 0,
        phone: normalized,
        about: about.trim().isEmpty ? 'مقدم خدمة مسجّل في رابط' : about.trim(),
        services: const [],
        review: const CustomerReview(
          author: 'رابط',
          text: 'لا توجد تقييمات بعد.',
        ),
      ),
    );
    _providers.add(
      ProviderAccount(
        id: 'prov-$_providerSequence',
        technicianId: technicianId,
        phone: normalized,
        passwordHash: hashPassword(password.trim(), salt),
        passwordSalt: salt,
        subscriptionStatus: 'expired',
        subscriptionExpiry: _now().subtract(const Duration(days: 1)),
        email: cleanEmail,
      ),
    );
    _touch();
    return null;
  }

  AccountDeletionRequest? deletionRequestFor({
    required String audience,
    required String accountId,
  }) {
    for (final request in _deletionRequests) {
      if (request.audience == audience &&
          request.accountId == accountId &&
          request.status == 'pending') {
        return request;
      }
    }
    return null;
  }

  String? requestAccountDeletion({
    required String audience,
    required String accountId,
  }) {
    if (deletionRequestFor(audience: audience, accountId: accountId) != null) {
      return 'طلب حذف الحساب بانتظار موافقة المالك';
    }
    final String name;
    final String phone;
    if (audience == 'provider') {
      final account = providerById(accountId);
      if (account == null) return 'الحساب غير موجود';
      name = technicianById(account.technicianId)?.name ?? account.phone;
      phone = account.phone;
    } else if (audience == 'client') {
      final account = clientById(accountId);
      if (account == null) return 'الحساب غير موجود';
      name = account.name;
      phone = account.phone;
    } else {
      return 'نوع الحساب غير معروف';
    }
    _deletionSequence += 1;
    _deletionRequests.insert(
      0,
      AccountDeletionRequest(
        id: 'del-$_deletionSequence',
        audience: audience,
        accountId: accountId,
        accountName: name,
        phone: phone,
        createdAt: _now(),
        status: 'pending',
      ),
    );
    _touch();
    return null;
  }

  String? rejectAccountDeletion(String requestId) {
    final index = _deletionRequests.indexWhere(
      (request) => request.id == requestId,
    );
    if (index < 0) return 'طلب الحذف غير موجود';
    final request = _deletionRequests[index];
    if (request.status != 'pending') return 'الطلب ليس بانتظار الموافقة';
    _deletionRequests[index] = AccountDeletionRequest(
      id: request.id,
      audience: request.audience,
      accountId: request.accountId,
      accountName: request.accountName,
      phone: request.phone,
      createdAt: request.createdAt,
      status: 'rejected',
    );
    _touch();
    return null;
  }

  String? approveAccountDeletion(String requestId) {
    AccountDeletionRequest? request;
    for (final candidate in _deletionRequests) {
      if (candidate.id == requestId) {
        request = candidate;
        break;
      }
    }
    if (request == null) return 'طلب الحذف غير موجود';
    if (request.status != 'pending') return 'الطلب ليس بانتظار الموافقة';
    final error = _removeAccount(
      audience: request.audience,
      accountId: request.accountId,
    );
    if (error != null) return error;
    _deletionRequests.removeWhere(
      (candidate) =>
          candidate.audience == request!.audience &&
          candidate.accountId == request.accountId,
    );
    _touch();
    return null;
  }

  String? deleteAccount({required String audience, required String accountId}) {
    final error = _removeAccount(audience: audience, accountId: accountId);
    if (error != null) return error;
    _deletionRequests.removeWhere(
      (request) =>
          request.audience == audience && request.accountId == accountId,
    );
    _touch();
    return null;
  }

  String? _removeAccount({
    required String audience,
    required String accountId,
  }) {
    if (audience == 'provider') {
      final account = providerById(accountId);
      if (account == null) return 'الحساب غير موجود';
      _providers.removeWhere((item) => item.id == accountId);
      _technicians.removeWhere((item) => item.id == account.technicianId);
      _startingPrices.remove(account.technicianId);
      _messages.removeWhere(
        (message) =>
            message.audience == 'provider' && message.recipientId == accountId,
      );
      if (_session?.id == accountId) _session = null;
      return null;
    }
    if (audience == 'client') {
      final account = clientById(accountId);
      if (account == null) return 'الحساب غير موجود';
      final requestIds = requests
          .where((request) => request.clientId == accountId)
          .map((request) => request.id)
          .toSet();
      _clientAccounts.removeWhere((item) => item.id == accountId);
      _orders.removeWhere((order) => order.clientId == accountId);
      requests.removeWhere((request) => request.clientId == accountId);
      _ratings.removeWhere((rating) => requestIds.contains(rating.requestId));
      _clients.remove(accountId);
      _messages.removeWhere(
        (message) =>
            message.audience == 'client' && message.recipientId == accountId,
      );
      _invoices.removeWhere((invoice) => invoice.partyName == account.name);
      if (_clientSession?.id == accountId) _clientSession = null;
      return null;
    }
    return 'نوع الحساب غير معروف';
  }

  Future<void> hydrate() async {
    final cached = await _store.readCache();
    if (cached != null) {
      _apply(cached);
      _base = cached;
    }
    try {
      final remote = await _store.load();
      if (remote != null) {
        _apply(remote);
        _base = remote;
        syncError = null;
      }
    } catch (_) {
      syncError ??= 'تعذر تحميل البيانات المحفوظة. تحقق من الاتصال.';
    }
    notifyListeners();
  }

  void noteSyncFailure() {
    syncError = 'تعذر تحميل البيانات المحفوظة. تحقق من الاتصال.';
    notifyListeners();
  }

  Future<void> flush() => _saveChain ?? Future<void>.value();

  void _touch() {
    notifyListeners();
    _enqueue(_persist);
  }

  void _enqueue(Future<void> Function() action) {
    _saveChain = (_saveChain ?? Future<void>.value()).then((_) => action());
  }

  Future<void> _refresh() async {
    try {
      final remote = await _store.load();
      if (remote == null) return;
      _apply(remote);
      _base = remote;
      syncError = null;
      notifyListeners();
    } catch (_) {
      syncError = 'تعذر تحميل البيانات المحفوظة. تحقق من الاتصال.';
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    try {
      final remote = await _store.load();
      final local = _capture();
      final merged = mergeSnapshots(base: _base, local: local, remote: remote);
      await _store.save(merged);
      _base = merged;
      syncError = null;
      if (!local.sameData(merged)) {
        _apply(merged);
        notifyListeners();
      }
    } catch (_) {
      syncError = 'تعذر حفظ البيانات على الويب. حاول مرة أخرى.';
      notifyListeners();
    }
  }

  SharedSnapshot _capture() {
    return SharedSnapshot(
      revision: _base.revision,
      services: List<ServiceCategory>.from(_extraCategories),
      suggestions: List<OwnerSuggestion>.from(_suggestions),
      messages: List<DeskMessage>.from(_messages),
      billing: _billing,
      startingPrices: Map<String, int>.from(_startingPrices),
      clients: List<ClientAccount>.from(_clientAccounts),
      providers: List<ProviderAccount>.from(_providers),
      technicians: List<Technician>.from(_technicians),
      orders: List<ServiceOrder>.from(_orders),
      requests: List<ServiceRequest>.from(requests),
      ratings: List<ProviderRating>.from(_ratings),
      subscriptions: _clients.values.toList(),
      invoices: List<ServickInvoice>.from(_invoices),
      deletionRequests: List<AccountDeletionRequest>.from(_deletionRequests),
      serviceSequence: _serviceSequence,
      suggestionSequence: _suggestionSequence,
      messageSequence: _messageSequence,
      clientSequence: _clientSequence,
      providerSequence: _providerSequence,
      technicianSequence: _technicianSequence,
      deletionSequence: _deletionSequence,
      requestSequence: _sequence,
      clientOrderSequence: _clientOrderSequence,
      ownerEmail: _ownerEmail,
      ownerPasswordHash: _ownerPasswordHash,
      ownerPasswordSalt: _ownerPasswordSalt,
      supervisors: List<SupervisorAccount>.from(_supervisors),
      supervisorSequence: _supervisorSequence,
    );
  }

  void _apply(SharedSnapshot snapshot) {
    _ownerEmail = snapshot.ownerEmail;
    _ownerPasswordHash = snapshot.ownerPasswordHash;
    _ownerPasswordSalt = snapshot.ownerPasswordSalt;
    _extraCategories
      ..clear()
      ..addAll(snapshot.services);
    _suggestions
      ..clear()
      ..addAll(snapshot.suggestions);
    _messages
      ..clear()
      ..addAll(snapshot.messages);
    _billing = snapshot.billing;
    _startingPrices
      ..clear()
      ..addAll(snapshot.startingPrices);
    _clientAccounts
      ..clear()
      ..addAll(snapshot.clients);
    _providers
      ..clear()
      ..addAll(snapshot.providers);
    _technicians
      ..clear()
      ..addAll(snapshot.technicians);
    _orders
      ..clear()
      ..addAll(snapshot.orders);
    requests
      ..clear()
      ..addAll(snapshot.requests);
    _ratings
      ..clear()
      ..addAll(snapshot.ratings);
    _clients
      ..clear()
      ..addEntries(
        snapshot.subscriptions.map(
          (subscription) => MapEntry(subscription.clientId, subscription),
        ),
      );
    _invoices
      ..clear()
      ..addAll(snapshot.invoices);
    _deletionRequests
      ..clear()
      ..addAll(snapshot.deletionRequests);
    _supervisors
      ..clear()
      ..addAll(snapshot.supervisors);
    _supervisorSequence = _maxSeq(
      snapshot.supervisorSequence,
      _maxSuffix(snapshot.supervisors.map((item) => item.id), 'sup-'),
    );
    _serviceSequence = _maxSeq(
      snapshot.serviceSequence,
      _maxSuffix(snapshot.services.map((item) => item.id), 'custom-'),
    );
    _suggestionSequence = _maxSeq(
      snapshot.suggestionSequence,
      _maxSuffix(snapshot.suggestions.map((item) => item.id), 'sug-'),
    );
    _messageSequence = _maxSeq(
      snapshot.messageSequence,
      _maxSuffix(
        snapshot.messages
            .where((message) => message.id.startsWith('msg-'))
            .map((message) => message.id),
        'msg-',
      ),
    );
    _clientSequence = _maxSeq(
      snapshot.clientSequence,
      _maxSuffix(snapshot.clients.map((item) => item.id), 'client-'),
    );
    _providerSequence = _maxSeq(
      snapshot.providerSequence,
      _maxSuffix(snapshot.providers.map((item) => item.id), 'prov-'),
    );
    _technicianSequence = _maxSeq(
      snapshot.technicianSequence,
      _maxSuffix(snapshot.technicians.map((item) => item.id), 'tech-'),
    );
    _deletionSequence = _maxSeq(
      snapshot.deletionSequence,
      _maxSuffix(snapshot.deletionRequests.map((item) => item.id), 'del-'),
    );
    _sequence = _maxSeq(
      snapshot.requestSequence,
      _maxSuffix(snapshot.requests.map((item) => item.id), 'SV-'),
    );
    _clientOrderSequence = _maxSeq(
      snapshot.clientOrderSequence,
      _maxSuffix(snapshot.orders.map((item) => item.id), 'ord-c-'),
    );
    final sessionId = _session?.id;
    _session = sessionId == null ? null : providerById(sessionId);
    final clientId = _clientSession?.id;
    _clientSession = clientId == null ? null : clientById(clientId);
  }

  int _maxSeq(int stored, int fromIds) => stored > fromIds ? stored : fromIds;

  int _maxSuffix(Iterable<String> ids, String prefix) {
    var max = 0;
    for (final id in ids) {
      if (!id.startsWith(prefix)) continue;
      final value = int.tryParse(id.substring(prefix.length));
      if (value != null && value > max) max = value;
    }
    return max;
  }
}

class PasswordResetResult {
  const PasswordResetResult({this.error, this.mailed = false, this.temporary});

  final String? error;
  final bool mailed;
  final String? temporary;
}

String foldEmail(String value) => value.trim().toLowerCase();

String? validateAccountEmail(String value) {
  final email = foldEmail(value);
  if (email.isEmpty) return 'اكتب البريد الإلكتروني';
  if (email.length > 80 ||
      !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'البريد الإلكتروني غير صحيح';
  }
  return null;
}

String _randomPassword() {
  const alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  final random = Random.secure();
  return List.generate(
    8,
    (_) => alphabet[random.nextInt(alphabet.length)],
  ).join();
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
