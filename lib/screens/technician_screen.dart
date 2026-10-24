import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/catalog.dart';
import '../data/format.dart';
import '../routes.dart';
import '../theme/servick_theme.dart';
import '../widgets/common.dart';
import '../widgets/copy_phone.dart';
import '../widgets/servick_scaffold.dart';

class TechnicianScreen extends StatelessWidget {
  const TechnicianScreen({super.key, required this.technicianId});

  final String technicianId;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final technician = model.technicianById(technicianId);
    if (technician == null) {
      return const ServickScaffold(
        title: 'الفني',
        showCity: false,
        body: Center(child: Text('هذا الفني غير موجود في القائمة.')),
      );
    }

    final category =
        model.categoryOf(technician.categoryId) ?? categories.first;
    final score = model.displayRating(technician);
    final review = model.displayReview(technician);
    return ServickScaffold(
      title: category.title,
      showCity: false,
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: () {
              Navigator.of(context)
                  .pushNamed(ServickRoutes.booking, arguments: technician.id);
            },
            child: Text(
              technician.available ? 'اطلب هذا الفني' : 'أرسل طلباً للفني',
            ),
          ),
        ),
      ),
      body: ServickFrame(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: ServickColors.line),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: category.color.withValues(alpha: 0.12),
                      child: Text(
                        initialOf(technician.name),
                        style: TextStyle(
                          color: category.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            technician.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${category.title} · ${technician.city}',
                            style: const TextStyle(color: ServickColors.muted),
                          ),
                          const SizedBox(height: 8),
                          StatusChip(
                            label: technician.available ? 'متاح الآن' : 'مشغول',
                            color: technician.available
                                ? ServickColors.success
                                : ServickColors.waiting,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'الخبرة',
                    value: '${technician.years} سنوات',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat(
                    label: 'الطلبات',
                    value: '${model.displayJobs(technician)}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat(
                    label: 'يبدأ من',
                    value: '${model.startingPriceOf(technician)} ر.س',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(technician.about, style: const TextStyle(height: 1.6)),
            const SizedBox(height: 8),
            Text(
              'الوصول التقديري خلال ${technician.etaMinutes} دقيقة داخل ${technician.city}. التقدير يتغير مع الزحمة.',
              style: const TextStyle(color: ServickColors.muted, height: 1.5),
            ),
            if (!technician.available) ...[
              const SizedBox(height: 8),
              const Text(
                'الفني مشغول الآن. الطلب يصل إليه ويراجعه عندما يتاح.',
                style: TextStyle(color: ServickColors.waiting, height: 1.5),
              ),
            ],
            const SizedBox(height: 16),
            const SectionTitle('الخدمات'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final service in technician.services)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        service,
                        style: TextStyle(
                          color: category.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            const SectionTitle('آخر تقييم'),
            const SizedBox(height: 8),
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: ServickColors.line),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: ServickColors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          score.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          review.author,
                          style: const TextStyle(color: ServickColors.muted),
                        ),
                      ],
                    ),
                    if (review.stars != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${review.stars} من 5',
                        key: const Key('latest-review-stars'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      review.text,
                      key: const Key('latest-review-text'),
                      style: const TextStyle(height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => copyPhone(context, technician.phone),
              icon: const Icon(Icons.content_copy, size: 18),
              label: PhoneLabel(prefix: 'رقم تجريبي', digits: technician.phone),
            ),
            const SizedBox(height: 12),
            const DemoNote(),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: ServickColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: ServickColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
