import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/format.dart';
import '../theme/servick_theme.dart';

class DeskInbox extends StatelessWidget {
  const DeskInbox({
    super.key,
    required this.audience,
    required this.recipientId,
    this.title = 'رسائل إدارة رابط',
  });

  final String audience;
  final String recipientId;
  final String title;

  @override
  Widget build(BuildContext context) {
    final messages = AppScope.of(context)
        .messagesFor(audience: audience, recipientId: recipientId);
    if (messages.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: const Color(0xFFFFFBEB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFDE68A)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: ServickColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              for (final message in messages) ...[
                Text(
                  formatRiyadh(message.createdAt),
                  style: const TextStyle(
                    color: ServickColors.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(message.body, style: const TextStyle(height: 1.5)),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
