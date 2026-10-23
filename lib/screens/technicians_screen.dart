import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/catalog.dart';
import '../data/matching.dart';
import '../models/models.dart';
import '../theme/servick_theme.dart';
import '../widgets/servick_scaffold.dart';
import '../widgets/technician_tile.dart';

class TechniciansScreen extends StatefulWidget {
  const TechniciansScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<TechniciansScreen> createState() => _TechniciansScreenState();
}

class _TechniciansScreenState extends State<TechniciansScreen> {
  TechnicianSort _order = TechnicianSort.nearest;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final category = categoryById(widget.categoryId);
    final people = techniciansFor(
      categoryId: category.id,
      city: model.city,
      order: _order,
    );
    final registered = technicianCount(
      categoryId: category.id,
      city: model.city,
    );
    final open = technicianCount(
      categoryId: category.id,
      city: model.city,
      availableOnly: true,
    );

    return ServickScaffold(
      title: category.title,
      body: ServickFrame(
        maxWidth: 760,
        child: ListView(
          key: const Key('technicians-list'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _CategoryIntro(
              category: category,
              city: model.city,
              open: open,
              registered: registered,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SortChip(
                  label: 'الأقرب',
                  selected: _order == TechnicianSort.nearest,
                  onSelected: () =>
                      setState(() => _order = TechnicianSort.nearest),
                ),
                _SortChip(
                  label: 'التقييم',
                  selected: _order == TechnicianSort.rating,
                  onSelected: () =>
                      setState(() => _order = TechnicianSort.rating),
                ),
                _SortChip(
                  label: 'المتاح',
                  selected: _order == TechnicianSort.availableOnly,
                  onSelected: () =>
                      setState(() => _order = TechnicianSort.availableOnly),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (people.isEmpty)
              _EmptyTechnicians(
                category: category,
                city: model.city,
                busyOnly:
                    registered > 0 && _order == TechnicianSort.availableOnly,
                onShowAll: () =>
                    setState(() => _order = TechnicianSort.nearest),
              )
            else
              for (final technician in people) ...[
                TechnicianTile(
                  key: Key('tech-${technician.id}'),
                  technician: technician,
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _CategoryIntro extends StatelessWidget {
  const _CategoryIntro({
    required this.category,
    required this.city,
    required this.open,
    required this.registered,
  });

  final ServiceCategory category;
  final String city;
  final int open;
  final int registered;

  @override
  Widget build(BuildContext context) {
    final countLine = registered == 0
        ? 'لا يوجد فنيون مسجّلون في $city'
        : '$open متاح من $registered في $city';
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ServickColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: category.color.withValues(alpha: 0.12),
              child: Icon(category.icon, color: category.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.subtitle),
                  const SizedBox(height: 4),
                  Text(
                    countLine,
                    style: const TextStyle(
                      color: ServickColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: ServickColors.navy,
      labelStyle: TextStyle(
        color: selected ? Colors.white : ServickColors.ink,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}

class _EmptyTechnicians extends StatelessWidget {
  const _EmptyTechnicians({
    required this.category,
    required this.city,
    required this.busyOnly,
    required this.onShowAll,
  });

  final ServiceCategory category;
  final String city;
  final bool busyOnly;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final others = otherCitiesWithTechnicians(
      categoryId: category.id,
      currentCity: city,
    );

    return Padding(
      key: const Key('empty-technicians'),
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 42, color: ServickColors.muted),
          const SizedBox(height: 12),
          Text(
            busyOnly
                ? 'الفنيون المسجّلون في $city مشغولون الآن.'
                : 'لا يوجد فنيون لخدمة ${category.title} في $city.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (busyOnly)
            TextButton(
              onPressed: onShowAll,
              child: const Text('عرض كل الفنيين'),
            )
          else if (others.isNotEmpty) ...[
            const Text(
              'الخدمة متوفرة في:',
              style: TextStyle(color: ServickColors.muted),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final entry in others)
                  ActionChip(
                    label: Text('${entry.city} (${entry.count})'),
                    onPressed: () => model.setCity(entry.city),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
