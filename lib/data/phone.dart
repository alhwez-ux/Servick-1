final _separator = RegExp(r'[\s-]');
final _saudiMobile = RegExp(r'^(05\d{8}|\+9665\d{8}|9665\d{8})$');

String? validateSaudiMobile(String? raw) {
  final compact = (raw ?? '').replaceAll(_separator, '');
  if (!_saudiMobile.hasMatch(compact)) {
    return 'أدخل جوالاً سعودياً يبدأ بـ 05';
  }
  return null;
}

String normalizeSaudiMobile(String raw) {
  var compact = raw.replaceAll(_separator, '');
  if (compact.startsWith('+')) {
    compact = compact.substring(1);
  }
  if (compact.startsWith('966')) {
    compact = '0${compact.substring(3)}';
  }
  return compact;
}
