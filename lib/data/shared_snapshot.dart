import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/client_subscription.dart';
import '../models/desk.dart';
import '../models/models.dart';
import '../models/order.dart';
import '../models/provider.dart';
import 'providers.dart';
import 'service_pictures.dart';

class SharedSnapshot {
  const SharedSnapshot({
    required this.revision,
    required this.services,
    required this.suggestions,
    required this.messages,
    required this.billing,
    required this.startingPrices,
    required this.clients,
    required this.providers,
    required this.technicians,
    required this.orders,
    required this.requests,
    required this.ratings,
    required this.subscriptions,
    required this.invoices,
    required this.deletionRequests,
    required this.serviceSequence,
    required this.suggestionSequence,
    required this.messageSequence,
    required this.clientSequence,
    required this.providerSequence,
    required this.technicianSequence,
    required this.deletionSequence,
    required this.requestSequence,
    required this.clientOrderSequence,
  });

  final int revision;
  final List<ServiceCategory> services;
  final List<OwnerSuggestion> suggestions;
  final List<DeskMessage> messages;
  final BillingConfig billing;
  final Map<String, int> startingPrices;
  final List<ClientAccount> clients;
  final List<ProviderAccount> providers;
  final List<Technician> technicians;
  final List<ServiceOrder> orders;
  final List<ServiceRequest> requests;
  final List<ProviderRating> ratings;
  final List<ClientSubscription> subscriptions;
  final List<ServickInvoice> invoices;
  final List<AccountDeletionRequest> deletionRequests;
  final int serviceSequence;
  final int suggestionSequence;
  final int messageSequence;
  final int clientSequence;
  final int providerSequence;
  final int technicianSequence;
  final int deletionSequence;
  final int requestSequence;
  final int clientOrderSequence;

  static SharedSnapshot empty() {
    return SharedSnapshot(
      revision: 0,
      services: const [],
      suggestions: const [],
      messages: const [],
      billing: const BillingConfig(
        providerAnnualFee: annualSubscriptionFee,
        planPrices: {},
        invoicePrefix: 'SV',
        nextNumber: 1041,
        note: 'فاتورة تجريبية. لا يُخصم مبلغ حقيقي.',
        invoicesEnabled: true,
      ),
      startingPrices: const {},
      clients: const [],
      providers: const [],
      technicians: const [],
      orders: const [],
      requests: const [],
      ratings: const [],
      subscriptions: const [],
      invoices: const [],
      deletionRequests: const [],
      serviceSequence: 0,
      suggestionSequence: 0,
      messageSequence: 0,
      clientSequence: 0,
      providerSequence: 0,
      technicianSequence: 0,
      deletionSequence: 0,
      requestSequence: 1040,
      clientOrderSequence: 0,
    );
  }

  static SharedSnapshot? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['v'] != 1) return null;
      final json = _map(decoded);
      final billing = _billing(_map(json['billing']));
      return SharedSnapshot(
        revision: _int(json['revision']),
        services: [
          for (final item in _list(json['services'])) _service(_map(item)),
        ],
        suggestions: [
          for (final item in _list(json['suggestions']))
            _suggestion(_map(item)),
        ],
        messages: [
          for (final item in _list(json['messages'])) _message(_map(item)),
        ],
        billing: billing,
        startingPrices: _intMap(json['startingPrices']),
        clients: [
          for (final item in _list(json['clients'])) _client(_map(item)),
        ],
        providers: [
          for (final item in _list(json['providers'])) _provider(_map(item)),
        ],
        technicians: [
          for (final item in _list(json['technicians']))
            _technician(_map(item)),
        ],
        orders: [for (final item in _list(json['orders'])) _order(_map(item))],
        requests: [
          for (final item in _list(json['requests'])) _request(_map(item)),
        ],
        ratings: [
          for (final item in _list(json['ratings'])) _rating(_map(item)),
        ],
        subscriptions: [
          for (final item in _list(json['subscriptions']))
            _subscription(_map(item)),
        ],
        invoices: [
          for (final item in _list(json['invoices'])) _invoice(_map(item)),
        ],
        deletionRequests: [
          for (final item in _list(json['deletionRequests']))
            _deletion(_map(item)),
        ],
        serviceSequence: _int(json['serviceSequence']),
        suggestionSequence: _int(json['suggestionSequence']),
        messageSequence: _int(json['messageSequence']),
        clientSequence: _int(json['clientSequence']),
        providerSequence: _int(json['providerSequence']),
        technicianSequence: _int(json['technicianSequence']),
        deletionSequence: _int(json['deletionSequence']),
        requestSequence: json['requestSequence'] == null
            ? 1040
            : _int(json['requestSequence']),
        clientOrderSequence: _int(json['clientOrderSequence']),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, Object?> toJson() {
    return {
      'v': 1,
      'revision': revision,
      'services': [
        for (final service in services)
          {
            'id': service.id,
            'title': service.title,
            'subtitle': service.subtitle,
            'icon': service.icon.codePoint,
            'color': service.color.toARGB32(),
            'image': service.imageAsset,
          },
      ],
      'suggestions': [
        for (final suggestion in suggestions)
          {
            'id': suggestion.id,
            'area': suggestion.area,
            'text': suggestion.text,
            'at': suggestion.createdAt.toUtc().toIso8601String(),
          },
      ],
      'messages': [
        for (final message in messages)
          {
            'id': message.id,
            'audience': message.audience,
            'recipientId': message.recipientId,
            'recipientName': message.recipientName,
            'body': message.body,
            'at': message.createdAt.toUtc().toIso8601String(),
          },
      ],
      'billing': _billingJson(billing),
      'startingPrices': startingPrices,
      'clients': [
        for (final client in clients)
          {
            'id': client.id,
            'name': client.name,
            'phone': client.phone,
            'city': client.city,
            'passwordHash': client.passwordHash,
            'passwordSalt': client.passwordSalt,
            'at': client.createdAt.toUtc().toIso8601String(),
          },
      ],
      'providers': [
        for (final provider in providers)
          {
            'id': provider.id,
            'technicianId': provider.technicianId,
            'phone': provider.phone,
            'passwordHash': provider.passwordHash,
            'passwordSalt': provider.passwordSalt,
            'status': provider.subscriptionStatus,
            'expiry': provider.subscriptionExpiry?.toUtc().toIso8601String(),
          },
      ],
      'technicians': [
        for (final technician in technicians)
          {
            'id': technician.id,
            'name': technician.name,
            'categoryId': technician.categoryId,
            'city': technician.city,
            'rating': technician.rating,
            'jobs': technician.jobs,
            'years': technician.years,
            'available': technician.available,
            'eta': technician.etaMinutes,
            'price': technician.startingPrice,
            'phone': technician.phone,
            'about': technician.about,
            'services': technician.services,
            'reviewAuthor': technician.review.author,
            'reviewText': technician.review.text,
            'reviewStars': technician.review.stars,
          },
      ],
      'orders': [
        for (final order in orders)
          {
            'id': order.id,
            'clientId': order.clientId,
            'clientName': order.clientName,
            'categoryId': order.categoryId,
            'serviceTitle': order.serviceTitle,
            'notes': order.notes,
            'city': order.city,
            'at': order.createdAt.toUtc().toIso8601String(),
            'status': order.status,
            'providerId': order.providerId,
            'requestId': order.requestId,
          },
      ],
      'requests': [
        for (final request in requests)
          {
            'id': request.id,
            'kind': request.kind.name,
            'categoryId': request.categoryId,
            'technicianId': request.technicianId,
            'clientId': request.clientId,
            'city': request.city,
            'summary': request.summary,
            'details': request.details,
            'phone': request.phone,
            'when': request.whenLabel,
            'at': request.createdAt.toUtc().toIso8601String(),
            'status': request.status.name,
          },
      ],
      'ratings': [
        for (final rating in ratings)
          {
            'requestId': rating.requestId,
            'technicianId': rating.technicianId,
            'stars': rating.stars,
            'comment': rating.comment,
            'author': rating.author,
            'at': rating.createdAt.toUtc().toIso8601String(),
          },
      ],
      'subscriptions': [
        for (final subscription in subscriptions)
          {
            'clientId': subscription.clientId,
            'status': subscription.status,
            'planId': subscription.planId,
            'expiry': subscription.expiry.toUtc().toIso8601String(),
          },
      ],
      'invoices': [
        for (final invoice in invoices)
          {
            'id': invoice.id,
            'number': invoice.number,
            'partyName': invoice.partyName,
            'title': invoice.title,
            'amount': invoice.amount,
            'at': invoice.createdAt.toUtc().toIso8601String(),
          },
      ],
      'deletionRequests': [
        for (final request in deletionRequests)
          {
            'id': request.id,
            'audience': request.audience,
            'accountId': request.accountId,
            'accountName': request.accountName,
            'phone': request.phone,
            'at': request.createdAt.toUtc().toIso8601String(),
            'status': request.status,
          },
      ],
      'serviceSequence': serviceSequence,
      'suggestionSequence': suggestionSequence,
      'messageSequence': messageSequence,
      'clientSequence': clientSequence,
      'providerSequence': providerSequence,
      'technicianSequence': technicianSequence,
      'deletionSequence': deletionSequence,
      'requestSequence': requestSequence,
      'clientOrderSequence': clientOrderSequence,
    };
  }

  String encode() => jsonEncode(toJson());

  bool sameData(SharedSnapshot other) {
    final left = toJson()..remove('revision');
    final right = other.toJson()..remove('revision');
    return jsonEncode(left) == jsonEncode(right);
  }
}

SharedSnapshot mergeSnapshots({
  required SharedSnapshot base,
  required SharedSnapshot local,
  required SharedSnapshot? remote,
}) {
  if (remote == null) {
    return _copy(local, revision: base.revision + 1);
  }
  return SharedSnapshot(
    revision: _max(base.revision, remote.revision) + 1,
    services: _mergeById(
      base: base.services,
      local: local.services,
      remote: remote.services,
      idOf: (item) => item.id,
      toJson: (item) => {
        'title': item.title,
        'subtitle': item.subtitle,
        'image': item.imageAsset,
      },
    ),
    suggestions: _mergeById(
      base: base.suggestions,
      local: local.suggestions,
      remote: remote.suggestions,
      idOf: (item) => item.id,
      toJson: (item) => {'text': item.text, 'area': item.area},
    ),
    messages: _mergeById(
      base: base.messages,
      local: local.messages,
      remote: remote.messages,
      idOf: (item) => item.id,
      toJson: (item) => {'body': item.body},
    ),
    billing: _mergeBilling(base.billing, local.billing, remote.billing),
    startingPrices: _mergeIntMap(
      base.startingPrices,
      local.startingPrices,
      remote.startingPrices,
    ),
    clients: _mergeById(
      base: base.clients,
      local: local.clients,
      remote: remote.clients,
      idOf: (item) => item.id,
      toJson: (item) => {
        'name': item.name,
        'phone': item.phone,
        'city': item.city,
      },
    ),
    providers: _mergeById(
      base: base.providers,
      local: local.providers,
      remote: remote.providers,
      idOf: (item) => item.id,
      toJson: (item) => {
        'status': item.subscriptionStatus,
        'expiry': item.subscriptionExpiry?.toUtc().toIso8601String(),
      },
    ),
    technicians: _mergeById(
      base: base.technicians,
      local: local.technicians,
      remote: remote.technicians,
      idOf: (item) => item.id,
      toJson: (item) => {
        'name': item.name,
        'city': item.city,
        'categoryId': item.categoryId,
        'available': item.available,
      },
    ),
    orders: _mergeById(
      base: base.orders,
      local: local.orders,
      remote: remote.orders,
      idOf: (item) => item.id,
      toJson: (item) => {'status': item.status, 'providerId': item.providerId},
    ),
    requests: _mergeById(
      base: base.requests,
      local: local.requests,
      remote: remote.requests,
      idOf: (item) => item.id,
      toJson: (item) => {
        'status': item.status.name,
        'technicianId': item.technicianId,
      },
    ),
    ratings: _mergeById(
      base: base.ratings,
      local: local.ratings,
      remote: remote.ratings,
      idOf: (item) => item.requestId,
      toJson: (item) => {'stars': item.stars, 'comment': item.comment},
    ),
    subscriptions: _mergeById(
      base: base.subscriptions,
      local: local.subscriptions,
      remote: remote.subscriptions,
      idOf: (item) => item.clientId,
      toJson: (item) => {
        'planId': item.planId,
        'status': item.status,
        'expiry': item.expiry.toUtc().toIso8601String(),
      },
    ),
    invoices: _mergeById(
      base: base.invoices,
      local: local.invoices,
      remote: remote.invoices,
      idOf: (item) => item.id,
      toJson: (item) => {'number': item.number, 'amount': item.amount},
    ),
    deletionRequests: _mergeById(
      base: base.deletionRequests,
      local: local.deletionRequests,
      remote: remote.deletionRequests,
      idOf: (item) => item.id,
      toJson: (item) => {'status': item.status},
    ),
    serviceSequence: _max(local.serviceSequence, remote.serviceSequence),
    suggestionSequence: _max(
      local.suggestionSequence,
      remote.suggestionSequence,
    ),
    messageSequence: _max(local.messageSequence, remote.messageSequence),
    clientSequence: _max(local.clientSequence, remote.clientSequence),
    providerSequence: _max(local.providerSequence, remote.providerSequence),
    technicianSequence: _max(
      local.technicianSequence,
      remote.technicianSequence,
    ),
    deletionSequence: _max(local.deletionSequence, remote.deletionSequence),
    requestSequence: _max(local.requestSequence, remote.requestSequence),
    clientOrderSequence: _max(
      local.clientOrderSequence,
      remote.clientOrderSequence,
    ),
  );
}

SharedSnapshot _copy(SharedSnapshot snapshot, {required int revision}) {
  return SharedSnapshot(
    revision: revision,
    services: snapshot.services,
    suggestions: snapshot.suggestions,
    messages: snapshot.messages,
    billing: snapshot.billing,
    startingPrices: snapshot.startingPrices,
    clients: snapshot.clients,
    providers: snapshot.providers,
    technicians: snapshot.technicians,
    orders: snapshot.orders,
    requests: snapshot.requests,
    ratings: snapshot.ratings,
    subscriptions: snapshot.subscriptions,
    invoices: snapshot.invoices,
    deletionRequests: snapshot.deletionRequests,
    serviceSequence: snapshot.serviceSequence,
    suggestionSequence: snapshot.suggestionSequence,
    messageSequence: snapshot.messageSequence,
    clientSequence: snapshot.clientSequence,
    providerSequence: snapshot.providerSequence,
    technicianSequence: snapshot.technicianSequence,
    deletionSequence: snapshot.deletionSequence,
    requestSequence: snapshot.requestSequence,
    clientOrderSequence: snapshot.clientOrderSequence,
  );
}

List<T> _mergeById<T>({
  required List<T> base,
  required List<T> local,
  required List<T> remote,
  required String Function(T item) idOf,
  required Map<String, Object?> Function(T item) toJson,
}) {
  final baseIds = {for (final item in base) idOf(item)};
  final localById = {for (final item in local) idOf(item): item};
  final baseById = {for (final item in base) idOf(item): item};
  final deleted = baseIds.difference(localById.keys.toSet());
  final result = <T>[];
  final seen = <String>{};
  for (final item in remote) {
    final id = idOf(item);
    if (deleted.contains(id)) continue;
    seen.add(id);
    final localItem = localById[id];
    if (localItem == null) {
      result.add(item);
      continue;
    }
    final baseItem = baseById[id];
    final localJson = jsonEncode(toJson(localItem));
    final baseJson = baseItem == null ? null : jsonEncode(toJson(baseItem));
    result.add(localJson == baseJson ? item : localItem);
  }
  for (final item in local) {
    final id = idOf(item);
    if (seen.contains(id)) continue;
    result.add(item);
  }
  return result;
}

BillingConfig _mergeBilling(
  BillingConfig base,
  BillingConfig local,
  BillingConfig remote,
) {
  T pick<T>(T baseValue, T localValue, T remoteValue) {
    return baseValue == localValue ? remoteValue : localValue;
  }

  return BillingConfig(
    providerAnnualFee: pick(
      base.providerAnnualFee,
      local.providerAnnualFee,
      remote.providerAnnualFee,
    ),
    planPrices: _sameIntMap(base.planPrices, local.planPrices)
        ? remote.planPrices
        : local.planPrices,
    invoicePrefix: pick(
      base.invoicePrefix,
      local.invoicePrefix,
      remote.invoicePrefix,
    ),
    nextNumber: pick(base.nextNumber, local.nextNumber, remote.nextNumber),
    note: pick(base.note, local.note, remote.note),
    invoicesEnabled: pick(
      base.invoicesEnabled,
      local.invoicesEnabled,
      remote.invoicesEnabled,
    ),
    providerFreeMonths: pick(
      base.providerFreeMonths,
      local.providerFreeMonths,
      remote.providerFreeMonths,
    ),
    clientFreeMonths: pick(
      base.clientFreeMonths,
      local.clientFreeMonths,
      remote.clientFreeMonths,
    ),
    providerFreeAnchor: pick(
      base.providerFreeAnchor,
      local.providerFreeAnchor,
      remote.providerFreeAnchor,
    ),
    clientFreeAnchor: pick(
      base.clientFreeAnchor,
      local.clientFreeAnchor,
      remote.clientFreeAnchor,
    ),
  );
}

Map<String, int> _mergeIntMap(
  Map<String, int> base,
  Map<String, int> local,
  Map<String, int> remote,
) {
  if (_sameIntMap(base, local)) return remote;
  return local;
}

bool _sameIntMap(Map<String, int> left, Map<String, int> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}

int _max(int left, int right) => left > right ? left : right;

Map<String, dynamic> _map(Object? value) {
  if (value is! Map) throw const FormatException('map');
  return value.map((key, item) => MapEntry(key.toString(), item));
}

List<dynamic> _list(Object? value) {
  if (value == null) return const [];
  if (value is! List) throw const FormatException('list');
  return value;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw const FormatException('int');
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is! String || value.isEmpty) throw const FormatException('date');
  return DateTime.parse(value);
}

Map<String, int> _intMap(Object? value) {
  if (value == null) return {};
  final json = _map(value);
  return {for (final entry in json.entries) entry.key: _int(entry.value)};
}

Map<String, Object?> _billingJson(BillingConfig billing) {
  return {
    'providerAnnualFee': billing.providerAnnualFee,
    'planPrices': billing.planPrices,
    'invoicePrefix': billing.invoicePrefix,
    'nextNumber': billing.nextNumber,
    'note': billing.note,
    'invoicesEnabled': billing.invoicesEnabled,
    'providerFreeMonths': billing.providerFreeMonths,
    'clientFreeMonths': billing.clientFreeMonths,
    'providerFreeAnchor': billing.providerFreeAnchor?.toUtc().toIso8601String(),
    'clientFreeAnchor': billing.clientFreeAnchor?.toUtc().toIso8601String(),
  };
}

BillingConfig _billing(Map<String, dynamic> json) {
  return BillingConfig(
    providerAnnualFee: _int(json['providerAnnualFee']),
    planPrices: _intMap(json['planPrices']),
    invoicePrefix: json['invoicePrefix'] as String,
    nextNumber: _int(json['nextNumber']),
    note: json['note'] as String,
    invoicesEnabled: json['invoicesEnabled'] as bool,
    providerFreeMonths: _int(json['providerFreeMonths'] ?? 0),
    clientFreeMonths: _int(json['clientFreeMonths'] ?? 0),
    providerFreeAnchor: _date(json['providerFreeAnchor']),
    clientFreeAnchor: _date(json['clientFreeAnchor']),
  );
}

const _knownIcons = <IconData>[
  Icons.home_repair_service,
  Icons.handyman,
  Icons.build_circle,
  Icons.plumbing,
  Icons.local_gas_station,
  Icons.car_repair,
  Icons.directions_car,
  Icons.engineering,
  Icons.bolt,
  Icons.electrical_services,
];

IconData _iconFrom(Object? value) {
  final codePoint = value is num ? value.toInt() : null;
  for (final icon in _knownIcons) {
    if (icon.codePoint == codePoint) return icon;
  }
  return Icons.home_repair_service;
}

ServiceCategory _service(Map<String, dynamic> json) {
  final title = json['title'] as String;
  final matched = pictureForTitle(title);
  final stored = json['image'] as String?;
  return ServiceCategory(
    id: json['id'] as String,
    title: title,
    subtitle: json['subtitle'] as String,
    icon: _iconFrom(json['icon']),
    color: Color(_int(json['color'])),
    imageAsset: matched.id == 'general'
        ? (stored ?? matched.asset)
        : matched.asset,
  );
}

OwnerSuggestion _suggestion(Map<String, dynamic> json) {
  return OwnerSuggestion(
    id: json['id'] as String,
    area: json['area'] as String,
    text: json['text'] as String,
    createdAt: _date(json['at'])!,
  );
}

DeskMessage _message(Map<String, dynamic> json) {
  return DeskMessage(
    id: json['id'] as String,
    audience: json['audience'] as String,
    recipientId: json['recipientId'] as String,
    recipientName: json['recipientName'] as String,
    body: json['body'] as String,
    createdAt: _date(json['at'])!,
  );
}

ClientAccount _client(Map<String, dynamic> json) {
  return ClientAccount(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    city: json['city'] as String,
    passwordHash: json['passwordHash'] as String,
    passwordSalt: json['passwordSalt'] as String,
    createdAt: _date(json['at'])!,
  );
}

ProviderAccount _provider(Map<String, dynamic> json) {
  return ProviderAccount(
    id: json['id'] as String,
    technicianId: json['technicianId'] as String,
    phone: json['phone'] as String,
    passwordHash: json['passwordHash'] as String,
    passwordSalt: json['passwordSalt'] as String,
    subscriptionStatus: json['status'] as String,
    subscriptionExpiry: _date(json['expiry']),
  );
}

Technician _technician(Map<String, dynamic> json) {
  return Technician(
    id: json['id'] as String,
    name: json['name'] as String,
    categoryId: json['categoryId'] as String,
    city: json['city'] as String,
    rating: (json['rating'] as num).toDouble(),
    jobs: _int(json['jobs']),
    years: _int(json['years']),
    available: json['available'] as bool,
    etaMinutes: _int(json['eta']),
    startingPrice: _int(json['price']),
    phone: json['phone'] as String,
    about: json['about'] as String,
    services: [for (final item in _list(json['services'])) item as String],
    review: CustomerReview(
      author: json['reviewAuthor'] as String? ?? 'سيرفيسك',
      text: json['reviewText'] as String? ?? 'لا توجد تقييمات بعد.',
      stars: json['reviewStars'] as int?,
    ),
  );
}

ServiceOrder _order(Map<String, dynamic> json) {
  return ServiceOrder(
    id: json['id'] as String,
    clientId: json['clientId'] as String?,
    clientName: json['clientName'] as String,
    categoryId: json['categoryId'] as String?,
    serviceTitle: json['serviceTitle'] as String,
    notes: json['notes'] as String,
    city: json['city'] as String,
    createdAt: _date(json['at'])!,
    status: json['status'] as String,
    providerId: json['providerId'] as String?,
    requestId: json['requestId'] as String?,
  );
}

ServiceRequest _request(Map<String, dynamic> json) {
  return ServiceRequest(
    id: json['id'] as String,
    kind: RequestKind.values.byName(json['kind'] as String),
    categoryId: json['categoryId'] as String,
    technicianId: json['technicianId'] as String?,
    clientId: json['clientId'] as String?,
    city: json['city'] as String,
    summary: json['summary'] as String,
    details: json['details'] as String,
    phone: json['phone'] as String,
    whenLabel: json['when'] as String,
    createdAt: _date(json['at'])!,
    status: RequestStatus.values.byName(json['status'] as String),
  );
}

ProviderRating _rating(Map<String, dynamic> json) {
  return ProviderRating(
    requestId: json['requestId'] as String,
    technicianId: json['technicianId'] as String,
    stars: _int(json['stars']),
    comment: json['comment'] as String,
    author: json['author'] as String,
    createdAt: _date(json['at'])!,
  );
}

ClientSubscription _subscription(Map<String, dynamic> json) {
  return ClientSubscription(
    clientId: json['clientId'] as String,
    status: json['status'] as String,
    planId: json['planId'] as String,
    expiry: _date(json['expiry'])!,
  );
}

ServickInvoice _invoice(Map<String, dynamic> json) {
  return ServickInvoice(
    id: json['id'] as String,
    number: json['number'] as String,
    partyName: json['partyName'] as String,
    title: json['title'] as String,
    amount: _int(json['amount']),
    createdAt: _date(json['at'])!,
  );
}

AccountDeletionRequest _deletion(Map<String, dynamic> json) {
  return AccountDeletionRequest(
    id: json['id'] as String,
    audience: json['audience'] as String,
    accountId: json['accountId'] as String,
    accountName: json['accountName'] as String,
    phone: json['phone'] as String,
    createdAt: _date(json['at'])!,
    status: json['status'] as String,
  );
}
