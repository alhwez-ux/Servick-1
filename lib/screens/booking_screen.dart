import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/catalog.dart';
import '../data/client_plans.dart';
import '../data/phone.dart';
import '../models/models.dart';
import '../routes.dart';
import '../theme/servick_theme.dart';
import '../widgets/privacy_gate.dart';
import '../widgets/servick_scaffold.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.technicianId});

  final String technicianId;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _details = TextEditingController();
  final _phone = TextEditingController();
  String _when = 'خلال اليوم';

  static const _whenOptions = ['الآن', 'خلال اليوم', 'غداً'];

  @override
  void dispose() {
    _details.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit(Technician technician) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final allowed = await requireClientPrivacy(context);
    if (!allowed || !mounted) return;
    final block = AppScope.of(context).clientServiceBlock(demoClientId);
    if (block != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(block)));
      return;
    }
    final request = AppScope.of(context).submit(
      kind: RequestKind.booking,
      categoryId: technician.categoryId,
      technicianId: technician.id,
      city: technician.city,
      summary: _details.text.trim(),
      details: _details.text.trim(),
      phone: _phone.text,
      whenLabel: _when,
      assignNow: technician.available,
    );
    Navigator.of(context).pushNamed(
      ServickRoutes.request,
      arguments: RequestRouteArgs(request: request, justSent: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final technician = findTechnician(widget.technicianId);
    if (technician == null) {
      return const ServickScaffold(
        title: 'طلب الخدمة',
        showCity: false,
        body: Center(child: Text('هذا الفني غير موجود في القائمة.')),
      );
    }

    return ServickScaffold(
      title: 'طلب الخدمة',
      showCity: false,
      body: ServickFrame(
        maxWidth: 760,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  '${categoryById(technician.categoryId).title} · ${technician.city}',
                  style: const TextStyle(color: ServickColors.muted),
                ),
                const SizedBox(height: 8),
                Text(
                  'يبدأ من ${AppScope.of(context).startingPriceOf(technician)} ر.س. السعر النهائي بعد المعاينة.',
                  style: const TextStyle(height: 1.5),
                ),
                const SizedBox(height: 18),
                const Text(
                  'الوقت المناسب',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in _whenOptions)
                      ChoiceChip(
                        label: Text(option),
                        selected: _when == option,
                        showCheckmark: false,
                        selectedColor: ServickColors.navy,
                        labelStyle: TextStyle(
                          color: _when == option
                              ? Colors.white
                              : ServickColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setState(() => _when = option),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('booking-details'),
                  controller: _details,
                  minLines: 3,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: 'وصف العطل',
                    hintText: 'مثال: صوت طقطقة عند تشغيل المكينة',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length < 8) {
                      return 'اكتب وصف العطل (8 أحرف على الأقل)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('booking-phone'),
                  controller: _phone,
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
                  key: const Key('send-booking'),
                  onPressed: () {
                    _submit(technician);
                  },
                  child: const Text('تأكيد الطلب'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
