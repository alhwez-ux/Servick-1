import 'dart:convert';

import 'package:http/http.dart' as http;

const passwordMailUrl = String.fromEnvironment(
  'SERVICK_MAIL',
  defaultValue: 'https://servick1.vercel.app/api/mail',
);

class PasswordMail {
  const PasswordMail({
    required this.to,
    required this.subject,
    required this.text,
  });

  final String to;
  final String subject;
  final String text;
}

Future<bool> postPasswordMail(PasswordMail mail) async {
  try {
    final response = await http
        .post(
          Uri.parse(passwordMailUrl),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'to': mail.to,
            'subject': mail.subject,
            'text': mail.text,
          }),
        )
        .timeout(const Duration(seconds: 8));
    return response.statusCode >= 200 && response.statusCode < 300;
  } catch (_) {
    return false;
  }
}
