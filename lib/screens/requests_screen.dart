import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/catalog.dart';
import '../data/format.dart';
import '../models/models.dart';
import '../routes.dart';
import '../theme/servick_theme.dart';
import '../widgets/common.dart';
import '../widgets/servick_scaffold.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = AppScope.of(context).requests;
    return ServickScaffold(
      title: 'طلباتي',
      showCity: false,
      showRequests: false,
      body: ServickFrame(
        maxWidth: 760,
        child: requests.isEmpty
            ? const _EmptyRequests()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                itemCount: requests.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _RequestCard(request: requests[index]);
                },
              ),
      ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 48, color: ServickColors.muted),
            SizedBox(height: 12),
            Text(
              'لا توجد طلبات',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            SizedBox(height: 6),
            Text(
              'عند إرسال طلب طوارئ أو حجز يظهر هنا.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ServickColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final technician = findTechnician(request.technicianId);
    final statusColor = switch (request.status) {
      RequestStatus.assigned => ServickColors.success,
      RequestStatus.waiting => ServickColors.waiting,
      RequestStatus.completed => ServickColors.muted,
    };
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ServickColors.line),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            ServickRoutes.request,
            arguments: RequestRouteArgs(request: request),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                '${request.city} · ${request.whenLabel}',
                style: const TextStyle(color: ServickColors.muted),
              ),
              if (technician != null) ...[
                const SizedBox(height: 4),
                Text(technician.name),
              ],
              if (request.technicianId != null &&
                  request.status != RequestStatus.waiting &&
                  AppScope.of(context).ratingForRequest(request.id) ==
                      null) ...[
                const SizedBox(height: 8),
                const Text(
                  'قيّم مقدم الخدمة',
                  style: TextStyle(
                    color: ServickColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                formatRiyadh(request.createdAt),
                style: const TextStyle(
                  color: ServickColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
