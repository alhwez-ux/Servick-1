import '../models/order.dart';

List<ServiceOrder> demoOrders(DateTime now) {
  return [
    ServiceOrder(
      id: 'ord-km-1',
      clientName: 'أبو محمد',
      serviceTitle: 'ميكانيكي بنزين',
      notes: 'صوت في المكينة عند التشغيل قرب طريق الملك فهد',
      city: 'خميس مشيط',
      createdAt: now.subtract(const Duration(minutes: 12)),
      status: 'pending',
    ),
    ServiceOrder(
      id: 'ord-km-2',
      clientName: 'أم سارة',
      serviceTitle: 'كهربائي سيارات',
      notes: 'البطارية لا تدير السيارة في حي النخيل',
      city: 'خميس مشيط',
      createdAt: now.subtract(const Duration(minutes: 28)),
      status: 'pending',
    ),
    ServiceOrder(
      id: 'ord-ab-1',
      clientName: 'أبو فيصل',
      serviceTitle: 'ميكانيكي ديزل',
      notes: 'دخان أبيض عند التشغيل في وسط أبها',
      city: 'أبها',
      createdAt: now.subtract(const Duration(minutes: 20)),
      status: 'pending',
    ),
    ServiceOrder(
      id: 'ord-ar-1',
      clientName: 'أبو ناصر',
      serviceTitle: 'كهربائي منازل',
      notes: 'القاطع الرئيسي يفصل في أحد رفيدة',
      city: 'أحد رفيدة',
      createdAt: now.subtract(const Duration(minutes: 35)),
      status: 'pending',
    ),
  ];
}
