import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/client_plans.dart';
import '../data/format.dart';
import '../routes.dart';
import '../theme/servick_theme.dart';
import '../widgets/privacy_gate.dart';
import 'client_auth_screen.dart';

class ClientSubscriptionScreen extends StatefulWidget {
  const ClientSubscriptionScreen({
    super.key,
    required this.clientId,
    this.isAdmin = false,
    this.catalog = false,
  });

  final String clientId;
  final bool isAdmin;
  final bool catalog;

  @override
  State<ClientSubscriptionScreen> createState() =>
      _ClientSubscriptionScreenState();
}

class _ClientSubscriptionScreenState extends State<ClientSubscriptionScreen> {
  String? _selectedPlanId;
  String? _assignClientId;

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _subscribeClient(ClientPlan plan) async {
    final model = AppScope.of(context);
    final owner = widget.isAdmin && model.adminUnlocked;
    if (owner && plan.adminOnly && _assignClientId == null) {
      _snack('اختر العميل الذي ستُخصص له الباقة');
      return;
    }
    final sessionId = model.clientSession?.id ?? '';
    final target = owner && _assignClientId != null
        ? _assignClientId!
        : (widget.clientId.isNotEmpty ? widget.clientId : sessionId);
    if (target.isEmpty) {
      _snack('أنشئ حساب عميل قبل تأكيد الاشتراك');
      await Navigator.of(context).pushNamed(
        ServickRoutes.clientAuth,
        arguments: const ClientAuthArgs(register: true),
      );
      return;
    }
    final allowed = await requireClientPrivacy(context);
    if (!allowed || !mounted) return;
    final error = AppScope.of(
      context,
    ).subscribeClient(clientId: target, planId: plan.id, months: plan.months);
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
      SnackBar(
        content: Text(
          owner && _assignClientId != null
              ? 'تم تخصيص الباقة للعميل.'
              : 'تم تفعيل باقتك بنجاح في رابط! مرحباً بك.',
        ),
      ),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final owner = widget.isAdmin && model.adminUnlocked;
    final availablePlans = plansFor(isAdmin: owner);
    final clients = model.clientAccounts;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.catalog ? 'باقات الاشتراك | رابط' : 'اشتراك العملاء | رابط',
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
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
            if (owner) ...[
              const SizedBox(height: 8),
              const Text(
                'باقة المالك الخاصة تظهر لك وحدك. اختر العميل لتخصيصها له.',
                style: TextStyle(
                  fontSize: 12,
                  color: ServickColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              if (clients.isEmpty)
                const Text(
                  'لا يوجد عملاء مسجلون بعد.',
                  key: Key('owner-plan-clients-empty'),
                  style: TextStyle(color: ServickColors.muted, height: 1.5),
                )
              else
                DropdownButtonFormField<String>(
                  key: const Key('owner-plan-client'),
                  initialValue: _assignClientId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'تخصيص الباقة للعميل',
                  ),
                  items: [
                    for (final client in clients)
                      DropdownMenuItem(
                        value: client.id,
                        child: Text('${client.name} · ${client.city}'),
                      ),
                  ],
                  onChanged: (value) => setState(() => _assignClientId = value),
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
                    child: InkWell(
                      key: Key('plan-${plan.id}'),
                      onTap: () => setState(() => _selectedPlanId = plan.id),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: plan.color.withValues(
                                alpha: 0.12,
                              ),
                              child: Icon(Icons.star, color: plan.color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'المدة: ${plan.duration}',
                                    style: const TextStyle(
                                      color: ServickColors.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${isolateLtr('$price')} ريال',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: plan.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
