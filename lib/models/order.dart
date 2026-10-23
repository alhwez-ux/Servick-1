class ServiceOrder {
  const ServiceOrder({
    required this.id,
    required this.clientName,
    required this.serviceTitle,
    required this.notes,
    required this.city,
    required this.createdAt,
    required this.status,
    this.clientId,
    this.categoryId,
    this.providerId,
    this.requestId,
  });

  final String id;
  final String? clientId;
  final String? categoryId;
  final String clientName;
  final String serviceTitle;
  final String notes;
  final String city;
  final DateTime createdAt;
  final String status;
  final String? providerId;
  final String? requestId;

  bool get isPending => status == 'pending';

  ServiceOrder copyWith({String? status, String? providerId}) {
    return ServiceOrder(
      id: id,
      clientName: clientName,
      serviceTitle: serviceTitle,
      notes: notes,
      city: city,
      createdAt: createdAt,
      status: status ?? this.status,
      clientId: clientId,
      categoryId: categoryId,
      providerId: providerId ?? this.providerId,
      requestId: requestId,
    );
  }
}

class ProviderOrdersArgs {
  const ProviderOrdersArgs({
    required this.providerId,
    required this.providerCity,
  });

  final String providerId;
  final String providerCity;
}

class ClientOrderArgs {
  const ClientOrderArgs({required this.clientId, required this.clientName});

  final String clientId;
  final String clientName;
}
