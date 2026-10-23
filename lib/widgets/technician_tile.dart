import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/catalog.dart';
import '../data/format.dart';
import '../models/models.dart';
import '../routes.dart';
import '../theme/servick_theme.dart';
import 'common.dart';

class TechnicianTile extends StatelessWidget {
  const TechnicianTile({
    super.key,
    required this.technician,
    this.openProfile = true,
  });

  final Technician technician;
  final bool openProfile;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final category = categoryById(technician.categoryId);
    final rating = model.displayRating(technician);
    final jobs = model.displayJobs(technician);
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ServickColors.line),
      ),
      child: InkWell(
        onTap: openProfile
            ? () {
                Navigator.of(
                  context,
                ).pushNamed(ServickRoutes.technician, arguments: technician.id);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: category.color.withValues(alpha: 0.12),
                child: Text(
                  initialOf(technician.name),
                  style: TextStyle(
                    color: category.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            technician.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(
                          label: technician.available ? 'متاح' : 'مشغول',
                          color: technician.available
                              ? ServickColors.success
                              : ServickColors.waiting,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.title,
                      style: const TextStyle(
                        color: ServickColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Meta(
                          icon: Icons.star_rounded,
                          label: rating.toStringAsFixed(1),
                          color: ServickColors.amber,
                        ),
                        _Meta(label: '$jobs طلب'),
                        _Meta(label: 'خلال ${technician.etaMinutes} د'),
                        _Meta(
                          label: 'من ${model.startingPriceOf(technician)} ر.س',
                        ),
                      ],
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

class _Meta extends StatelessWidget {
  const _Meta({required this.label, this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: color ?? ServickColors.muted),
          const SizedBox(width: 2),
        ],
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: ServickColors.muted),
        ),
      ],
    );
  }
}
