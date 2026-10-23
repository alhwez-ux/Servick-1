import '../models/provider.dart';

const annualSubscriptionFee = 100;
const annualSubscriptionDays = 365;
const demoProviderPassword = '123456';

List<ProviderAccount> demoProviders(DateTime now) {
  return [
    ProviderAccount(
      id: 'prov-p-km-1',
      technicianId: 'p-km-1',
      phone: '0554102201',
      password: demoProviderPassword,
      subscriptionStatus: 'active',
      subscriptionExpiry: now.add(const Duration(days: 240)),
    ),
    ProviderAccount(
      id: 'prov-d-ab-1',
      technicianId: 'd-ab-1',
      phone: '0554102206',
      password: demoProviderPassword,
      subscriptionStatus: 'expired',
      subscriptionExpiry: now.subtract(const Duration(days: 15)),
    ),
  ];
}
