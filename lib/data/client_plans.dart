import 'package:flutter/material.dart';

const demoClientId = 'client-demo';
const demoClientName = 'عميل رابط';

class ClientPlan {
  const ClientPlan({
    required this.id,
    required this.title,
    required this.duration,
    required this.priceAmount,
    required this.months,
    required this.adminOnly,
    required this.color,
  });

  final String id;
  final String title;
  final String duration;
  final int priceAmount;
  final int months;
  final bool adminOnly;
  final Color color;

  String get priceLabel => '$priceAmount ريال';
}

const clientPlans = <ClientPlan>[
  ClientPlan(
    id: 'free_admin',
    title: 'باقة المالك الخاصة',
    duration: 'استثناء تجريبي',
    priceAmount: 0,
    months: 0,
    adminOnly: true,
    color: Color(0xFF9E9E9E),
  ),
  ClientPlan(
    id: 'monthly',
    title: 'الاشتراك الشهري',
    duration: 'شهر واحد',
    priceAmount: 20,
    months: 1,
    adminOnly: false,
    color: Color(0xFF2196F3),
  ),
  ClientPlan(
    id: 'quarterly',
    title: 'اشتراك 3 أشهر',
    duration: 'ثلاثة أشهر',
    priceAmount: 40,
    months: 3,
    adminOnly: false,
    color: Color(0xFF0F766E),
  ),
  ClientPlan(
    id: 'semi_annual',
    title: 'اشتراك 6 أشهر',
    duration: 'نصف سنة',
    priceAmount: 70,
    months: 6,
    adminOnly: false,
    color: Color(0xFF3F51B5),
  ),
  ClientPlan(
    id: 'annual',
    title: 'اشتراك 12 شهراً',
    duration: 'سنة كاملة (توفيري)',
    priceAmount: 120,
    months: 12,
    adminOnly: false,
    color: Color(0xFFFF8F00),
  ),
];

ClientPlan? clientPlanById(String id) {
  for (final plan in clientPlans) {
    if (plan.id == id) return plan;
  }
  return null;
}

List<ClientPlan> plansFor({required bool isAdmin}) {
  return clientPlans.where((plan) => isAdmin || !plan.adminOnly).toList();
}
