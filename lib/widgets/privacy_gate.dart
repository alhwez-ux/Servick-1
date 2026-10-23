import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../routes.dart';
import '../theme/servick_theme.dart';

Future<bool> requireClientPrivacy(BuildContext context) async {
  final model = AppScope.of(context);
  if (model.clientPrivacyAccepted) return true;

  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const PrivacyConsentDialog(),
  );
  if (!context.mounted) return false;
  if (accepted == true) {
    AppScope.of(context).acceptPrivacy(audience: 'client');
    return true;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('لا يمكن المتابعة قبل الموافقة على سياسة الخصوصية'),
    ),
  );
  return false;
}

class PrivacyConsentDialog extends StatefulWidget {
  const PrivacyConsentDialog({super.key});

  @override
  State<PrivacyConsentDialog> createState() => _PrivacyConsentDialogState();
}

class _PrivacyConsentDialogState extends State<PrivacyConsentDialog> {
  var _accepted = false;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: const Text(
        'موافقة التسجيل',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420, maxHeight: height * 0.5),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'يقتصر دور سيرفيسك على الربط بين مقدمي الخدمة والعملاء. اختيار مقدم الخدمة مسؤولية العميل، وعليه التأكد من إمكانياته بالاتصال الهاتفي قبل الاتفاق.',
                style: TextStyle(height: 1.6),
              ),
              const SizedBox(height: 10),
              const Text(
                'لا يتحمل التطبيق ولا مالك التطبيق ولا فريق العمل أي مسؤولية عن الخلافات أو الأضرار التي تقع بين الطرفين.',
                style: TextStyle(height: 1.6),
              ),
              const SizedBox(height: 10),
              const Text(
                'الحرفيون مستقلون. رسوم الاشتراك مقابل استخدام المنصة فقط، والسداد في هذه النسخة محاكاة لا تخصم مبلغاً حقيقياً. البيانات تبقى على هذا الجهاز خلال الجلسة.',
                style: TextStyle(height: 1.6, color: ServickColors.muted),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  key: const Key('open-privacy-from-dialog'),
                  onPressed: () {
                    Navigator.of(context).pushNamed(ServickRoutes.privacy);
                  },
                  child: const Text('قراءة النص الكامل'),
                ),
              ),
              InkWell(
                key: const Key('privacy-checkbox'),
                onTap: () => setState(() => _accepted = !_accepted),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _accepted,
                      onChanged: (value) {
                        setState(() => _accepted = value ?? false);
                      },
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          'أوافق على سياسة الخصوصية وأقر بحدود مسؤولية المنصة',
                          style: TextStyle(height: 1.45),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('accept-privacy'),
                onPressed: _accepted
                    ? () => Navigator.of(context).pop(true)
                    : null,
                child: const Text('أوافق وأتابع'),
              ),
              TextButton(
                key: const Key('decline-privacy'),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('لا أوافق'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
