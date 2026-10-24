const serviceSubtitleMaxLength = 80;

class ServicePicture {
  const ServicePicture({
    required this.id,
    required this.asset,
    required this.label,
    this.keywords = const [],
  });

  final String id;
  final String asset;
  final String label;
  final List<String> keywords;
}

const servicePictures = <ServicePicture>[
  ServicePicture(
    id: 'general',
    asset: 'assets/services/general.jpg',
    label: 'ورشة',
  ),
  ServicePicture(
    id: 'ac',
    asset: 'assets/services/ac.jpg',
    label: 'تكييف',
    keywords: ['مكيف', 'تكييف', 'تبريد'],
  ),
  ServicePicture(
    id: 'tire',
    asset: 'assets/services/tire.jpg',
    label: 'إطارات',
    keywords: ['إطار', 'اطار', 'كفر', 'بنشر', 'إطارات'],
  ),
  ServicePicture(
    id: 'oil',
    asset: 'assets/services/oil.jpg',
    label: 'زيت',
    keywords: ['زيت', 'تشحيم'],
  ),
  ServicePicture(
    id: 'brake',
    asset: 'assets/services/brake.jpg',
    label: 'فرامل',
    keywords: ['فرامل', 'فحمات', 'بريك'],
  ),
  ServicePicture(
    id: 'battery',
    asset: 'assets/services/battery.jpg',
    label: 'بطارية',
    keywords: ['بطارية', 'دينمو'],
  ),
  ServicePicture(
    id: 'tow',
    asset: 'assets/services/tow.jpg',
    label: 'سطحة',
    keywords: ['سطحة', 'سحب', 'ونش'],
  ),
  ServicePicture(
    id: 'paint',
    asset: 'assets/services/paint.jpg',
    label: 'سمكرة',
    keywords: ['سمكرة', 'سمكره', 'دهان', 'بوية', 'رش'],
  ),
  ServicePicture(
    id: 'glass',
    asset: 'assets/services/glass.jpg',
    label: 'زجاج',
    keywords: ['زجاج'],
  ),
  ServicePicture(
    id: 'plumb',
    asset: 'assets/services/plumb.jpg',
    label: 'سباكة',
    keywords: ['سباكة', 'سباك', 'مواسير', 'تسريب', 'صحي'],
  ),
  ServicePicture(
    id: 'keys',
    asset: 'assets/services/keys.jpg',
    label: 'مفاتيح',
    keywords: ['مفتاح', 'ريموت'],
  ),
  ServicePicture(
    id: 'wash',
    asset: 'assets/services/wash.jpg',
    label: 'غسيل',
    keywords: ['غسيل', 'تلميع', 'مغسلة'],
  ),
  ServicePicture(
    id: 'weld',
    asset: 'assets/services/weld.jpg',
    label: 'لحام',
    keywords: ['لحام', 'حداد', 'حدادة'],
  ),
  ServicePicture(
    id: 'light',
    asset: 'assets/services/light.jpg',
    label: 'إضاءة',
    keywords: ['إضاءة', 'لمبة', 'كشاف', 'أنوار'],
  ),
];

ServicePicture servicePictureById(String id) {
  for (final picture in servicePictures) {
    if (picture.id == id) return picture;
  }
  return servicePictures.first;
}

String foldArabic(String value) {
  return value
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ـ', '');
}

ServicePicture pictureForTitle(String title) {
  final folded = foldArabic(title);
  ServicePicture? match;
  var longest = 0;
  for (final picture in servicePictures) {
    for (final keyword in picture.keywords) {
      final needle = foldArabic(keyword);
      if (needle.isEmpty || !folded.contains(needle)) continue;
      if (needle.length > longest) {
        match = picture;
        longest = needle.length;
      }
    }
  }
  return match ?? servicePictures.first;
}
