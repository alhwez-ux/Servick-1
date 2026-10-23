import 'package:flutter/material.dart';

import '../data/matching.dart';
import '../models/models.dart';
import '../routes.dart';
import '../theme/servick_theme.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.category, required this.city});

  final ServiceCategory category;
  final String city;

  @override
  Widget build(BuildContext context) {
    final total = technicianCount(categoryId: category.id, city: city);
    final open = technicianCount(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: category.color.withValues(alpha: 0.12),
                  child: Icon(category.icon, size: 30, color: category.color),
                ),
                const SizedBox(height: 10),
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
        ),
      ),
    );
  }
}
