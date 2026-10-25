import '../data/password_hash.dart';

class SupervisorAccount {
  const SupervisorAccount({
    required this.id,
    required this.name,
    required this.phone,
    required this.passwordHash,
    required this.passwordSalt,
    required this.createdAt,
    this.email = '',
  });

  final String id;
  final String name;
  final String phone;
  final String passwordHash;
  final String passwordSalt;
  final String email;
  final DateTime createdAt;

  bool matchesPassword(String raw) {
    return hashPassword(raw, passwordSalt) == passwordHash;
  }
}
