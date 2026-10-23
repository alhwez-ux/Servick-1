import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/catalog.dart';
import '../data/format.dart';
import '../models/provider.dart';
import '../routes.dart';
import '../theme/servick_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final pending = model.expiredProviders;
    final wide = MediaQuery.sizeOf(context).width >= 560;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'لوحة تحكم المالك | Servick Admin',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
        ),
        backgroundColor: ServickColors.navy,
        actions: [
          IconButton(
            key: const Key('admin-settings'),
            tooltip: 'اقتراحات التعديل',
            icon: const Icon(Icons.edit_note),
            onPressed: () {
              Navigator.of(context).pushNamed(ServickRoutes.adminReview);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'نظرة عامة على النظام',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'عاين تفاصيل الحرفيين والطلبات، وافتح الشاشات كما يراها العميل، ثم سجّل ما يحتاج تعديلاً أو إضافة. التفعيل لا يخصم مبلغاً، والبيانات تبقى داخل الجلسة.',
                style: TextStyle(
                  color: ServickColors.muted,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('open-admin-review'),
                onPressed: () {
                  Navigator.of(context).pushNamed(ServickRoutes.adminReview);
                },
                icon: const Icon(Icons.manage_search),
                label: const Text('معاينة التفاصيل والاقتراحات'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('open-admin-desk'),
                onPressed: () {
                  Navigator.of(context).pushNamed(ServickRoutes.adminDesk);
                },
                icon: const Icon(Icons.tune),
                label: const Text('الأسعار والمراسلات والفوترة'),
              ),
              const SizedBox(height: 16),
              if (wide)
                Row(
                  children: [
                    Expanded(child: _providersCard(model.providers.length)),
                    const SizedBox(width: 12),
                    Expanded(child: _ordersCard(model.orderCount)),
                  ],
                )
              else ...[
                _providersCard(model.providers.length),
                const SizedBox(height: 12),
                _ordersCard(model.orderCount),
              ],
              const SizedBox(height: 24),
              const Text(
                'طلبات الحرفيين بانتظار الاعتماد وتفعيل الاشتراك',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              if (pending.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      'لا توجد طلبات انضمام جديدة بانتظار التفعيل',
                      key: Key('admin-empty'),
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                for (final account in pending) ...[
                  _PendingProviderCard(account: account),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _providersCard(int count) {
    return _StatCard(
      title: 'الحرفيون المسجلون',
      countKey: const Key('stat-providers'),
      count: count,
      icon: Icons.engineering,
      color: ServickColors.navy,
    );
  }

  Widget _ordersCard(int count) {
    return _StatCard(
      title: 'طلبات الصيانة النشطة',
      countKey: const Key('stat-orders'),
      count: count,
      icon: Icons.car_repair,
      color: const Color(0xFF10B981),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.countKey,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String title;
  final Key countKey;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            key: countKey,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingProviderCard extends StatelessWidget {
  const _PendingProviderCard({required this.account});

  final ProviderAccount account;

  @override
  Widget build(BuildContext context) {
    final technician = findTechnician(account.technicianId);
    final name = technician?.name ?? 'حرفي بدون اسم';
    final city = technician?.city ?? 'خميس مشيط';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFFEF3C7),
                  child: Icon(Icons.person_outline, color: Colors.amber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'الجوال: ${formatPhone(account.phone)} | المدينة: $city',
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton(
              key: Key('activate-provider-${account.id}'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () => _activate(context, account.id),
              child: const Text('تفعيل الحساب', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _activate(BuildContext context, String providerId) {
    final error = AppScope.of(context).activateProviderSubscription(providerId);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error == null
                ? 'تم تفعيل اشتراك الحرفي بنجاح!'
                : 'خطأ في التفعيل: $error',
          ),
        ),
      );
  }
}
