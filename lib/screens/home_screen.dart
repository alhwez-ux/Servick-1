import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/catalog.dart';
import '../data/client_plans.dart';
import '../data/format.dart';
import '../data/matching.dart';
import '../models/client_subscription.dart';
import '../models/models.dart';
import '../models/order.dart';
import '../routes.dart';
import '../theme/servick_theme.dart';
import '../widgets/category_card.dart';
import '../widgets/complimentary_notice.dart';
import '../widgets/desk_inbox.dart';
import '../widgets/common.dart';
import '../widgets/hood_open_scene.dart';
import '../widgets/servick_scaffold.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final openNow = availableInCity(model.city);
    final columns = MediaQuery.sizeOf(context).width >= 900 ? 3 : 2;

    return ServickScaffold(
      brand: true,
      body: ServickFrame(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HoodOpenScene(
                onTap: () {
                  Navigator.of(context).pushNamed(ServickRoutes.emergency);
                },
              ),
              const SizedBox(height: 12),
              _EmergencyBanner(city: model.city),
              const SizedBox(height: 16),
              ComplimentaryNotice(
                audience: 'client',
                recipientId: demoClientId,
                onPay: () {
                  Navigator.of(context).pushNamed(
                    ServickRoutes.clientSubscription,
                    arguments: const ClientSubscriptionArgs(
                      clientId: demoClientId,
                      isAdmin: false,
                    ),
                  );
                },
              ),
              DeskInbox(audience: 'client', recipientId: demoClientId),
              const SizedBox(height: 6),
              if (openNow.isNotEmpty) ...[
                const SectionTitle('متاحون الآن'),
                const SizedBox(height: 10),
                _AvailableStrip(technicians: openNow),
                const SizedBox(height: 22),
              ],
              const SectionTitle('اختر نوع الخدمة المطلوبة:'),
              const SizedBox(height: 12),
              _CategoryGrid(
                city: model.city,
                columns: columns,
                categories: model.serviceCategories,
              ),
              const SizedBox(height: 22),
              const DemoNote(),
              const SizedBox(height: 4),
              Center(
                child: TextButton.icon(
                  key: const Key('open-privacy'),
                  onPressed: () {
                    Navigator.of(context).pushNamed(ServickRoutes.privacy);
                  },
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: const Text('سياسة الخصوصية'),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: FilledButton.icon(
                  key: const Key('open-client-order'),
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      ServickRoutes.clientOrder,
                      arguments: const ClientOrderArgs(
                        clientId: demoClientId,
                        clientName: demoClientName,
                      ),
                    );
                  },
                  icon: const Icon(Icons.home_repair_service_outlined),
                  label: const Text('طلب خدمة صيانة عاجلة'),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton.icon(
                  key: const Key('open-client-plans'),
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      ServickRoutes.clientSubscription,
                      arguments: const ClientSubscriptionArgs(
                        clientId: demoClientId,
                        isAdmin: false,
                      ),
                    );
                  },
                  icon: const Icon(Icons.card_membership),
                  label: const Text('باقات اشتراك العملاء'),
                ),
              ),
              Center(
                child: TextButton.icon(
                  key: const Key('open-admin-login'),
                  onPressed: () {
                    Navigator.of(context).pushNamed(ServickRoutes.adminLogin);
                  },
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('دخول مالك التطبيق'),
                ),
              ),
              Center(
                child: TextButton(
                  key: const Key('open-owner-plans'),
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      ServickRoutes.clientSubscription,
                      arguments: const ClientSubscriptionArgs(
                        clientId: demoClientId,
                        isAdmin: true,
                      ),
                    );
                  },
                  child: const Text('معاينة باقة المالك'),
                ),
              ),
              _ClientPlanNote(
                subscription: model.clientSubscription(demoClientId),
              ),
              Center(
                child: TextButton.icon(
                  key: const Key('open-provider-login'),
                  onPressed: () {
                    Navigator.of(context)
                        .pushNamed(ServickRoutes.providerLogin);
                  },
                  icon: const Icon(Icons.engineering_rounded),
                  label: const Text('دخول مزودي الخدمات'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientPlanNote extends StatelessWidget {
  const _ClientPlanNote({required this.subscription});

  final ClientSubscription? subscription;

  @override
  Widget build(BuildContext context) {
    final current = subscription;
    if (current == null || !current.isActiveAt(AppScope.of(context).now)) {
      return const SizedBox.shrink();
    }
    final plan = clientPlanById(current.planId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'باقتك الحالية: ${plan?.title ?? current.planId} حتى ${formatSubscriptionDate(current.expiry)}',
        key: const Key('client-plan-note'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: ServickColors.muted, height: 1.5),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.city,
    required this.columns,
    required this.categories,
  });

  final String city;
  final int columns;
  final List<ServiceCategory> categories;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var index = 0; index < categories.length; index += columns) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var column = 0; column < columns; column++) ...[
                if (column > 0) const SizedBox(width: 14),
                Expanded(
                  child: index + column < categories.length
                      ? CategoryCard(
                          key: Key('category-${categories[index + column].id}'),
                          category: categories[index + column],
                          city: city,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
      if (index + columns < categories.length) {
        rows.add(const SizedBox(height: 14));
      }
    }
    return Column(children: rows);
  }
}

class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner({required this.city});

  final String city;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      key: const Key('open-emergency'),
      onPressed: () {
        Navigator.of(context).pushNamed(ServickRoutes.emergency);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: ServickColors.emergency,
        elevation: 0,
        minimumSize: const Size(0, 48),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      child: const Text('طلب طوارئ'),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ServickColors.emergency, ServickColors.emergencySoft],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'عطل طارئ على الطريق؟',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'اضغط هنا لطلب أقرب فني متاح فوراً',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  city,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            );
            final icon = const DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x29FFFFFF),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            );

            if (constraints.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      icon,
                      const SizedBox(width: 12),
                      Expanded(child: copy),
                    ],
                  ),
                  const SizedBox(height: 14),
                  button,
                ],
              );
            }

            return Row(
              children: [
                icon,
                const SizedBox(width: 16),
                Expanded(child: copy),
                const SizedBox(width: 12),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AvailableStrip extends StatelessWidget {
  const _AvailableStrip({required this.technicians});

  final List<Technician> technicians;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        primary: false,
        scrollDirection: Axis.horizontal,
        itemCount: technicians.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final technician = technicians[index];
          final category = categoryById(technician.categoryId);
          return SizedBox(
            width: 230,
            child: Material(
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: ServickColors.line),
              ),
              child: InkWell(
                key: Key('open-now-${technician.id}'),
                onTap: () {
                  Navigator.of(context).pushNamed(
                    ServickRoutes.technician,
                    arguments: technician.id,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: category.color.withValues(alpha: 0.12),
                        child: Text(
                          initialOf(technician.name),
                          style: TextStyle(
                            color: category.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              technician.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              category.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: ServickColors.muted,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'خلال ${technician.etaMinutes} د',
                              style: TextStyle(
                                color: category.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
