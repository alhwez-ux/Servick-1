import 'package:flutter/material.dart';

import '../data/privacy_policy.dart';
import '../theme/servick_theme.dart';
import '../widgets/servick_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ServickScaffold(
      title: 'سياسة الخصوصية',
      showCity: false,
      body: ServickFrame(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              privacyPolicyTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              privacyPolicyUpdated,
              style: TextStyle(
                color: ServickColors.amber,
                fontWeight: FontWeight.w700,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              privacyPolicyIntro,
              style: TextStyle(color: ServickColors.muted, height: 1.7),
            ),
            const SizedBox(height: 16),
            for (final section in privacySections) ...[
              Text(
                section.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ServickColors.navy,
                ),
              ),
              const SizedBox(height: 6),
              for (final paragraph in section.paragraphs) ...[
                Text(paragraph, style: const TextStyle(height: 1.7)),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
