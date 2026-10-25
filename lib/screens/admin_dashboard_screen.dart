import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../widgets/account_security.dart';
import '../widgets/confirm_action.dart';
import '../data/format.dart';
import '../models/provider.dart';
import '../routes.dart';
import '../theme/servick_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final pending = model.expiredProviders;
    final wide = MediaQuery.sizeOf(context).width >= 560;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          model.isOwner ? 'لوحة تحكم المالك | رابط' : 'لوحة المشرف | رابط',
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
        ),
        backgroundColor: ServickColors.navy,
        actions: [
          IconButton(
            key: const Key('admin-settings'),
            tooltip: 'اقتراحات التعديل',
            icon: const Icon(Icons.edit_note),
            onPressed: () {
              Navigator.of(context).pushNamed(ServickRoutes.adminReview);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'نظرة عامة على النظام',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'الحسابات والطلبات والخدمات تُحفظ على الويب وتظهر من أي جهاز تدخل منه. لا تُحذف بيانات المستخدم إلا من هنا، أو بعد موافقتك على طلب الحذف. التفعيل لا يخصم مبلغاً.',
                style: TextStyle(
                  color: ServickColors.muted,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              _DashButton(
                buttonKey: const Key('open-admin-review'),
                icon: Icons.manage_search,
                label: 'معاينة التفاصيل والاقتراحات',
                filled: true,
                onPressed: () {
                  Navigator.of(context).pushNamed(ServickRoutes.adminReview);
                },
              ),
              const SizedBox(height: 8),
              _DashButton(
                buttonKey: const Key('open-admin-desk'),
                icon: Icons.tune,
                label: 'الأسعار والمراسلات والفوترة',
                onPressed: () {
                  Navigator.of(context).pushNamed(ServickRoutes.adminDesk);
                },
              ),
              const SizedBox(height: 8),
              _DashButton(
                buttonKey: const Key('open-add-service'),
                icon: Icons.add_circle_outline,
                label: 'إضافة خدمة جديدة',
                filled: true,
                amber: true,
                onPressed: () {
                  Navigator.of(context).pushNamed(ServickRoutes.adminService);
                },
              ),
              const SizedBox(height: 16),
              if (model.isOwner) ...[
                const PasswordChangeCard(audience: 'owner'),
                const SizedBox(height: 8),
                const _SupervisorsCard(),
                const SizedBox(height: 8),
              ],
              const _FreeMonthsCard(),
              const SizedBox(height: 16),
              if (wide)
                Row(
                  children: [
                    Expanded(child: _providersCard(model.providers.length)),
                    const SizedBox(width: 12),
                    Expanded(child: _ordersCard(model.orderCount)),
                  ],
                )
              else ...[
                _providersCard(model.providers.length),
                const SizedBox(height: 12),
                _ordersCard(model.orderCount),
              ],
              const SizedBox(height: 24),
              const _DeletionRequests(),
              const SizedBox(height: 16),
              const _AccountDirectory(),
              const SizedBox(height: 24),
              const Text(
                'طلبات مقدمي الخدمات بانتظار الاعتماد وتفعيل الاشتراك',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              if (pending.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      'لا توجد طلبات انضمام جديدة بانتظار التفعيل',
                      key: Key('admin-empty'),
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                for (final account in pending) ...[
                  _PendingProviderCard(account: account),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _providersCard(int count) {
    return _StatCard(
      title: 'مقدمو الخدمات المسجلون',
      countKey: const Key('stat-providers'),
      count: count,
      icon: Icons.engineering,
      color: ServickColors.navy,
    );
  }

  Widget _ordersCard(int count) {
    return _StatCard(
      title: 'طلبات الصيانة النشطة',
      countKey: const Key('stat-orders'),
      count: count,
      icon: Icons.car_repair,
      color: const Color(0xFF10B981),
    );
  }
}

class _FreeMonthsCard extends StatefulWidget {
  const _FreeMonthsCard();

  @override
  State<_FreeMonthsCard> createState() => _FreeMonthsCardState();
}

class _FreeMonthsCardState extends State<_FreeMonthsCard> {
  final _providerMonths = TextEditingController();
  final _clientMonths = TextEditingController();
  var _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final billing = AppScope.of(context).billing;
    _providerMonths.text = '${billing.providerFreeMonths}';
    _clientMonths.text = '${billing.clientFreeMonths}';
  }

  @override
  void dispose() {
    _providerMonths.dispose();
    _clientMonths.dispose();
    super.dispose();
  }

  void _save() {
    final model = AppScope.of(context);
    final error = model.updateFreeMonths(
      providerRaw: _providerMonths.text,
      clientRaw: _clientMonths.text,
    );
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'تم حفظ المدة المجانية')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final providerEnd = model.complimentaryEnd(forProvider: true);
    final clientEnd = model.complimentaryEnd(forProvider: false);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ServickColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'المدة المجانية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'يحدد المالك عدد الأشهر لمقدم الخدمة وللعميل. قبل نهاية المدة بأسبوع يصل تنبيه بأن خدمات التطبيق ستتوقف بعد 7 أيام إذا لم تُدفع رسوم الاشتراك. من دفع اشتراكه لا يتأثر.',
              style: TextStyle(
                color: ServickColors.muted,
                height: 1.6,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('free-provider-months'),
              controller: _providerMonths,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'المدة المجانية لمقدم الخدمة',
                suffixText: 'شهر',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('free-client-months'),
              controller: _clientMonths,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'المدة المجانية للعميل',
                suffixText: 'شهر',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('save-free-months'),
              onPressed: _save,
              child: const Text('حفظ المدة المجانية'),
            ),
            if (providerEnd != null) ...[
              const SizedBox(height: 10),
              Text(
                'تنتهي مجانية مقدم الخدمة في ${formatSubscriptionDate(providerEnd)}',
                key: const Key('free-provider-end'),
                style: const TextStyle(height: 1.5),
              ),
            ],
            if (clientEnd != null) ...[
              const SizedBox(height: 4),
              Text(
                'تنتهي مجانية العميل في ${formatSubscriptionDate(clientEnd)}',
                key: const Key('free-client-end'),
                style: const TextStyle(height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashButton extends StatelessWidget {
  const _DashButton({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.amber = false,
  });

  final Key buttonKey;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final button = !filled
        ? OutlinedButton(
            key: buttonKey,
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: shape,
            ),
            child: child,
          )
        : FilledButton(
            key: buttonKey,
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: amber ? ServickColors.amber : ServickColors.navy,
              foregroundColor: amber ? ServickColors.navy : Colors.white,
              shape: shape,
            ),
            child: child,
          );
    return SizedBox(width: double.infinity, child: button);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.countKey,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String title;
  final Key countKey;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            key: countKey,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _deleteAccount(
  BuildContext context, {
  required String audience,
  required String accountId,
}) async {
  final approved = await confirmAction(
    context,
    title: 'حذف الحساب',
    message:
        'سيُحذف الحساب وبياناته من كل الأجهزة. لا يمكن التراجع من التطبيق.',
    confirm: 'حذف الحساب',
  );
  if (!approved || !context.mounted) return;
  final error = AppScope.of(context)
      .deleteAccount(audience: audience, accountId: accountId);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(error ?? 'تم حذف الحساب وبياناته')));
}

class _DeletionRequests extends StatelessWidget {
  const _DeletionRequests();

  @override
  Widget build(BuildContext context) {
    final pending = AppScope.of(context).pendingDeletions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'طلبات حذف الحسابات',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'لا يُحذف الحساب إلا بعد موافقتك، أو مباشرة من زر الحذف.',
          style: TextStyle(color: ServickColors.muted, height: 1.5),
        ),
        const SizedBox(height: 8),
        if (pending.isEmpty)
          const Text(
            'لا توجد طلبات حذف بانتظار الموافقة.',
            key: Key('deletions-empty'),
            style: TextStyle(color: ServickColors.muted),
          )
        else
          for (final request in pending)
            Card(
              key: Key('deletion-request-${request.id}'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.accountName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${request.audience == 'provider' ? 'مقدم خدمة' : 'عميل'} · ${formatPhone(request.phone)}',
                      style: const TextStyle(
                        color: ServickColors.muted,
                        height: 1.4,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          key: Key('reject-deletion-${request.id}'),
                          onPressed: () {
                            AppScope.of(context)
                                .rejectAccountDeletion(request.id);
                          },
                          child: const Text('رفض'),
                        ),
                        FilledButton(
                          key: Key('approve-deletion-${request.id}'),
                          onPressed: () {
                            AppScope.of(context)
                                .approveAccountDeletion(request.id);
                          },
                          child: const Text('موافقة'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _SupervisorsCard extends StatefulWidget {
  const _SupervisorsCard();

  @override
  State<_SupervisorsCard> createState() => _SupervisorsCardState();
}

class _SupervisorsCardState extends State<_SupervisorsCard> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

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

  void _add() {
    final error = AppScope.of(context).addSupervisor(
      name: _name.text,
      phone: _phone.text,
      password: _password.text,
    );
    if (error != null) {
      _snack(error);
      return;
    }
    _name.clear();
    _phone.clear();
    _password.clear();
    _snack('تمت إضافة المشرف');
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'إضافة مشرفين',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'المشرف يدخل من بوابة الدخول الرئيسية برقم جواله وكلمة مروره، ويصل إلى لوحة التحكم.',
              style: TextStyle(color: ServickColors.muted, height: 1.5),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('supervisor-name'),
              controller: _name,
              decoration: const InputDecoration(labelText: 'اسم المشرف'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('supervisor-phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'جوال المشرف'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('supervisor-password'),
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('add-supervisor'),
              onPressed: _add,
              child: const Text('إضافة المشرف'),
            ),
            const SizedBox(height: 8),
            if (model.supervisors.isEmpty)
              const Text(
                'لا يوجد مشرفون بعد.',
                key: Key('supervisors-empty'),
                style: TextStyle(color: ServickColors.muted, height: 1.5),
              )
            else
              for (final supervisor in model.supervisors)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(supervisor.name),
                  subtitle: Text(formatPhone(supervisor.phone)),
                  trailing: IconButton(
                    key: Key('supervisor-delete-${supervisor.id}'),
                    tooltip: 'حذف المشرف',
                    onPressed: () {
                      final error = model.removeSupervisor(supervisor.id);
                      if (error != null) _snack(error);
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _AccountDirectory extends StatelessWidget {
  const _AccountDirectory();

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final active = model.providers.where(
      (account) => account.subscriptionStatus == 'active',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الحسابات المحفوظة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (model.clientAccounts.isEmpty && active.isEmpty)
          const Text(
            'لا توجد حسابات بعد. تظهر هنا بعد تسجيل العملاء ومقدمي الخدمات.',
            key: Key('accounts-empty'),
            style: TextStyle(color: ServickColors.muted, height: 1.5),
          ),
        for (final client in model.clientAccounts)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(client.name),
            subtitle: Text('عميل · ${formatPhone(client.phone)}'),
            trailing: IconButton(
              key: Key('owner-delete-client-${client.id}'),
              tooltip: 'حذف الحساب',
              onPressed: () => _deleteAccount(
                context,
                audience: 'client',
                accountId: client.id,
              ),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        for (final account in active)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              model.technicianById(account.technicianId)?.name ?? account.phone,
            ),
            subtitle: Text('مقدم خدمة · ${formatPhone(account.phone)}'),
            trailing: IconButton(
              key: Key('owner-delete-provider-${account.id}'),
              tooltip: 'حذف الحساب',
              onPressed: () => _deleteAccount(
                context,
                audience: 'provider',
                accountId: account.id,
              ),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
      ],
    );
  }
}

class _PendingProviderCard extends StatelessWidget {
  const _PendingProviderCard({required this.account});

  final ProviderAccount account;

  @override
  Widget build(BuildContext context) {
    final technician = AppScope.of(context)
        .technicianById(account.technicianId);
    final name = technician?.name ?? 'مقدم خدمة بدون اسم';
    final city = technician?.city ?? 'خميس مشيط';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFFEF3C7),
                  child: Icon(Icons.person_outline, color: Colors.amber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'الجوال: ${formatPhone(account.phone)} | المدينة: $city',
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton(
              key: Key('activate-provider-${account.id}'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () => _activate(context, account.id),
              child: const Text('تفعيل الحساب', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: Key('owner-delete-provider-${account.id}'),
              onPressed: () => _deleteAccount(
                context,
                audience: 'provider',
                accountId: account.id,
              ),
              child: const Text('حذف الحساب'),
            ),
          ],
        ),
      ),
    );
  }

  void _activate(BuildContext context, String providerId) {
    final error = AppScope.of(context).activateProviderSubscription(providerId);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            error == null
                ? 'تم تفعيل اشتراك مقدم الخدمة بنجاح!'
                : 'خطأ في التفعيل: $error',
          ),
        ),
      );
  }
}
