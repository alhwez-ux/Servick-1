const complimentaryWarningDays = 7;
const freeMonthDays = 30;

const complimentaryWarningText =
    'خدمات التطبيق ستتوقف بعد 7 أيام في حال عدم دفع رسوم الاشتراك.';

const complimentaryEndedText =
    'انتهت المدة المجانية. توقفت خدمات التطبيق حتى دفع رسوم الاشتراك.';

enum ComplimentaryPhase { inactive, open, warning, ended }

class BillingConfig {
  const BillingConfig({
    required this.providerAnnualFee,
    required this.planPrices,
    required this.invoicePrefix,
    required this.nextNumber,
    required this.note,
    required this.invoicesEnabled,
    this.providerFreeMonths = 0,
    this.clientFreeMonths = 0,
    this.providerFreeAnchor,
    this.clientFreeAnchor,
  });

  final int providerAnnualFee;
  final Map<String, int> planPrices;
  final String invoicePrefix;
  final int nextNumber;
  final String note;
  final bool invoicesEnabled;
  final int providerFreeMonths;
  final int clientFreeMonths;
  final DateTime? providerFreeAnchor;
  final DateTime? clientFreeAnchor;

  BillingConfig copyWith({
    int? providerAnnualFee,
    Map<String, int>? planPrices,
    String? invoicePrefix,
    int? nextNumber,
    String? note,
    bool? invoicesEnabled,
    int? providerFreeMonths,
    int? clientFreeMonths,
    DateTime? providerFreeAnchor,
    DateTime? clientFreeAnchor,
  }) {
    return BillingConfig(
      providerAnnualFee: providerAnnualFee ?? this.providerAnnualFee,
      planPrices: planPrices ?? this.planPrices,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      nextNumber: nextNumber ?? this.nextNumber,
      note: note ?? this.note,
      invoicesEnabled: invoicesEnabled ?? this.invoicesEnabled,
      providerFreeMonths: providerFreeMonths ?? this.providerFreeMonths,
      clientFreeMonths: clientFreeMonths ?? this.clientFreeMonths,
      providerFreeAnchor: providerFreeAnchor ?? this.providerFreeAnchor,
      clientFreeAnchor: clientFreeAnchor ?? this.clientFreeAnchor,
    );
  }
}

class DeskRecipient {
  const DeskRecipient({
    required this.id,
    required this.audience,
    required this.name,
    required this.detail,
  });

  final String id;
  final String audience;
  final String name;
  final String detail;
}

class DeskMessage {
  const DeskMessage({
    required this.id,
    required this.audience,
    required this.recipientId,
    required this.recipientName,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String audience;
  final String recipientId;
  final String recipientName;
  final String body;
  final DateTime createdAt;
}

class ServickInvoice {
  const ServickInvoice({
    required this.id,
    required this.number,
    required this.partyName,
    required this.title,
    required this.amount,
    required this.createdAt,
  });

  final String id;
  final String number;
  final String partyName;
  final String title;
  final int amount;
  final DateTime createdAt;
}
