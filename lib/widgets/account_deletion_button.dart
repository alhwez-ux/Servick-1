import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../theme/servick_theme.dart';
import 'confirm_action.dart';

class AccountDeletionButton extends StatelessWidget {
  const AccountDeletionButton({
    super.key,
    required this.audience,
    required this.accountId,
  });

  final String audience;
  final String accountId;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final pending = model.deletionRequestFor(
      audience: audience,
      accountId: accountId,
    );
    if (pending != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'طلب حذف الحساب بانتظار موافقة المالك',
          key: Key('deletion-pending-$accountId'),
          style: const TextStyle(color: ServickColors.waiting, height: 1.5),
        ),
      );
    }
    return TextButton(
      key: Key('request-deletion-$accountId'),
      onPressed: () async {
        final approved = await confirmAction(
          context,
          title: 'طلب حذف الحساب',
          message: 'يصل الطلب إلى المالك، ولا يُحذف الحساب وبياناته إلا بعد موافقته.',
          confirm: 'إرسال الطلب',
        );
        if (!approved || !context.mounted) return;
        final error = AppScope.of(context)
            .requestAccountDeletion(audience: audience, accountId: accountId);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error ?? 'أُرسل طلب حذف الحساب. لا يُحذف إلا بعد موافقة المالك.',
            ),
          ),
        );
      },
      child: const Text('طلب حذف الحساب'),
    );
  }
}
