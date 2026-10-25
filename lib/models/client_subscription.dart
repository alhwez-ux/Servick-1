class ClientSubscription {
  const ClientSubscription({
    required this.clientId,
    required this.status,
    required this.planId,
    required this.expiry,
  });

  final String clientId;
  final String status;
  final String planId;
  final DateTime expiry;

  bool isActiveAt(DateTime now) {
    return status == 'active' && expiry.isAfter(now);
  }
}

class ClientSubscriptionArgs {
  const ClientSubscriptionArgs({
    required this.clientId,
    required this.isAdmin,
    this.catalog = false,
  });

  final String clientId;
  final bool isAdmin;
  final bool catalog;
}
