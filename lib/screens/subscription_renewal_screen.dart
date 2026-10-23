import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/catalog.dart';
import '../data/format.dart';
import '../data/providers.dart';
import '../routes.dart';
import '../theme/servick_theme.dart';

class SubscriptionRenewalScreen extends StatelessWidget {
  const SubscriptionRenewalScreen({super.key, required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final account = model.providerById(providerId);
    if (account == null) {
      return const Scaffold(
        body: Center(child: Text('تعذر العثور على حساب المزود.')),
      );
    }

    final technician = findTechnician(account.technicianId);
    final category = technician == null
        ? null
        : categoryById(technician.categoryId);
    final renewalDate = model.now.add(
      const Duration(days: annualSubscriptionDays),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('تجديد الاشتراك السنوي')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Icon(
                  Icons.event_repeat,
                  size: 56,
                  color: ServickColors.navy,
                ),
                const SizedBox(height: 12),
                Text(
                  technician?.name ?? 'مزود الخدمة',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (category != null) category.title,
                    if (technician != null) technician.city,
                  ].join(' · '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ServickColors.muted),
                ),
                const SizedBox(height: 20),
                _FeeRow(label: 'حالة الاشتراك', value: 'منتهي'),
                _FeeRow(label: 'التجديد حتى', value: formatRiyadh(renewalDate)),
                _FeeRow(
                  label: 'رسوم السنة',
                  value: '$annualSubscriptionFee ر.س',
                ),
                const SizedBox(height: 12),
                const Text(
                  'سداد تجريبي. لا يُخصم مبلغ حقيقي، ويتفعل الحساب داخل هذه الجلسة فقط.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ServickColors.muted,
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('pay-subscription'),
                  onPressed: () {
                    final renewed = model.renewSubscription(providerId);
                    if (renewed == null || !context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      ServickRoutes.providerDashboard,
                      (route) => route.isFirst,
                    );
                  },
                  child: const Text('تأكيد السداد وتفعيل الحساب'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: ServickColors.muted),
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
