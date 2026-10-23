import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/format.dart';

class PhoneLabel extends StatelessWidget {
  const PhoneLabel({super.key, required this.prefix, required this.digits});

  final String prefix;
  final String digits;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: prefix),
          const TextSpan(text: ' '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(formatPhone(digits)),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> copyPhone(BuildContext context, String phone) async {
  await Clipboard.setData(ClipboardData(text: phone));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('تم نسخ ${formatPhone(phone)}')));
}
