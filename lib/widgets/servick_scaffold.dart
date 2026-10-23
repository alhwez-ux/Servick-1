import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/models.dart';
import '../routes.dart';
import '../theme/servick_theme.dart';

class ServickFrame extends StatelessWidget {
  const ServickFrame({super.key, required this.child, this.maxWidth = 1080});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > maxWidth
            ? maxWidth
            : constraints.maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: constraints.maxHeight,
            child: child,
          ),
        );
      },
    );
  }
}

class ServickBrand extends StatelessWidget {
  const ServickBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('سيرفيسك'),
        SizedBox(width: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: ServickColors.amber,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Text(
              'Servick',
              style: TextStyle(
                color: ServickColors.navy,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CityPickerBar extends StatelessWidget implements PreferredSizeWidget {
  const CityPickerBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: ServickColors.amber, size: 20),
          const SizedBox(width: 8),
          const Text(
            'المدينة',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
          const Spacer(),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: const Key('city-dropdown'),
                  value: model.city,
                  isDense: true,
                  borderRadius: BorderRadius.circular(12),
                  dropdownColor: ServickColors.navy,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: ServickColors.amber,
                  ),
                  items: [
                    for (final city in cities)
                      DropdownMenuItem<String>(
                        value: city,
                        child: Text(
                          city,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) model.setCity(value);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ServickScaffold extends StatelessWidget {
  const ServickScaffold({
    super.key,
    required this.body,
    this.title,
    this.brand = false,
    this.showCity = true,
    this.showRequests = true,
    this.bottom,
  }) : assert(brand || title != null);

  final Widget body;
  final String? title;
  final bool brand;
  final bool showCity;
  final bool showRequests;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final count = AppScope.of(context).requests.length;
    return Scaffold(
      appBar: AppBar(
        title: brand ? const ServickBrand() : Text(title!),
        actions: [
          if (showRequests)
            IconButton(
              tooltip: 'طلباتي',
              onPressed: () {
                Navigator.of(context).pushNamed(ServickRoutes.requests);
              },
              icon: Badge(
                isLabelVisible: count > 0,
                backgroundColor: ServickColors.amber,
                textColor: ServickColors.navy,
                label: Text('$count'),
                child: const Icon(Icons.receipt_long),
              ),
            ),
        ],
        bottom: showCity ? const CityPickerBar() : null,
      ),
      body: body,
      bottomNavigationBar: bottom,
    );
  }
}
