import '../data/password_hash.dart';

class ProviderAccount {
  const ProviderAccount({
    required this.id,
    required this.technicianId,
    required this.phone,
    required this.passwordHash,
    required this.passwordSalt,
    required this.subscriptionStatus,
    required this.subscriptionExpiry,
    this.email = '',
  });

  final String id;
  final String technicianId;
  final String phone;
  final String passwordHash;
  final String passwordSalt;
  final String subscriptionStatus;
  final DateTime? subscriptionExpiry;
  final String email;

  bool matchesPassword(String raw) {
    return hashPassword(raw, passwordSalt) == passwordHash;
  }

  bool isSubscribedAt(DateTime now) {
    final expiry = subscriptionExpiry;
    return subscriptionStatus == 'active' &&
        expiry != null &&
        expiry.isAfter(now);
  }

  ProviderAccount copyWith({
    String? subscriptionStatus,
    DateTime? subscriptionExpiry,
    String? passwordHash,
    String? passwordSalt,
    String? email,
  }) {
    return ProviderAccount(
      id: id,
      technicianId: technicianId,
      phone: phone,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      email: email ?? this.email,
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
