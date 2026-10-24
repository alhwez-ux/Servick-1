import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/admin.dart';
import '../data/catalog.dart';
import '../data/client_plans.dart';
import '../data/format.dart';
import '../models/client_subscription.dart';
import '../models/models.dart';
import '../models/order.dart';
import '../models/provider.dart';
import '../routes.dart';
import '../theme/servick_theme.dart';
import '../widgets/common.dart';
import '../widgets/servick_scaffold.dart';

class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  final _suggestionController = TextEditingController();
  String _area = ownerSuggestionAreas.keys.first;

  @override
  void dispose() {
    _suggestionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('معاينة التفاصيل')),
      body: ServickFrame(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'هذه شاشة المالك لمراجعة المحتوى كما يظهر للعميل والحرفي. افتح أي شاشة، ثم سجّل في الأسفل ما يحتاج تعديلاً أو إضافة.',
                style: TextStyle(color: ServickColors.muted, height: 1.6),
              ),
              const SizedBox(height: 20),
              const SectionTitle('معاينة الشاشات'),
              const SizedBox(height: 10),
              _PreviewLinks(),
              const SizedBox(height: 24),
              const SectionTitle('دليل الفنيين'),
              const SizedBox(height: 6),
              Text(
                '${model.technicians.length} فنياً مسجّلين. المس أي اسم لفتح صفحته.',
                key: const Key('review-providers'),
                style: const TextStyle(color: ServickColors.muted, height: 1.5),
              ),
              const SizedBox(height: 12),
              for (final city in cities) ...[
                Text(
                  city,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ServickColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                for (final technician in model.technicians)
                  if (technician.city == city) ...[
                    _TechnicianDetail(technician: technician),
                    const SizedBox(height: 8),
                  ],
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 16),
              const SectionTitle('الطلبات'),
              const SizedBox(height: 6),
              Text(
                '${model.orderCount} طلباً محفوظاً على الويب.',
                key: const Key('review-orders'),
                style: const TextStyle(color: ServickColors.muted, height: 1.5),
              ),
              const SizedBox(height: 12),
              for (final order in model.orders) ...[
                _OrderDetail(order: order),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 16),
              const SectionTitle('اقتراحات التعديل والإضافة'),
              const SizedBox(height: 8),
              _SuggestionForm(
                area: _area,
                controller: _suggestionController,
                onArea: (area) => setState(() => _area = area),
                onSubmit: _submit,
              ),
              const SizedBox(height: 12),
              if (model.ownerSuggestions.isEmpty)
                const Text(
                  'لم تُسجل اقتراحات بعد. اكتب ما تريد تعديله أو إضافته.',
                  key: Key('suggestions-empty'),
                  style: TextStyle(color: ServickColors.muted, height: 1.6),
                )
              else
                for (final suggestion in model.ownerSuggestions) ...[
                  _SuggestionCard(suggestion: suggestion),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final error = AppScope.of(context)
        .addOwnerSuggestion(area: _area, text: _suggestionController.text);
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'تم حفظ اقتراحك للمراجعة')),
    );
    if (error == null) _suggestionController.clear();
  }
}

class _PreviewLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final links = <_PreviewLink>[
      _PreviewLink(
        keyName: 'preview-home',
        label: 'الرئيسية',
        icon: Icons.home_outlined,
        onTap: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
      _PreviewLink(
        keyName: 'preview-client-order',
        label: 'طلب صيانة عاجلة',
        icon: Icons.home_repair_service_outlined,
        onTap: () {
          Navigator.of(context).pushNamed(
            ServickRoutes.clientOrder,
            arguments: const ClientOrderArgs(
              clientId: demoClientId,
              clientName: demoClientName,
            ),
          );
        },
      ),
      _PreviewLink(
        keyName: 'preview-client-plans',
        label: 'باقات العملاء',
        icon: Icons.card_membership,
        onTap: () {
          Navigator.of(context).pushNamed(
            ServickRoutes.clientSubscription,
            arguments: const ClientSubscriptionArgs(
              clientId: demoClientId,
              isAdmin: false,
            ),
          );
        },
      ),
      _PreviewLink(
        keyName: 'preview-emergency',
        label: 'طلب طوارئ',
        icon: Icons.warning_amber_rounded,
        onTap: () {
          Navigator.of(context).pushNamed(ServickRoutes.emergency);
        },
      ),
      _PreviewLink(
        keyName: 'preview-provider',
        label: 'دخول الحرفي',
        icon: Icons.engineering_rounded,
        onTap: () {
          Navigator.of(context).pushNamed(ServickRoutes.providerLogin);
        },
      ),
      _PreviewLink(
        keyName: 'preview-technician',
        label: 'صفحة فهد الشهري',
        icon: Icons.person_outline,
        onTap: () {
          Navigator.of(context)
              .pushNamed(ServickRoutes.technician, arguments: 'p-km-1');
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final link in links) ...[
                _PreviewButton(link: link),
                const SizedBox(height: 8),
              ],
            ],
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final link in links) _PreviewButton(link: link)],
        );
      },
    );
  }
}

class _PreviewLink {
  const _PreviewLink({
    required this.keyName,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String keyName;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _PreviewButton extends StatelessWidget {
  const _PreviewButton({required this.link});

  final _PreviewLink link;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: Key(link.keyName),
      onPressed: link.onTap,
      icon: Icon(link.icon, size: 18),
      label: Text(link.label),
    );
  }
}

class _TechnicianDetail extends StatelessWidget {
  const _TechnicianDetail({required this.technician});

  final Technician technician;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final category = categoryById(technician.categoryId);
    final account = _accountFor(model, technician.id);
    final subscribed = account?.isSubscribedAt(model.now) ?? false;
    final status = account == null
        ? 'غير مسجّل'
        : subscribed
        ? 'اشتراك ساري'
        : 'اشتراك منتهٍ';
    final statusColor = account == null
        ? ServickColors.muted
        : subscribed
        ? ServickColors.success
        : ServickColors.waiting;
    final expiry = account?.subscriptionExpiry;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: ServickColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('review-tech-${technician.id}'),
        onTap: () {
          Navigator.of(context)
              .pushNamed(ServickRoutes.technician, arguments: technician.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: category.color.withValues(alpha: 0.12),
                    child: Text(
                      initialOf(technician.name),
                      style: TextStyle(
                        color: category.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          technician.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${category.title} · ${technician.city}',
                          style: const TextStyle(
                            color: ServickColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(
                    label: technician.available ? 'متاح' : 'غير متاح',
                    color: technician.available
                        ? ServickColors.success
                        : ServickColors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'التقييم ${model.displayRating(technician).toStringAsFixed(1)} · ${model.displayJobs(technician)} طلباً · يصل خلال ${technician.etaMinutes} د · يبدأ من ${model.startingPriceOf(technician)} ر.س',
                style: const TextStyle(fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'الجوال '),
                    TextSpan(text: formatPhone(technician.phone)),
                    TextSpan(text: ' · $status'),
                    if (expiry != null)
                      TextSpan(text: ' حتى ${formatSubscriptionDate(expiry)}'),
                  ],
                ),
                style: TextStyle(fontSize: 12, height: 1.5, color: statusColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ProviderAccount? _accountFor(AppModel model, String technicianId) {
    for (final account in model.providers) {
      if (account.technicianId == technicianId) return account;
    }
    return null;
  }
}

class _OrderDetail extends StatelessWidget {
  const _OrderDetail({required this.order});

  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    final pending = order.status == 'pending';
    final accepted = order.status == 'accepted';
    final label = pending
        ? 'معلّق'
        : accepted
        ? 'مقبول'
        : order.status;

    return Container(
      key: Key('order-detail-${order.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ServickColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.serviceTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              StatusChip(
                label: label,
                color: pending
                    ? ServickColors.waiting
                    : accepted
                    ? ServickColors.success
                    : ServickColors.navy,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${order.clientName} · ${order.city} · ${formatRiyadh(order.createdAt)}',
            style: const TextStyle(color: ServickColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(order.notes, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}

class _SuggestionForm extends StatelessWidget {
  const _SuggestionForm({
    required this.area,
    required this.controller,
    required this.onArea,
    required this.onSubmit,
  });

  final String area;
  final TextEditingController controller;
  final ValueChanged<String> onArea;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('suggestion-form'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ServickColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'موضع الاقتراح',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in ownerSuggestionAreas.entries)
                ChoiceChip(
                  key: Key('suggestion-area-${entry.key}'),
                  label: Text(entry.value),
                  selected: area == entry.key,
                  onSelected: (_) => onArea(entry.key),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('suggestion-text'),
            controller: controller,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText:
                  'مثال: أضف صورة للفني في بطاقة الدليل، أو غيّر سعر البداية',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('submit-suggestion'),
            onPressed: onSubmit,
            child: const Text('حفظ الاقتراح'),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion});

  final OwnerSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final area = ownerSuggestionAreas[suggestion.area] ?? suggestion.area;
    return Container(
      key: Key('suggestion-${suggestion.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$area · ${formatRiyadh(suggestion.createdAt)}',
            style: const TextStyle(
              color: ServickColors.waiting,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(suggestion.text, style: const TextStyle(height: 1.5)),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: Key('delete-suggestion-${suggestion.id}'),
              onPressed: () {
                AppScope.of(context).removeOwnerSuggestion(suggestion.id);
              },
              child: const Text('حذف الاقتراح'),
            ),
          ),
        ],
      ),
    );
  }
}
