import 'package:flutter/material.dart';

const cities = <String>['خميس مشيط', 'أبها', 'أحد رفيدة'];

enum RequestKind { emergency, booking }

enum RequestStatus { assigned, waiting }

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
  };
}

class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class CustomerReview {
  const CustomerReview({required this.author, required this.text});

  final String author;
  final String text;
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
  });

  final String id;
  final RequestKind kind;
  final String categoryId;
  final String? technicianId;
  final String city;
  final String summary;
  final String details;
  final String phone;
  final String whenLabel;
  final DateTime createdAt;
  final RequestStatus status;
}

class RequestRouteArgs {
  const RequestRouteArgs({required this.request, this.justSent = false});

  final ServiceRequest request;
  final bool justSent;
}
