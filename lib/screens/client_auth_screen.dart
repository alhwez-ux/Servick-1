import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/models.dart';
import '../theme/servick_theme.dart';
import '../widgets/servick_scaffold.dart';

class ClientAuthArgs {
  const ClientAuthArgs({required this.register});

  final bool register;
}

class ClientAuthScreen extends StatefulWidget {
  const ClientAuthScreen({super.key, required this.register});

  final bool register;

  @override
  State<ClientAuthScreen> createState() => _ClientAuthScreenState();
}

class _ClientAuthScreenState extends State<ClientAuthScreen> {
  late var _register = widget.register;
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  var _city = cities.first;
  var _accepted = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    if (!_accepted) {
      _snack('يجب الموافقة على سياسة الخصوصية قبل المتابعة');
      return;
    }
    final model = AppScope.of(context);
    model.acceptPrivacy(audience: 'client');
    if (_register) {
      final error = model.registerClient(
        name: _name.text,
        phone: _phone.text,
        city: _city,
        password: _password.text,
      );
      if (error != null) {
        _snack(error);
        return;
      }
    }
    final error = model.loginClient(
      phone: _phone.text,
      password: _password.text,
    );
    if (error != null) {
      _snack(error);
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ServickScaffold(
      title: _register ? 'إنشاء حساب عميل' : 'دخول العميل',
      showCity: false,
      body: ServickFrame(
        maxWidth: 560,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Text(
              _register
                  ? 'الحساب يُحفظ على الويب ويظهر من أي جهاز تدخل منه. كلمة المرور لا تُعرض كنص في السجل.'
                  : 'ادخل برقم الجوال وكلمة المرور التي سجّلت بها.',
              style: const TextStyle(color: ServickColors.muted, height: 1.6),
            ),
            const SizedBox(height: 16),
            if (_register) ...[
              TextField(
                key: const Key('client-name'),
                controller: _name,
                decoration: const InputDecoration(labelText: 'الاسم'),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              key: const Key('client-phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'الجوال'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('client-password'),
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور'),
            ),
            if (_register) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('client-city'),
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
            ],
            const SizedBox(height: 8),
            CheckboxListTile(
              key: const Key('client-privacy'),
              contentPadding: EdgeInsets.zero,
              value: _accepted,
              onChanged: (value) => setState(() => _accepted = value ?? false),
              title: const Text(
                'أوافق على سياسة الخصوصية وأقر بحدود مسؤولية المنصة',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('client-submit'),
              onPressed: _submit,
              child: Text(_register ? 'إنشاء الحساب' : 'دخول'),
            ),
            TextButton(
              key: const Key('client-auth-mode'),
              onPressed: () => setState(() => _register = !_register),
              child: Text(_register ? 'لدي حساب' : 'إنشاء حساب جديد'),
            ),
          ],
        ),
      ),
    );
  }
}
