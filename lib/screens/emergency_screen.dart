import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/catalog.dart';
import '../data/format.dart';
import '../data/matching.dart';
import '../data/phone.dart';
import '../models/models.dart';
import '../routes.dart';
import '../theme/servick_theme.dart';
import '../widgets/common.dart';
import '../widgets/hood_open_scene.dart';
import '../widgets/copy_phone.dart';
import '../widgets/provider_rating_panel.dart';
import '../widgets/servick_scaffold.dart';
import '../widgets/technician_tile.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _place = TextEditingController();
  final _notes = TextEditingController();
  final _phone = TextEditingController();
  String? _issueId;
  String? _issueError;
  ServiceRequest? _request;

  @override
  void dispose() {
    _place.dispose();
    _notes.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    final issueOk = _issueId != null;
    final formOk = _formKey.currentState?.validate() ?? false;
    setState(() => _issueError = issueOk ? null : 'اختر نوع العطل');
    if (!issueOk || !formOk) return;

    final model = AppScope.of(context);
    final issue = issueById(_issueId!);
    final technician = nearestAvailable(
      city: model.city,
      categoryIds: issue.categoryIds,
    );
    final notes = _notes.text.trim();
    final request = model.submit(
      kind: RequestKind.emergency,
      categoryId: technician?.categoryId ?? issue.categoryIds.first,
      technicianId: technician?.id,
      city: model.city,
      summary: issue.label,
      details: [
        'الموقع: ${_place.text.trim()}',
        if (notes.isNotEmpty) notes,
      ].join('\n'),
      phone: _phone.text,
      whenLabel: 'فوراً',
      assignNow: technician != null,
    );
    setState(() => _request = request);
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    return ServickScaffold(
      title: 'طلب طوارئ',
      body: ServickFrame(
        maxWidth: 760,
        child: request == null
            ? _EmergencyForm(
                formKey: _formKey,
                city: AppScope.of(context).city,
                place: _place,
                notes: _notes,
                phone: _phone,
                issueId: _issueId,
                issueError: _issueError,
                onSelectIssue: (id) {
                  setState(() {
                    _issueId = id;
                    _issueError = null;
                  });
                },
                onSubmit: _submit,
              )
            : _EmergencyResult(request: request),
      ),
    );
  }
}

class _EmergencyForm extends StatelessWidget {
  const _EmergencyForm({
    required this.formKey,
    required this.city,
    required this.place,
    required this.notes,
    required this.phone,
    required this.issueId,
    required this.issueError,
    required this.onSelectIssue,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final String city;
  final TextEditingController place;
  final TextEditingController notes;
  final TextEditingController phone;
  final String? issueId;
  final String? issueError;
  final ValueChanged<String> onSelectIssue;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HoodOpenScene(),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    ServickColors.emergency,
                    ServickColors.emergencySoft,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'نبحث في $city عن أقرب فني متاح للطريق. إذا لم يتوفر أحد، يبقى الطلب محفوظاً.',
                  style: const TextStyle(color: Colors.white, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'نوع العطل',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final issue in roadsideIssues)
                  ChoiceChip(
                    avatar: Icon(
                      issue.icon,
                      size: 18,
                      color: issueId == issue.id
                          ? Colors.white
                          : ServickColors.navy,
                    ),
                    label: Text(issue.label),
                    selected: issueId == issue.id,
                    showCheckmark: false,
                    selectedColor: ServickColors.emergency,
                    labelStyle: TextStyle(
                      color: issueId == issue.id
                          ? Colors.white
                          : ServickColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => onSelectIssue(issue.id),
                  ),
              ],
            ),
            if (issueError != null) ...[
              const SizedBox(height: 8),
              Text(
                issueError!,
                style: const TextStyle(color: ServickColors.emergency),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('emergency-place'),
              controller: place,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'أقرب معلم',
                hintText: 'حي، شارع، أو محطة',
              ),
              validator: (value) {
                if ((value ?? '').trim().length < 3) {
                  return 'اكتب أقرب معلم للموقع';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('emergency-notes'),
              controller: notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'تفاصيل إضافية (اختياري)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('emergency-phone'),
              controller: phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: const InputDecoration(
                labelText: 'الجوال',
                hintText: '05xxxxxxxx',
              ),
              validator: validateSaudiMobile,
            ),
            const SizedBox(height: 18),
            FilledButton(
              key: const Key('send-emergency'),
              style: FilledButton.styleFrom(
                backgroundColor: ServickColors.emergency,
                foregroundColor: Colors.white,
              ),
              onPressed: onSubmit,
              child: const Text('إرسال طلب الطوارئ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyResult extends StatelessWidget {
  const _EmergencyResult({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final technician = findTechnician(request.technicianId);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            technician == null
                ? Icons.hourglass_top_rounded
                : Icons.check_circle_rounded,
            size: 56,
            color: technician == null
                ? ServickColors.waiting
                : ServickColors.success,
          ),
          const SizedBox(height: 12),
          Text(
            technician == null ? 'الطلب بانتظار فني' : 'تم توجيه الطلب',
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
          const SizedBox(height: 12),
          Text(
            technician == null
                ? 'الطلب ${request.id} محفوظ وبانتظار فني يتاح في ${request.city}.'
                : 'أقرب فني متاح هو ${technician.name}. الوصول التقديري خلال ${technician.etaMinutes} دقيقة داخل ${request.city}.',
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.6),
          ),
          const SizedBox(height: 16),
          if (technician != null) ...[
            TechnicianTile(technician: technician),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => copyPhone(context, technician.phone),
              icon: const Icon(Icons.content_copy, size: 18),
              label: PhoneLabel(prefix: 'رقم الفني', digits: technician.phone),
            ),
            const SizedBox(height: 8),
          ],
          Text.rich(
            TextSpan(
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
            textAlign: TextAlign.center,
          ),
          if (technician != null) ...[
            const SizedBox(height: 16),
            ProviderRatingPanel(requestId: request.id),
          ],
          const SizedBox(height: 12),
          const DemoNote(),
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
      ),
    );
  }
}
