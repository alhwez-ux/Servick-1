import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/format.dart';
import '../models/models.dart';
import '../routes.dart';
import '../theme/servick_theme.dart';
import '../widgets/common.dart';
import '../widgets/copy_phone.dart';
import '../widgets/provider_rating_panel.dart';
import '../widgets/servick_scaffold.dart';
import '../widgets/technician_tile.dart';

class RequestDetailsScreen extends StatelessWidget {
  const RequestDetailsScreen({
    super.key,
    required this.request,
    this.justSent = false,
  });

  final ServiceRequest request;
  final bool justSent;

  @override
  Widget build(BuildContext context) {
    final technician = findTechnician(request.technicianId);
    final category = categoryById(request.categoryId);
    final assigned = request.status != RequestStatus.waiting;
    final showDetails =
        request.details.trim().isNotEmpty &&
        request.details.trim() != request.summary.trim();

    return ServickScaffold(
      title: justSent ? 'تم الإرسال' : 'تفاصيل الطلب',
      showCity: false,
      body: ServickFrame(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Icon(
              assigned
                  ? Icons.check_circle_rounded
                  : Icons.hourglass_top_rounded,
              size: 56,
              color: assigned ? ServickColors.success : ServickColors.waiting,
            ),
            const SizedBox(height: 12),
            Text(
              justSent ? 'تم إرسال طلبك' : request.status.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              request.id,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ServickColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(label: 'الخدمة', value: category.title),
            _InfoRow(label: 'النوع', value: request.kind.label),
            _InfoRow(label: 'المدينة', value: request.city),
            _InfoRow(label: 'الوقت', value: request.whenLabel),
            _InfoRow(label: 'أُرسل', value: formatRiyadh(request.createdAt)),
            const SizedBox(height: 8),
            Text(
              request.summary,
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.5),
            ),
            if (showDetails) ...[
              const SizedBox(height: 6),
              Text(request.details, style: const TextStyle(height: 1.6)),
            ],
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                style: const TextStyle(color: ServickColors.muted),
                children: [
                  const TextSpan(text: 'جوال الطلب: '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        formatPhone(request.phone),
                        style: const TextStyle(color: ServickColors.muted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (technician != null) ...[
              const SizedBox(height: 16),
              const SectionTitle('الفني'),
              const SizedBox(height: 8),
              TechnicianTile(technician: technician),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => copyPhone(context, technician.phone),
                icon: const Icon(Icons.content_copy, size: 18),
                label: PhoneLabel(
                  prefix: 'رقم الفني',
                  digits: technician.phone,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ProviderRatingPanel(requestId: request.id),
            const SizedBox(height: 12),
            const DemoNote(),
            if (justSent) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('العودة للرئيسية'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(ServickRoutes.requests);
                },
                child: const Text('طلباتي'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(color: ServickColors.muted),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
