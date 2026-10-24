import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/format.dart';
import '../models/desk.dart';
import '../theme/servick_theme.dart';

class ComplimentaryNotice extends StatefulWidget {
  const ComplimentaryNotice({
    super.key,
    required this.audience,
    required this.recipientId,
    this.onPay,
  });

  final String audience;
  final String recipientId;
  final VoidCallback? onPay;

  @override
  State<ComplimentaryNotice> createState() => _ComplimentaryNoticeState();
}

class _ComplimentaryNoticeState extends State<ComplimentaryNotice> {
  var _queued = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_queued) return;
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.of(context).ensureComplimentaryNotice(
        audience: widget.audience,
        recipientId: widget.recipientId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final phase = widget.audience == 'provider'
        ? () {
            final account = model.providerById(widget.recipientId);
            if (account == null) return ComplimentaryPhase.inactive;
            return model.providerComplimentaryPhase(account);
          }()
        : model.clientComplimentaryPhase(widget.recipientId);
    if (phase == ComplimentaryPhase.inactive) return const SizedBox.shrink();

    final end = model.complimentaryEnd(
      forProvider: widget.audience == 'provider',
    );
    final warning = phase == ComplimentaryPhase.warning;
    final ended = phase == ComplimentaryPhase.ended;
    final tone = ended
        ? ServickColors.emergency
        : warning
        ? const Color(0xFFB45309)
        : ServickColors.navy;
    final background = ended
        ? const Color(0xFFFEF2F2)
        : warning
        ? const Color(0xFFFFFBEB)
        : const Color(0xFFEFF6FF);
    final message = ended
        ? complimentaryEndedText
        : warning
        ? complimentaryWarningText
        : 'المدة المجانية سارية حتى ${end == null ? '' : formatSubscriptionDate(end)}.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: tone.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    ended
                        ? Icons.block
                        : warning
                        ? Icons.notification_important_outlined
                        : Icons.card_giftcard_outlined,
                    color: tone,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      key: Key(
                        ended
                            ? 'complimentary-ended'
                            : warning
                            ? 'complimentary-warning'
                            : 'complimentary-open',
                      ),
                      style: const TextStyle(height: 1.55),
                    ),
                  ),
                ],
              ),
              if (widget.onPay != null && (warning || ended))
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    key: const Key('complimentary-pay'),
                    onPressed: widget.onPay,
                    child: const Text('دفع رسوم الاشتراك'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
