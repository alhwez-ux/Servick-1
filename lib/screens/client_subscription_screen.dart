import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/client_plans.dart';
import '../data/format.dart';
import '../theme/servick_theme.dart';

class ClientSubscriptionScreen extends StatefulWidget {
  const ClientSubscriptionScreen({
    super.key,
    required this.clientId,
    this.isAdmin = false,
  });

  final String clientId;
  final bool isAdmin;

  @override
  State<ClientSubscriptionScreen> createState() =>
      _ClientSubscriptionScreenState();
}

class _ClientSubscriptionScreenState extends State<ClientSubscriptionScreen> {
  String? _selectedPlanId;

  void _subscribeClient(ClientPlan plan) {
    final error = AppScope.of(context).subscribeClient(
      clientId: widget.clientId,
      planId: plan.id,
      months: plan.months,
    );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الاشتراك: $error')),
      );
      return;
    }
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('تم تفعيل باقتك بنجاح في Servick! مرحباً بك.'),
      ),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final availablePlans = plansFor(isAdmin: widget.isAdmin);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'باقات اشتراك العملاء | Servick',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
        ),
        backgroundColor: ServickColors.navy,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر الباقة المناسبة لك للوصول إلى كافة مزودي الخدمات في خميس مشيط، أبها، وأحد رفيدة:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            if (widget.isAdmin) ...[
              const SizedBox(height: 8),
              const Text(
                'معاينة المالك: الباقة الخاصة تجريبية ولا تفتح صلاحية حقيقية.',
                style: TextStyle(
                  fontSize: 12,
                  color: ServickColors.muted,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: availablePlans.length,
                itemBuilder: (context, index) {
                  final plan = availablePlans[index];
                  final isSelected = _selectedPlanId == plan.id;
                  final price = AppScope.of(context).planPriceOf(plan.id);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    elevation: isSelected ? 4 : 1,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isSelected
                            ? ServickColors.navy
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      key: Key('plan-${plan.id}'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: plan.color.withValues(alpha: 0.12),
                        child: Icon(Icons.star, color: plan.color),
                      ),
                      title: Text(
                        plan.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'المدة: ${plan.duration}',
                        style: const TextStyle(
                          color: ServickColors.muted,
                          fontSize: 13,
                        ),
                      ),
                      trailing: Text(
                        '${isolateLtr('$price')} ريال',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: plan.color,
                        ),
                      ),
                      onTap: () => setState(() => _selectedPlanId = plan.id),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'سداد تجريبي. لا يُخصم مبلغ حقيقي.',
              style: TextStyle(
                color: ServickColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                key: const Key('confirm-client-plan'),
                onPressed: _selectedPlanId == null
                    ? null
                    : () {
                        final selectedPlan = clientPlanById(_selectedPlanId!);
                        if (selectedPlan == null) return;
                        _subscribeClient(selectedPlan);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: ServickColors.navy,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'تأكيد الاشتراك والانطلاق',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
