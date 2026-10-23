import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/format.dart';
import '../models/order.dart';
import '../theme/servick_theme.dart';

class ProviderOrdersScreen extends StatelessWidget {
  const ProviderOrdersScreen({
    super.key,
    required this.providerId,
    required this.providerCity,
  });

  final String providerId;
  final String providerCity;

  Future<void> _acceptOrder(BuildContext context, String orderId) async {
    final error = AppScope.of(context)
        .acceptOrder(orderId: orderId, providerId: providerId);
    if (!context.mounted) return;
    final message = error == null
        ? 'تم قبول الطلب بنجاح. توجه لموقع العميل الآن.'
        : 'خطأ في قبول الطلب: $error';
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _showNotifications(BuildContext context, List<ServiceOrder> orders) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'إشعارات الطلبات الفورية',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(height: 12),
                if (orders.isEmpty)
                  const Text(
                    'لا توجد إشعارات جديدة',
                    style: TextStyle(color: ServickColors.muted, height: 1.5),
                  )
                else
                  for (final order in orders) ...[
                    Text(
                      order.clientName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.serviceTitle} · ${order.city}',
                      style: const TextStyle(color: ServickColors.muted),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = AppScope.of(context).pendingOrdersIn(providerCity);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'طلبات الصيانة القريبة ($providerCity)',
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
        ),
        backgroundColor: ServickColors.navy,
        actions: [
          IconButton(
            key: const Key('provider-notifications'),
            tooltip: 'إشعارات الطلبات الفورية',
            icon: const Icon(Icons.notifications_active),
            onPressed: () => _showNotifications(context, orders),
          ),
        ],
      ),
      body: orders.isEmpty
          ? const Center(
              child: Column(
                key: Key('nearby-empty'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 70,
                    color: ServickColors.muted,
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'لا توجد طلبات جديدة متاحة حالياً في منطقتك',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ServickColors.muted,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              key: const Key('nearby-orders'),
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (_, index) {
                final order = orders[index];
                final notes = order.notes.trim().isEmpty
                    ? 'لا توجد ملاحظات إضافية'
                    : order.notes;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 3,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFE0E7FF),
                              child: Icon(
                                Icons.person,
                                color: ServickColors.navy,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                order.clientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                order.serviceTitle,
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(
                              Icons.notes,
                              size: 18,
                              color: ServickColors.muted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'وصف العطل: $notes',
                                style: const TextStyle(
                                  color: ServickColors.muted,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 18,
                              color: ServickColors.emergency,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'الموقع: $providerCity (قريب منك)',
                                style: const TextStyle(
                                  color: ServickColors.muted,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 18,
                              color: ServickColors.muted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                formatRiyadh(order.createdAt),
                                style: const TextStyle(
                                  color: ServickColors.muted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: FilledButton.icon(
                            key: Key('accept-order-${order.id}'),
                            onPressed: () => _acceptOrder(context, order.id),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'قبول الطلب وبدء الخدمة',
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
              },
            ),
    );
  }
}
