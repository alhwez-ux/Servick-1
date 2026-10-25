import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/models.dart';
import '../routes.dart';
import '../theme/servick_theme.dart';
import 'service_artwork.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.category, required this.city});

  final ServiceCategory category;
  final String city;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final total = model.technicianCount(categoryId: category.id, city: city);
    final open = model.technicianCount(
      categoryId: category.id,
      city: city,
      availableOnly: true,
    );
    final line = total == 0
        ? 'غير متوفر في $city'
        : open == 0
        ? 'مسجّلون لكنهم مشغولون'
        : '$open متاح في $city';
    final lineColor = open == 0 ? ServickColors.muted : ServickColors.success;

    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Color(0x141E3A8A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ServickColors.line),
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context)
                .pushNamed(ServickRoutes.technicians, arguments: category.id);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),
              Center(
                child: ServiceArtwork(
                  category: category,
                  height: 84,
                  borderRadius: 42,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                child: Column(
                  children: [
                    Text(
                      category.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ServickColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: ServickColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      line,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: lineColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
