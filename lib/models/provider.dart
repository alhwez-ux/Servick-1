class ProviderAccount {
  const ProviderAccount({
    required this.id,
    required this.technicianId,
    required this.phone,
    required this.password,
    required this.subscriptionStatus,
    required this.subscriptionExpiry,
  });

  final String id;
  final String technicianId;
  final String phone;
  final String password;
  final String subscriptionStatus;
  final DateTime? subscriptionExpiry;

  bool isSubscribedAt(DateTime now) {
    final expiry = subscriptionExpiry;
    return subscriptionStatus == 'active' &&
        expiry != null &&
        expiry.isAfter(now);
  }

  ProviderAccount copyWith({
    String? subscriptionStatus,
    DateTime? subscriptionExpiry,
  }) {
    return ProviderAccount(
      id: id,
      technicianId: technicianId,
      phone: phone,
      password: password,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
    );
  }
}

sealed class ProviderLoginResult {
  const ProviderLoginResult();
}

class ProviderLoginSuccess extends ProviderLoginResult {
  const ProviderLoginSuccess(this.account);

  final ProviderAccount account;
}

class ProviderLoginFailure extends ProviderLoginResult {
  const ProviderLoginFailure(this.message);

  final String message;
}

class ProviderSubscriptionExpired extends ProviderLoginResult {
  const ProviderSubscriptionExpired(this.account);

  final ProviderAccount account;
}

class ProviderFreePeriodEnded extends ProviderLoginResult {
  const ProviderFreePeriodEnded(this.account);

  final ProviderAccount account;
}
