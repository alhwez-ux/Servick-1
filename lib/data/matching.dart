import '../models/models.dart';

enum TechnicianSort { nearest, rating, availableOnly }

List<Technician> techniciansFor({
  required List<Technician> people,
  required String categoryId,
  required String city,
  TechnicianSort order = TechnicianSort.nearest,
  double Function(Technician technician)? ratingOf,
}) {
  final list = people
      .where(
        (technician) =>
            technician.categoryId == categoryId && technician.city == city,
      )
      .toList();
  double score(Technician technician) =>
      ratingOf?.call(technician) ?? technician.rating;

  switch (order) {
    case TechnicianSort.nearest:
      list.sort((a, b) {
        if (a.available != b.available) {
          return a.available ? -1 : 1;
        }
        final byEta = a.etaMinutes.compareTo(b.etaMinutes);
        if (byEta != 0) return byEta;
        return score(b).compareTo(score(a));
      });
    case TechnicianSort.rating:
      list.sort((a, b) {
        final byRating = score(b).compareTo(score(a));
        if (byRating != 0) return byRating;
        return b.jobs.compareTo(a.jobs);
      });
    case TechnicianSort.availableOnly:
      list.retainWhere((technician) => technician.available);
      list.sort((a, b) => a.etaMinutes.compareTo(b.etaMinutes));
  }
  return list;
}

int technicianCount({
  required List<Technician> people,
  required String categoryId,
  required String city,
  bool availableOnly = false,
}) {
  return people
      .where(
        (technician) =>
            technician.categoryId == categoryId &&
            technician.city == city &&
            (!availableOnly || technician.available),
      )
      .length;
}

List<Technician> availableInCity(List<Technician> people, String city) {
  final list =
      people
          .where(
            (technician) => technician.city == city && technician.available,
          )
          .toList()
        ..sort((a, b) {
          final byEta = a.etaMinutes.compareTo(b.etaMinutes);
          if (byEta != 0) return byEta;
          return b.rating.compareTo(a.rating);
        });
  return list;
}

Technician? nearestAvailable({
  required List<Technician> people,
  required String city,
  required List<String> categoryIds,
}) {
  final pool =
      people
          .where(
            (technician) =>
                technician.city == city &&
                technician.available &&
                categoryIds.contains(technician.categoryId),
          )
          .toList()
        ..sort((a, b) {
          final byEta = a.etaMinutes.compareTo(b.etaMinutes);
          if (byEta != 0) return byEta;
          return b.rating.compareTo(a.rating);
        });
  if (pool.isEmpty) return null;
  return pool.first;
}

List<({String city, int count})> otherCitiesWithTechnicians({
  required List<Technician> people,
  required String categoryId,
  required String currentCity,
}) {
  return [
    for (final city in cities)
      if (city != currentCity)
        (
          city: city,
          count: technicianCount(
            people: people,
            categoryId: categoryId,
            city: city,
          ),
        ),
  ].where((entry) => entry.count > 0).toList();
}
