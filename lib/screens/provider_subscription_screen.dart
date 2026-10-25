import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/format.dart';
import '../routes.dart';
import '../theme/servick_theme.dart';

class ProviderSubscriptionScreen extends StatefulWidget {
  const ProviderSubscriptionScreen({super.key, required this.providerId});

  final String providerId;

  @override
  State<ProviderSubscriptionScreen> createState() =>
      _ProviderSubscriptionScreenState();
}

class _ProviderSubscriptionScreenState
    extends State<ProviderSubscriptionScreen> {
  var _reportedMissing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final account = AppScope.of(context).providerById(widget.providerId);
    if (account != null || _reportedMissing) return;
    _reportedMissing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'خطأ في جلب بيانات الاشتراك: تعذر العثور على حساب المزود',
          ),
        ),
      );
    });
  }

  void _renewSubscription() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'تأكيد تجديد الاشتراك السنوي',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'تلك الخطوة ستقوم بتحويلك لبوابة الدفع الآمنة لسداد رسوم الاشتراك السنوي لباقة مزودي الخدمات في رابط.\n\n(رسوم الاشتراك السنوي: تمكنك من استقبال طلبات غير محدودة بدون عمولة).',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          actions: [
            FilledButton(
              key: const Key('confirm-payment'),
              style: FilledButton.styleFrom(
                backgroundColor: ServickColors.navy,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _updateSubscriptionInDB();
              },
              child: const Text('متابعة للدفع (مدى / فيزا)'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: ServickColors.muted),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateSubscriptionInDB() {
    final renewed = AppScope.of(context).renewSubscription(widget.providerId);
    if (!mounted) return;
    final message = renewed == null
        ? 'حدث خطأ أثناء التحديث: تعذر العثور على حساب المزود'
        : 'تم تجديد اشتراكك السنوي بنجاح! شكراً لانضمامك لرابط';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final account = model.providerById(widget.providerId);
    final expiry = account?.subscriptionExpiry;
    final isActive = account?.isSubscribedAt(model.now) ?? false;
    final formattedDate = expiry == null
        ? 'غير متوفر'
        : formatSubscriptionDate(expiry);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إدارة الاشتراك السنوي | رابط',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
        ),
        backgroundColor: ServickColors.navy,
      ),
      body: account == null
          ? const Center(child: Text('تعذر العثور على حساب المزود.'))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _StatusCard(
                            isActive: isActive,
                            formattedDate: formattedDate,
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'مميزات باقة مزودي الخدمات:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const _FeatureRow(
                            'ظهور مستمر في نتائج بحث العملاء في (خميس مشيط، أبها، أحد رفيدة).',
                          ),
                          const _FeatureRow(
                            'الحصول على أرباحك كاملة 100% بدون أي عمولات مقتطعة.',
                          ),
                          const _FeatureRow(
                            'تنبيهات فورية عند طلب أي عطل طارئ بالقرب من موقعك.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    'سداد تجريبي · ${isolateLtr('${model.providerAnnualFee}')} ر.س · لا يُخصم مبلغ حقيقي.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ServickColors.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('renew-subscription'),
                      onPressed: _renewSubscription,
                      style: FilledButton.styleFrom(
                        backgroundColor: ServickColors.navy,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isActive
                            ? 'تجديد الاشتراك لمدة سنة إضافية'
                            : 'سداد رسوم التجديد وتفعيل الحساب',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (model.providerSession?.id == widget.providerId) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      key: const Key('open-dashboard-from-subscription'),
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          ServickRoutes.providerDashboard,
                          (route) => route.isFirst,
                        );
                      },
                      child: const Text('الانتقال إلى لوحة الطلبات'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.isActive, required this.formattedDate});

  final bool isActive;
  final String formattedDate;

  @override
  Widget build(BuildContext context) {
    final tone = isActive ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.green.shade300 : Colors.red.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isActive ? Icons.verified_rounded : Icons.warning_amber_rounded,
            size: 50,
            color: tone,
          ),
          const SizedBox(height: 12),
          Text(
            isActive
                ? 'حسابك مفعل وجاهز لاستقبال الطلبات'
                : 'اشتراكك السنوي منتهي أو غير مفعل',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تاريخ انتهاء الاشتراك: $formattedDate',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 20, color: ServickColors.navy),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
