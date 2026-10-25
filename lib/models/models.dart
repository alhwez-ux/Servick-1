import 'package:flutter/material.dart';

import '../data/password_hash.dart';

const cities = <String>['خميس مشيط', 'أبها', 'أحد رفيدة'];

enum RequestKind { emergency, booking }

enum RequestStatus { assigned, waiting, completed }

extension RequestKindLabel on RequestKind {
  String get label => switch (this) {
    RequestKind.emergency => 'طوارئ',
    RequestKind.booking => 'حجز',
  };
}

extension RequestStatusLabel on RequestStatus {
  String get label => switch (this) {
    RequestStatus.assigned => 'تم التوجيه',
    RequestStatus.waiting => 'بانتظار فني',
    RequestStatus.completed => 'مكتمل',
  };
}

class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.imageAsset,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? imageAsset;
}

class CustomerReview {
  const CustomerReview({required this.author, required this.text, this.stars});

  final String author;
  final String text;
  final int? stars;
}

class OwnerSuggestion {
  const OwnerSuggestion({
    required this.id,
    required this.area,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String area;
  final String text;
  final DateTime createdAt;
}

class ProviderRating {
  const ProviderRating({
    required this.requestId,
    required this.technicianId,
    required this.stars,
    required this.comment,
    required this.author,
    required this.createdAt,
  });

  final String requestId;
  final String technicianId;
  final int stars;
  final String comment;
  final String author;
  final DateTime createdAt;
}

class Technician {
  const Technician({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.city,
    required this.rating,
    required this.jobs,
    required this.years,
    required this.available,
    required this.etaMinutes,
    required this.startingPrice,
    required this.phone,
    required this.about,
    required this.services,
    required this.review,
  });

  final String id;
  final String name;
  final String categoryId;
  final String city;
  final double rating;
  final int jobs;
  final int years;
  final bool available;
  final int etaMinutes;
  final int startingPrice;
  final String phone;
  final String about;
  final List<String> services;
  final CustomerReview review;
}

class RoadsideIssue {
  const RoadsideIssue({
    required this.id,
    required this.label,
    required this.icon,
    required this.categoryIds,
  });

  final String id;
  final String label;
  final IconData icon;
  final List<String> categoryIds;
}

class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.kind,
    required this.categoryId,
    required this.city,
    required this.summary,
    required this.details,
    required this.phone,
    required this.whenLabel,
    required this.createdAt,
    required this.status,
    this.technicianId,
    this.clientId,
  });

  final String id;
  final RequestKind kind;
  final String categoryId;
  final String? technicianId;
  final String? clientId;
  final String city;
  final String summary;
  final String details;
  final String phone;
  final String whenLabel;
  final DateTime createdAt;
  final RequestStatus status;

  ServiceRequest copyWith({RequestStatus? status, String? technicianId}) {
    return ServiceRequest(
      id: id,
      kind: kind,
      categoryId: categoryId,
      technicianId: technicianId ?? this.technicianId,
      clientId: clientId,
      city: city,
      summary: summary,
      details: details,
      phone: phone,
      whenLabel: whenLabel,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }
}

class ClientAccount {
  const ClientAccount({
    required this.id,
    required this.name,
    required this.phone,
    required this.city,
    required this.passwordHash,
    required this.passwordSalt,
    required this.createdAt,
    this.email = '',
  });

  final String id;
  final String name;
  final String phone;
  final String city;
  final String passwordHash;
  final String passwordSalt;
  final DateTime createdAt;
  final String email;

  bool matchesPassword(String raw) {
    return hashPassword(raw, passwordSalt) == passwordHash;
  }

  ClientAccount copyWith({
    String? passwordHash,
    String? passwordSalt,
    String? email,
  }) {
    return ClientAccount(
      id: id,
      name: name,
      phone: phone,
      city: city,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      createdAt: createdAt,
      email: email ?? this.email,
    );
  }
}

class AccountDeletionRequest {
  const AccountDeletionRequest({
    required this.id,
    required this.audience,
    required this.accountId,
    required this.accountName,
    required this.phone,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final String audience;
  final String accountId;
  final String accountName;
  final String phone;
  final DateTime createdAt;
  final String status;
}

class RequestRouteArgs {
  const RequestRouteArgs({required this.request, this.justSent = false});

  final ServiceRequest request;
  final bool justSent;
}
