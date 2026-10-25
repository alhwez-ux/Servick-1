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
    keywords: ['سطحة', 'سطحات', 'سحب', 'ونش'],
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
  ServicePicture(
    id: 'carwash',
    asset: 'assets/services/carwash.jpg',
    label: 'غسيل سيارات',
    keywords: ['غسيل السيارات', 'غسيل السياره'],
  ),
  ServicePicture(
    id: 'laundry',
    asset: 'assets/services/laundry.jpg',
    label: 'غسيل ملابس',
    keywords: ['ملابس', 'غسيل الملابس'],
  ),
  ServicePicture(
    id: 'yard',
    asset: 'assets/services/yard.jpg',
    label: 'أحواش',
    keywords: ['أحواش', 'احواش'],
  ),
  ServicePicture(
    id: 'cleaning',
    asset: 'assets/services/cleaning.jpg',
    label: 'نظافة',
    keywords: ['نظافة', 'نظافه'],
  ),
  ServicePicture(
    id: 'elegance',
    asset: 'assets/services/elegance.jpg',
    label: 'أناقة',
    keywords: ['أناقة', 'اناقه'],
  ),
  ServicePicture(
    id: 'hospitality',
    asset: 'assets/services/hospitality.jpg',
    label: 'ضيافة',
    keywords: ['ضيافة', 'ضيافه'],
  ),
  ServicePicture(
    id: 'computer',
    asset: 'assets/services/computer.jpg',
    label: 'حاسب',
    keywords: ['حاسب', 'تصوير'],
  ),
  ServicePicture(
    id: 'phone',
    asset: 'assets/services/phone.jpg',
    label: 'جوال',
    keywords: ['جوال'],
  ),
  ServicePicture(
    id: 'aluminum',
    asset: 'assets/services/aluminum.jpg',
    label: 'ألمنيوم',
    keywords: ['ألمنيوم', 'المنيوم'],
  ),
  ServicePicture(
    id: 'construct',
    asset: 'assets/services/construct.jpg',
    label: 'إنشاء',
    keywords: ['إنشاء', 'انشاء'],
  ),
  ServicePicture(
    id: 'finish',
    asset: 'assets/services/finish.jpg',
    label: 'تشطيب',
    keywords: ['تشطيب'],
  ),
  ServicePicture(
    id: 'gypsum',
    asset: 'assets/services/gypsum.jpg',
    label: 'جبس',
    keywords: ['جبس'],
  ),
  ServicePicture(
    id: 'stone',
    asset: 'assets/services/stone.jpg',
    label: 'حجر',
    keywords: ['تكسيات', 'حجر'],
  ),
  ServicePicture(
    id: 'cement',
    asset: 'assets/services/cement.jpg',
    label: 'أسمنت',
    keywords: ['اسمنت', 'أسمنت'],
  ),
  ServicePicture(
    id: 'wood',
    asset: 'assets/services/wood.jpg',
    label: 'خشب',
    keywords: ['خشب', 'بديل الخشب'],
  ),
  ServicePicture(
    id: 'garden',
    asset: 'assets/services/garden.jpg',
    label: 'حدائق',
    keywords: ['حدائق', 'حديقه'],
  ),
  ServicePicture(
    id: 'tent',
    asset: 'assets/services/tent.jpg',
    label: 'خيام',
    keywords: ['خيام', 'خيمه'],
  ),
  ServicePicture(
    id: 'kitchen',
    asset: 'assets/services/kitchen.jpg',
    label: 'مطبخ',
    keywords: ['مطبخ'],
  ),
  ServicePicture(
    id: 'chalet',
    asset: 'assets/services/chalet.jpg',
    label: 'شاليه',
    keywords: ['شاليه', 'استراحات', 'استراحه'],
  ),
  ServicePicture(
    id: 'stay',
    asset: 'assets/services/stay.jpg',
    label: 'إقامة',
    keywords: ['إقامة', 'اقامه', 'مفروشة', 'مفروشه'],
  ),
  ServicePicture(
    id: 'school',
    asset: 'assets/services/school.jpg',
    label: 'نقل مدرسي',
    keywords: ['مدرسي'],
  ),
  ServicePicture(
    id: 'moving',
    asset: 'assets/services/moving.jpg',
    label: 'نقل عفش',
    keywords: ['عفش'],
  ),
  ServicePicture(
    id: 'print',
    asset: 'assets/services/print.jpg',
    label: 'طباعة',
    keywords: ['طباعة', 'طباعه', 'تصميم'],
  ),
  ServicePicture(
    id: 'family',
    asset: 'assets/services/family.jpg',
    label: 'أسر منتجة',
    keywords: ['منتجة', 'منتجه'],
  ),
  ServicePicture(
    id: 'gym',
    asset: 'assets/services/gym.jpg',
    label: 'رياضة',
    keywords: ['رياض'],
  ),
  ServicePicture(
    id: 'tourism',
    asset: 'assets/services/tourism.jpg',
    label: 'سياحة',
    keywords: ['سياح', 'ارشاد', 'إرشاد'],
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
