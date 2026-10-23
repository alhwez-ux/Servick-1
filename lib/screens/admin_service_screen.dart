import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../theme/servick_theme.dart';

class AdminServiceScreen extends StatefulWidget {
  const AdminServiceScreen({super.key});

  @override
  State<AdminServiceScreen> createState() => _AdminServiceScreenState();
}

class _AdminServiceScreenState extends State<AdminServiceScreen> {
  final _title = TextEditingController();
  final _subtitle = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  void _save() {
    final error = AppScope.of(context)
        .addService(title: _title.text, subtitle: _subtitle.text);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'تمت إضافة الخدمة وتظهر الآن في الرئيسية'),
      ),
    );
    if (error == null) {
      _title.clear();
      _subtitle.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final added = AppScope.of(context).addedServices;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إضافة خدمة جديدة',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const Text(
                  'الخدمة تُضاف إلى شبكة الرئيسية في هذه الجلسة. لا تُنشئ حرفيين جدداً، ويظهر للعميل أنها غير متوفرة إلى أن يُربط بها فني.',
                  style: TextStyle(height: 1.6, color: ServickColors.muted),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('service-title'),
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'اسم الخدمة',
                    hintText: 'مثال: صيانة مكيفات السيارات',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('service-subtitle'),
                  controller: _subtitle,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'وصف مختصر',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('save-service'),
                  onPressed: _save,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة خدمة جديدة'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'خدمات هذه الجلسة',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (added.isEmpty)
                  const Text(
                    'لم تُضف خدمة بعد.',
                    key: Key('added-services-empty'),
                    style: TextStyle(color: ServickColors.muted, height: 1.5),
                  )
                else
                  for (final service in added)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(service.icon, color: service.color),
                        title: Text(
                          service.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          service.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
