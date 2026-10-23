import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/catalog.dart';
import '../data/format.dart';
import '../models/models.dart';
import '../models/order.dart';
import '../routes.dart';
import '../theme/servick_theme.dart';
import '../widgets/common.dart';
import '../widgets/servick_scaffold.dart';

class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final session = model.providerSession;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('لوحة مزود الخدمة')),
        body: Center(
          child: FilledButton(
            onPressed: () {
              Navigator.of(context).pushNamed(ServickRoutes.providerLogin);
            },
            child: const Text('تسجيل الدخول'),
          ),
        ),
      );
    }

    final technician = findTechnician(session.technicianId);
    final category = technician == null
        ? null
        : categoryById(technician.categoryId);
    final jobs = model.jobsFor(session);
    final expiry = session.subscriptionExpiry;

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات مزود الخدمة'),
        actions: [
          IconButton(
            key: const Key('provider-logout'),
            tooltip: 'تسجيل الخروج',
            onPressed: () {
              model.logoutProvider();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ServickFrame(
        maxWidth: 760,
        child: ListView(
          key: const Key('provider-dashboard'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const Text(
              'تم تسجيل الدخول بنجاح أهلاً بك في Servick',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: ServickColors.line),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      technician?.name ?? 'مزود الخدمة',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (category != null) category.title,
                        if (technician != null) technician.city,
                      ].join(' · '),
                      style: const TextStyle(color: ServickColors.muted),
                    ),
                    if (expiry != null) ...[
                      const SizedBox(height: 8),
                      Text('الاشتراك ساري حتى ${formatRiyadh(expiry)}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('open-subscription'),
              onPressed: () {
                Navigator.of(context).pushNamed(
                  ServickRoutes.providerSubscription,
                  arguments: session.id,
                );
              },
              icon: const Icon(Icons.verified_outlined),
              label: const Text('إدارة الاشتراك السنوي'),
            ),
            if (technician != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                key: const Key('open-nearby-orders'),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    ServickRoutes.providerOrders,
                    arguments: ProviderOrdersArgs(
                      providerId: session.id,
                      providerCity: technician.city,
                    ),
                  );
                },
                child: Text(
                  'طلبات الصيانة القريبة (${technician.city}) · ${model.pendingOrdersIn(technician.city).length}',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 18),
            const SectionTitle('طلبات العملاء'),
            const SizedBox(height: 10),
            if (jobs.isEmpty)
              const Padding(
                key: Key('provider-empty-jobs'),
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'لا توجد طلبات في مدينتك وتخصصك حالياً. عندما يرسل عميل طلباً يظهر هنا.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ServickColors.muted, height: 1.5),
                ),
              )
            else
              for (final job in jobs) ...[
                _JobCard(request: job, technicianId: session.technicianId),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.request, required this.technicianId});

  final ServiceRequest request;
  final String technicianId;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final statusColor = switch (request.status) {
      RequestStatus.assigned => ServickColors.success,
      RequestStatus.waiting => ServickColors.waiting,
      RequestStatus.completed => ServickColors.muted,
    };
    final mine = request.technicianId == technicianId;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ServickColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                StatusChip(
                  label: request.kind.label,
                  color: ServickColors.navy,
                ),
                const SizedBox(width: 8),
                StatusChip(label: request.status.label, color: statusColor),
                const Spacer(),
                Text(
                  request.id,
                  style: const TextStyle(
                    color: ServickColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              request.summary,
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.5),
            ),
            if (request.details.trim().isNotEmpty &&
                request.details.trim() != request.summary.trim()) ...[
              const SizedBox(height: 4),
              Text(request.details, style: const TextStyle(height: 1.5)),
            ],
            const SizedBox(height: 6),
            Text('${request.city} · ${request.whenLabel}'),
            const SizedBox(height: 4),
            Text('جوال العميل: ${formatPhone(request.phone)}'),
            if (request.status == RequestStatus.waiting) ...[
              const SizedBox(height: 12),
              FilledButton(
                key: Key('accept-${request.id}'),
                onPressed: () {
                  model.acceptRequest(
                    requestId: request.id,
                    technicianId: technicianId,
                  );
                },
                child: const Text('قبول الطلب'),
              ),
            ] else if (request.status == RequestStatus.assigned && mine) ...[
              const SizedBox(height: 12),
              FilledButton(
                key: Key('complete-${request.id}'),
                onPressed: () {
                  model.completeRequest(
                    requestId: request.id,
                    technicianId: technicianId,
                  );
                },
                child: const Text('تم التنفيذ'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
