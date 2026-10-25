import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/models.dart';
import '../theme/servick_theme.dart';
import '../widgets/servick_scaffold.dart';

class ProviderRegisterScreen extends StatefulWidget {
  const ProviderRegisterScreen({super.key});

  @override
  State<ProviderRegisterScreen> createState() => _ProviderRegisterScreenState();
}

class _ProviderRegisterScreenState extends State<ProviderRegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _email = TextEditingController();
  final _about = TextEditingController();
  var _city = cities.first;
  var _categoryId = 'petrol';
  var _accepted = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _email.dispose();
    _about.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    if (!_accepted) {
      _snack('يجب الموافقة على سياسة الخصوصية قبل إنشاء الحساب');
      return;
    }
    final model = AppScope.of(context);
    model.acceptPrivacy(audience: 'provider');
    final error = model.registerProvider(
      name: _name.text,
      phone: _phone.text,
      city: _city,
      categoryId: _categoryId,
      password: _password.text,
      email: _email.text,
      about: _about.text,
    );
    if (error != null) {
      _snack(error);
      return;
    }
    _snack(
      'تم إنشاء الحساب وحفظه. يظهر للمالك لتفعيله، ويدخل خلال المدة المجانية إن كانت مفتوحة. السداد هنا لا يخصم مبلغاً.',
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final categories = AppScope.of(context).serviceCategories;
    return ServickScaffold(
      title: 'تسجيل مقدم خدمة',
      showCity: false,
      body: ServickFrame(
        maxWidth: 560,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const Text(
              'الحساب يُحفظ على الويب ويظهر من أي جهاز. لا تُحذف بياناته إلا من المالك، أو بطلبك بعد موافقته.',
              style: TextStyle(color: ServickColors.muted, height: 1.6),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('provider-name'),
              controller: _name,
              decoration: const InputDecoration(labelText: 'الاسم'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('provider-reg-phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'الجوال'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('provider-reg-password'),
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                helperText: 'ستة أحرف على الأقل',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('provider-reg-email'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                helperText: 'يُستخدم لاسترجاع كلمة المرور',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('provider-city'),
              initialValue: _city,
              decoration: const InputDecoration(labelText: 'المدينة'),
              items: [
                for (final city in cities)
                  DropdownMenuItem(value: city, child: Text(city)),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _city = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('provider-category'),
              initialValue: categories.any((item) => item.id == _categoryId)
                  ? _categoryId
                  : categories.first.id,
              decoration: const InputDecoration(labelText: 'الخدمة'),
              items: [
                for (final category in categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.title),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _categoryId = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('provider-about'),
              controller: _about,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'نبذة قصيرة',
                alignLabelWithHint: true,
              ),
            ),
            CheckboxListTile(
              key: const Key('provider-reg-privacy'),
              contentPadding: EdgeInsets.zero,
              value: _accepted,
              onChanged: (value) => setState(() => _accepted = value ?? false),
              title: const Text(
                'أوافق على سياسة الخصوصية والشروط. المنصة وسيط، ورسوم الاشتراك غير مستردة.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            FilledButton(
              key: const Key('provider-register'),
              onPressed: _submit,
              child: const Text('إنشاء الحساب'),
            ),
          ],
        ),
      ),
    );
  }
}
