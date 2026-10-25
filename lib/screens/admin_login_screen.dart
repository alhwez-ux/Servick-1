import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/admin.dart';
import '../data/format.dart';
import '../routes.dart';
import '../theme/servick_theme.dart';
import '../widgets/account_security.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _passcodeController = TextEditingController();
  var _isLoading = false;

  @override
  void dispose() {
    _passcodeController.dispose();
    super.dispose();
  }

  void _snack(String message, {Color? backgroundColor}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  void _verifyAdminLogin() {
    final enteredPasscode = _passcodeController.text.trim();
    if (enteredPasscode.isEmpty) {
      _snack('الرجاء إدخال الرقم السري الخاص بالمالك');
      return;
    }

    setState(() => _isLoading = true);
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (AppScope.of(context).ownerPasswordMatches(enteredPasscode)) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        AppScope.of(context).unlockAdmin();
        if (!context.mounted) return;
        Navigator.of(context)
            .pushReplacementNamed(ServickRoutes.adminDashboard);
        return;
      }
      _snack(
        'الرقم السري غير صحيح، حاول مرة أخرى',
        backgroundColor: Colors.red,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'دخول مالك التطبيق | رابط',
          style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
        ),
        backgroundColor: ServickColors.navy,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: ServickColors.navy,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 45,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'منطقة الإدارة العليا',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'أدخل الرقم السري الخاص بمالك التطبيق للوصول إلى لوحة التحكم والإحصائيات',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                if (AppScope.of(context).ownerUsesDemoPasscode) ...[
                  const SizedBox(height: 8),
                  Text(
                    'الرقم التجريبي: ${isolateLtr(demoAdminPasscode)}. التحقق داخل الجلسة وليس حماية حقيقية.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ServickColors.muted,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                TextField(
                  key: const Key('admin-passcode'),
                  controller: _passcodeController,
                  obscureText: true,
                  keyboardType: TextInputType.text,
                  maxLength: 32,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  enabled: !_isLoading,
                  style: const TextStyle(
                    fontSize: 20,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    labelText: 'الرقم السري للسيستم',
                    labelStyle: const TextStyle(fontSize: 14),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: ServickColors.navy,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    key: const Key('admin-login'),
                    onPressed: _isLoading ? null : _verifyAdminLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ServickColors.navy,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: ServickColors.navy.withValues(
                        alpha: 0.6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'دخول لوحة التحكم',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                TextButton(
                  key: const Key('forgot-password-owner'),
                  onPressed: _isLoading
                      ? null
                      : () => showPasswordRecovery(context, audience: 'owner'),
                  child: const Text('نسيت كلمة المرور؟'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
