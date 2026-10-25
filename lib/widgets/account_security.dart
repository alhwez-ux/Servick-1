import 'package:flutter/material.dart';

import '../app_scope.dart';

class PasswordChangeCard extends StatefulWidget {
  const PasswordChangeCard({
    super.key,
    required this.audience,
    this.accountId = '',
  });

  final String audience;
  final String accountId;

  @override
  State<PasswordChangeCard> createState() => _PasswordChangeCardState();
}

class _PasswordChangeCardState extends State<PasswordChangeCard> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _email = TextEditingController();
  var _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final model = AppScope.of(context);
    _email.text = switch (widget.audience) {
      'owner' => model.ownerEmail,
      'provider' => model.providerSession?.email ?? '',
      _ => model.clientSession?.email ?? '',
    };
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() {
    final model = AppScope.of(context);
    final error = switch (widget.audience) {
      'owner' => model.changeOwnerPassword(
        current: _current.text,
        next: _next.text,
        email: _email.text,
      ),
      'provider' => model.changeProviderPassword(
        providerId: widget.accountId,
        current: _current.text,
        next: _next.text,
        email: _email.text,
      ),
      _ => model.changeClientPassword(
        clientId: widget.accountId,
        current: _current.text,
        next: _next.text,
        email: _email.text,
      ),
    };
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'تم حفظ كلمة المرور والبريد')),
    );
    if (error == null) {
      _current.clear();
      _next.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefix = widget.audience;
    return ExpansionTile(
      key: Key('password-panel-$prefix'),
      tilePadding: EdgeInsets.zero,
      title: const Text(
        'كلمة المرور والبريد',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      children: [
        TextField(
          key: Key('password-email-$prefix'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            labelText: 'البريد الإلكتروني لاسترجاع كلمة المرور',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: Key('password-current-$prefix'),
          controller: _current,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'كلمة المرور الحالية'),
        ),
        const SizedBox(height: 8),
        TextField(
          key: Key('password-next-$prefix'),
          controller: _next,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'كلمة المرور الجديدة',
            helperText: 'ستة أحرف على الأقل',
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton(
            key: Key('save-password-$prefix'),
            onPressed: _save,
            child: const Text('حفظ كلمة المرور'),
          ),
        ),
      ],
    );
  }
}

Future<void> showPasswordRecovery(
  BuildContext context, {
  required String audience,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return _RecoveryDialog(audience: audience);
    },
  );
}

class _RecoveryDialog extends StatefulWidget {
  const _RecoveryDialog({required this.audience});

  final String audience;

  @override
  State<_RecoveryDialog> createState() => _RecoveryDialogState();
}

class _RecoveryDialogState extends State<_RecoveryDialog> {
  final _email = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final result = await AppScope.of(context)
        .resetPasswordByEmail(audience: widget.audience, email: _email.text);
    if (!mounted) return;
    final error = result.error;
    var message =
        'تعذر إرسال البريد الآن. كلمة المرور المؤقتة: ${result.temporary}';
    if (error != null) {
      message = error;
    } else if (result.mailed) {
      message = 'أُرسلت كلمة مرور مؤقتة إلى بريدك. غيّرها بعد الدخول.';
    }
    Navigator.of(context).pop();
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('استرجاع كلمة المرور'),
      content: TextField(
        key: const Key('recovery-email'),
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        textDirection: TextDirection.ltr,
        decoration: const InputDecoration(
          labelText: 'البريد المسجّل في الحساب',
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          key: const Key('send-recovery'),
          onPressed: _busy ? null : _send,
          child: const Text('إرسال'),
        ),
      ],
    );
  }
}
