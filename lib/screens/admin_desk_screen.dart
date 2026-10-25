import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../data/catalog.dart';
import '../data/client_plans.dart';
import '../data/format.dart';
import '../data/phone.dart';
import '../data/whatsapp.dart';
import '../models/desk.dart';
import '../models/models.dart';
import '../theme/servick_theme.dart';
import '../widgets/common.dart';
import '../widgets/servick_scaffold.dart';

class AdminDeskScreen extends StatefulWidget {
  const AdminDeskScreen({super.key});

  @override
  State<AdminDeskScreen> createState() => _AdminDeskScreenState();
}

class _AdminDeskScreenState extends State<AdminDeskScreen> {
  final _prices = <String, TextEditingController>{};
  final _planPrices = <String, TextEditingController>{};
  final _providerFee = TextEditingController();
  final _prefix = TextEditingController();
  final _nextNumber = TextEditingController();
  final _note = TextEditingController();
  final _messageBody = TextEditingController();
  final _whatsAppBody = TextEditingController();
  final _whatsAppIds = <String>{};
  var _ready = false;
  var _invoicesEnabled = true;
  var _audience = 'provider';
  var _whatsAppAudience = 'provider';
  String? _recipientId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final model = AppScope.of(context);
    for (final technician in AppScope.of(context).technicians) {
      _prices[technician.id] = TextEditingController(
        text: '${model.startingPriceOf(technician)}',
      );
    }
    for (final plan in clientPlans.where((plan) => !plan.adminOnly)) {
      _planPrices[plan.id] = TextEditingController(
        text: '${model.planPriceOf(plan.id)}',
      );
    }
    _providerFee.text = '${model.providerAnnualFee}';
    _prefix.text = model.billing.invoicePrefix;
    _nextNumber.text = '${model.billing.nextNumber}';
    _note.text = model.billing.note;
    _invoicesEnabled = model.billing.invoicesEnabled;
    final recipients = model.deskRecipients(_audience);
    _recipientId = recipients.isEmpty ? null : recipients.first.id;
  }

  @override
  void dispose() {
    for (final controller in _prices.values) {
      controller.dispose();
    }
    for (final controller in _planPrices.values) {
      controller.dispose();
    }
    _providerFee.dispose();
    _prefix.dispose();
    _nextNumber.dispose();
    _note.dispose();
    _messageBody.dispose();
    _whatsAppBody.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final recipients = model.deskRecipients(_audience);

    return Scaffold(
      appBar: AppBar(title: const Text('الأسعار والمراسلات والفوترة')),
      body: ServickFrame(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'التعديل يُحفظ على الويب ويظهر من أي جهاز. الفوترة محاكاة ولا تخصم مبلغاً.',
                style: TextStyle(color: ServickColors.muted, height: 1.6),
              ),
              const SizedBox(height: 20),
              const SectionTitle('تعديل الأسعار'),
              const SizedBox(height: 6),
              const Text(
                'سعر بداية الزيارة لكل فني. السعر النهائي يبقى بعد المعاينة.',
                style: TextStyle(color: ServickColors.muted, height: 1.5),
              ),
              const SizedBox(height: 12),
              for (final city in cities) ...[
                Text(
                  city,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ServickColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                for (final technician in model.technicians)
                  if (technician.city == city) ...[
                    _PriceRow(
                      technician: technician,
                      controller: _prices[technician.id]!,
                      onSave: () => _savePrice(technician.id),
                    ),
                    const SizedBox(height: 8),
                  ],
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
              const SectionTitle('مراسلة مزودي الخدمة والعملاء'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    key: const Key('message-audience-provider'),
                    label: const Text('مزودو الخدمة'),
                    selected: _audience == 'provider',
                    onSelected: (_) => _selectAudience('provider'),
                  ),
                  ChoiceChip(
                    key: const Key('message-audience-client'),
                    label: const Text('العملاء'),
                    selected: _audience == 'client',
                    onSelected: (_) => _selectAudience('client'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final recipient in recipients)
                    ChoiceChip(
                      key: Key('message-recipient-${recipient.id}'),
                      label: Text(recipient.name),
                      selected: _recipientId == recipient.id,
                      onSelected: (_) {
                        setState(() => _recipientId = recipient.id);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('message-body'),
                controller: _messageBody,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'نص الرسالة التي تصل إلى لوحة المستلم',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const Key('send-message'),
                onPressed: _send,
                child: const Text('إرسال الرسالة'),
              ),
              const SizedBox(height: 12),
              if (model.deskMessages.isEmpty)
                const Text(
                  'لا توجد رسائل محفوظة.',
                  key: Key('messages-empty'),
                  style: TextStyle(color: ServickColors.muted, height: 1.5),
                )
              else
                for (final message in model.deskMessages) ...[
                  _MessageCard(message: message),
                  const SizedBox(height: 8),
                ],
              const SizedBox(height: 20),
              const SectionTitle('واتساب الأعمال'),
              const SizedBox(height: 6),
              Text(
                'تُفتح المحادثة من واتساب الأعمال ${isolateLtr(whatsAppBusinessDisplay)} مع كل مقدم خدمة أو عميل تحدده.',
                style: const TextStyle(color: ServickColors.muted, height: 1.5),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    key: const Key('whatsapp-audience-provider'),
                    label: const Text('مقدمو الخدمات'),
                    selected: _whatsAppAudience == 'provider',
                    onSelected: (_) => _selectWhatsAppAudience('provider'),
                  ),
                  ChoiceChip(
                    key: const Key('whatsapp-audience-client'),
                    label: const Text('العملاء'),
                    selected: _whatsAppAudience == 'client',
                    onSelected: (_) => _selectWhatsAppAudience('client'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _WhatsAppList(
                recipients: _whatsAppTargets(model),
                selected: _whatsAppIds,
                onToggleAll: _toggleWhatsAppAll,
                onToggle: _toggleWhatsApp,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('whatsapp-body'),
                controller: _whatsAppBody,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'نص رسالة واتساب الأعمال',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('send-whatsapp'),
                onPressed: _sendWhatsApp,
                icon: const Icon(Icons.chat),
                label: const Text('مراسلة عبر واتساب'),
              ),
              const SizedBox(height: 20),
              const SectionTitle('نظام الفوترة'),
              const SizedBox(height: 6),
              const Text(
                'رسوم الاشتراك وشكل الفاتورة التجريبية. التفعيل والسداد لا يخصمان مبلغاً حقيقياً.',
                style: TextStyle(color: ServickColors.muted, height: 1.5),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('billing-provider-fee'),
                controller: _providerFee,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'رسوم اشتراك الحرفي السنوي',
                  suffixText: 'ر.س',
                ),
              ),
              const SizedBox(height: 10),
              for (final plan in clientPlans.where(
                (plan) => !plan.adminOnly,
              )) ...[
                TextField(
                  key: Key('billing-plan-${plan.id}'),
                  controller: _planPrices[plan.id],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: plan.title,
                    suffixText: 'ر.س',
                  ),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                key: const Key('billing-prefix'),
                controller: _prefix,
                decoration: const InputDecoration(
                  labelText: 'بادئة رقم الفاتورة',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('billing-next'),
                controller: _nextNumber,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'رقم الفاتورة التالية',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('billing-note'),
                controller: _note,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة أسفل الفاتورة',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                key: const Key('billing-enabled'),
                contentPadding: EdgeInsets.zero,
                title: const Text('إصدار فاتورة تجريبية عند الاشتراك'),
                value: _invoicesEnabled,
                onChanged: (value) => setState(() => _invoicesEnabled = value),
              ),
              FilledButton(
                key: const Key('save-billing'),
                onPressed: _saveBilling,
                child: const Text('حفظ إعدادات الفوترة'),
              ),
              const SizedBox(height: 12),
              _InvoicePreview(model: model),
              const SizedBox(height: 12),
              if (model.invoices.isEmpty)
                const Text(
                  'لا توجد فواتير بعد.',
                  key: Key('invoices-empty'),
                  style: TextStyle(color: ServickColors.muted, height: 1.5),
                )
              else
                for (final invoice in model.invoices) ...[
                  _InvoiceCard(invoice: invoice, note: model.billing.note),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ),
    );
  }

  void _selectAudience(String audience) {
    final recipients = AppScope.of(context).deskRecipients(audience);
    setState(() {
      _audience = audience;
      _recipientId = recipients.isEmpty ? null : recipients.first.id;
    });
  }

  void _snack(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _savePrice(String technicianId) {
    final error = AppScope.of(context).updateStartingPrice(
      technicianId: technicianId,
      raw: _prices[technicianId]?.text ?? '',
    );
    _snack(error ?? 'تم تحديث سعر البداية');
  }

  void _send() {
    final recipientId = _recipientId;
    if (recipientId == null) {
      _snack('اختر مستلماً من القائمة');
      return;
    }
    final error = AppScope.of(context).sendDeskMessage(
      audience: _audience,
      recipientId: recipientId,
      body: _messageBody.text,
    );
    if (error == null) _messageBody.clear();
    _snack(error ?? 'تم إرسال الرسالة');
  }

  List<DeskRecipient> _whatsAppTargets(AppModel model) {
    return [
      for (final recipient in model.deskRecipients(_whatsAppAudience))
        if (validateSaudiMobile(recipient.detail) == null) recipient,
    ];
  }

  void _selectWhatsAppAudience(String audience) {
    setState(() {
      _whatsAppAudience = audience;
      _whatsAppIds.clear();
    });
  }

  void _toggleWhatsAppAll(List<DeskRecipient> recipients, bool? value) {
    setState(() {
      _whatsAppIds.clear();
      if (value ?? false) {
        _whatsAppIds.addAll(recipients.map((recipient) => recipient.id));
      }
    });
  }

  void _toggleWhatsApp(String id, bool? value) {
    setState(() {
      if (value ?? false) {
        _whatsAppIds.add(id);
      } else {
        _whatsAppIds.remove(id);
      }
    });
  }

  void _sendWhatsApp() {
    final text = _whatsAppBody.text.trim();
    if (text.isEmpty) {
      _snack('اكتب نص الرسالة');
      return;
    }
    final chosen = _whatsAppTargets(AppScope.of(context))
        .where((recipient) => _whatsAppIds.contains(recipient.id));
    var opened = 0;
    for (final recipient in chosen) {
      if (whatsAppChatUrl(recipient.detail, text) == null) continue;
      openWhatsAppChat(recipient.detail, text);
      opened += 1;
    }
    if (opened == 0) {
      _snack('اختر مستلماً واحداً على الأقل');
      return;
    }
    _snack('فُتحت $opened محادثة على واتساب الأعمال $whatsAppBusinessDisplay');
  }

  void _saveBilling() {
    final error = AppScope.of(context).updateBilling(
      providerFeeRaw: _providerFee.text,
      planPriceRaws: {
        for (final entry in _planPrices.entries) entry.key: entry.value.text,
      },
      prefix: _prefix.text,
      nextNumberRaw: _nextNumber.text,
      note: _note.text,
      invoicesEnabled: _invoicesEnabled,
    );
    _snack(error ?? 'تم حفظ إعدادات الفوترة');
  }
}

class _WhatsAppList extends StatelessWidget {
  const _WhatsAppList({
    required this.recipients,
    required this.selected,
    required this.onToggleAll,
    required this.onToggle,
  });

  final List<DeskRecipient> recipients;
  final Set<String> selected;
  final void Function(List<DeskRecipient> recipients, bool? value) onToggleAll;
  final void Function(String id, bool? value) onToggle;

  @override
  Widget build(BuildContext context) {
    if (recipients.isEmpty) {
      return const Text(
        'لا يوجد رقم جوال سعودي في هذه القائمة.',
        key: Key('whatsapp-empty'),
        style: TextStyle(color: ServickColors.muted, height: 1.5),
      );
    }
    final allSelected = recipients.every(
      (recipient) => selected.contains(recipient.id),
    );
    return Column(
      children: [
        CheckboxListTile(
          key: const Key('whatsapp-all'),
          contentPadding: EdgeInsets.zero,
          value: allSelected,
          title: const Text('تحديد الكل'),
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (value) => onToggleAll(recipients, value),
        ),
        for (final recipient in recipients)
          CheckboxListTile(
            key: Key('whatsapp-target-${recipient.id}'),
            contentPadding: EdgeInsets.zero,
            value: selected.contains(recipient.id),
            title: Text(recipient.name),
            subtitle: Text(isolateLtr(recipient.detail)),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (value) => onToggle(recipient.id, value),
          ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.technician,
    required this.controller,
    required this.onSave,
  });

  final Technician technician;
  final TextEditingController controller;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final category = categoryById(technician.categoryId);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ServickColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    technician.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    category.title,
                    style: const TextStyle(
                      color: ServickColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 88,
              child: TextField(
                key: Key('price-field-${technician.id}'),
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  isDense: true,
                  suffixText: 'ر.س',
                ),
              ),
            ),
            IconButton(
              key: Key('save-price-${technician.id}'),
              tooltip: 'حفظ السعر',
              onPressed: onSave,
              icon: const Icon(Icons.check_circle_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final DeskMessage message;

  @override
  Widget build(BuildContext context) {
    final audience = message.audience == 'provider' ? 'مزود' : 'عميل';
    return Container(
      key: Key('desk-message-${message.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ServickColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$audience · ${message.recipientName} · ${formatRiyadh(message.createdAt)}',
            style: const TextStyle(
              color: ServickColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(message.body, style: const TextStyle(height: 1.5)),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: Key('delete-message-${message.id}'),
              onPressed: () {
                AppScope.of(context).removeDeskMessage(message.id);
              },
              child: const Text('حذف الرسالة'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicePreview extends StatelessWidget {
  const _InvoicePreview({required this.model});

  final AppModel model;

  @override
  Widget build(BuildContext context) {
    final billing = model.billing;
    final number = '${billing.invoicePrefix}-${billing.nextNumber}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ServickColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'شكل الفاتورة التالية',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text('الرقم ${isolateLtr(number)}'),
          Text(
            'رسوم الحرفي السنوية ${isolateLtr('${billing.providerAnnualFee}')} ر.س',
          ),
          Text(billing.note, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, required this.note});

  final ServickInvoice invoice;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('invoice-${invoice.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ServickColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${isolateLtr(invoice.number)} · ${invoice.partyName}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text('${invoice.title} · ${isolateLtr('${invoice.amount}')} ر.س'),
          Text(
            '${formatRiyadh(invoice.createdAt)} · $note',
            style: const TextStyle(
              color: ServickColors.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
