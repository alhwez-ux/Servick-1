import 'phone.dart';
import 'external_url.dart';

const whatsAppBusinessDisplay = '0555748375';

String? whatsAppChatUrl(String phone, String text) {
  if (validateSaudiMobile(phone) != null) return null;
  final local = normalizeSaudiMobile(phone);
  final international = '966${local.substring(1)}';
  return 'https://wa.me/$international?text=${Uri.encodeComponent(text.trim())}';
}

void openWhatsAppChat(String phone, String text) {
  final url = whatsAppChatUrl(phone, text);
  if (url == null) return;
  openExternalUrl(url);
}
