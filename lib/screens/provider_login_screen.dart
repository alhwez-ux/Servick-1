import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/catalog.dart';
import '../data/providers.dart';
import '../models/provider.dart';
import '../routes.dart';
import '../theme/servick_theme.dart';
import '../widgets/servick_scaffold.dart';

class ProviderLoginScreen extends StatefulWidget {
  const ProviderLoginScreen({super.key});

  @override
  State<ProviderLoginScreen> createState() => _ProviderLoginScreenState();
}

class _ProviderLoginScreenState extends State<ProviderLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptedPrivacy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loginProvider() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    if (phone.isEmpty || password.isEmpty) {
      _snack('الرجاء إدخال رقم الجوال وكلمة المرور');
      return;
    }
    if (!_acceptedPrivacy) {
      _snack('يجب الموافقة على سياسة الخصوصية قبل تسجيل الدخول');
      return;
    }
    AppScope.of(context).acceptPrivacy(audience: 'provider');

    setState(() => _isLoading = true);
    final result = AppScope.of(context)
        .loginProvider(phone: phone, password: password);
    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case ProviderLoginSuccess():
        Navigator.of(context).pushNamedAndRemoveUntil(
          ServickRoutes.providerDashboard,
          (route) => route.isFirst,
        );
      case ProviderSubscriptionExpired(:final account):
        _showSubscriptionExpiredDialog(account.id);
      case ProviderFreePeriodEnded(:final account):
        _showFreePeriodEndedDialog(account.id);
      case ProviderLoginFailure(:final message):
        _snack(message);
    }
  }

  void _showFreePeriodEndedDialog(String providerId) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'انتهت المدة المجانية',
            style: TextStyle(
              color: ServickColors.emergency,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'توقفت خدمات التطبيق حتى دفع رسوم الاشتراك.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ServickColors.navy,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(
                  context,
                ).pushNamed(ServickRoutes.providerRenew, arguments: providerId);
              },
              child: const Text('سداد رسوم الاشتراك'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: ServickColors.muted),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSubscriptionExpiredDialog(String providerId) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'اشتراكك السنوي منتهي',
            style: TextStyle(
              color: ServickColors.emergency,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'عذراً، اشتراكك السنوي في منصة Servick قد انتهى. يرجى سداد رسوم الاشتراك السنوي لتفعيل حسابك واستقبال طلبات العملاء مجدداً.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ServickColors.navy,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(
                  context,
                ).pushNamed(ServickRoutes.providerRenew, arguments: providerId);
              },
              child: const Text('تجديد الاشتراك الآن'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: ServickColors.muted),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    return ServickScaffold(
      title: 'دخول مزودي الخدمات',
      showCity: false,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.engineering_rounded,
                    size: 40,
                    color: ServickColors.navy,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'بوابة الحرفيين والورش',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'أدخل بياناتك لاستقبال طلبات الصيانة في خميس مشيط، أبها، وأحد رفيدة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: ServickColors.muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('provider-phone'),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      labelText: 'رقم الجوال (مثال: 05xxxxxxxx)',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('provider-password'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'إظهار كلمة المرور'
                            : 'إخفاء كلمة المرور',
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    key: const Key('provider-privacy'),
                    onTap: _isLoading
                        ? null
                        : () {
                            setState(
                              () => _acceptedPrivacy = !_acceptedPrivacy,
                            );
                          },
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _acceptedPrivacy,
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(
                                    () => _acceptedPrivacy = value ?? false,
                                  );
                                },
                        ),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              'أوافق على سياسة الخصوصية والشروط. المنصة وسيط، ورسوم الاشتراك غير مستردة.',
                              style: TextStyle(fontSize: 13, height: 1.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      key: const Key('open-provider-privacy'),
                      onPressed: () {
                        Navigator.of(context).pushNamed(ServickRoutes.privacy);
                      },
                      child: const Text('قراءة سياسة الخصوصية'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      key: const Key('provider-login'),
                      onPressed: _isLoading ? null : _loginProvider,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text('تسجيل الدخول'),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'حسابات تجريبية',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'كلمة المرور: $demoProviderPassword. السداد هنا تجريبي ولا يخصم مبلغاً.',
                    style: const TextStyle(
                      color: ServickColors.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final account in model.providers)
                        ActionChip(
                          key: Key('demo-${account.id}'),
                          label: Text(_demoLabel(account, model.now)),
                          onPressed: () {
                            setState(() {
                              _phoneController.text = account.phone;
                              _passwordController.text = account.password;
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _demoLabel(ProviderAccount account, DateTime now) {
    final technician = findTechnician(account.technicianId);
    final name = technician?.name ?? account.phone;
    final status = account.isSubscribedAt(now) ? 'ساري' : 'منتهي';
    return '$name · $status';
  }
}
