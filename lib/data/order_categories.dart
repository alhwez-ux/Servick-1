import 'package:flutter/material.dart';

class OrderCategory {
  const OrderCategory({
    required this.id,
    required this.title,
    required this.icon,
  });

  final String id;
  final String title;
  final IconData icon;
}

const orderCategories = <OrderCategory>[
  OrderCategory(
    id: 'benz_mech',
    title: 'ميكانيكي سيارات بنزين',
    icon: Icons.local_gas_station,
  ),
  OrderCategory(
    id: 'diesel_mech',
    title: 'ميكانيكي سيارات ديزل',
    icon: Icons.car_repair,
  ),
  OrderCategory(
    id: 'chinese_mech',
    title: 'ميكانيكي سيارات صينية',
    icon: Icons.directions_car,
  ),
  OrderCategory(
    id: 'equipment_mech',
    title: 'ميكانيكي معدات',
    icon: Icons.engineering,
  ),
  OrderCategory(id: 'car_electric', title: 'كهربائي سيارات', icon: Icons.bolt),
  OrderCategory(
    id: 'home_electric',
    title: 'كهربائي منازل',
    icon: Icons.electrical_services,
  ),
];

OrderCategory? orderCategoryById(String id) {
  for (final category in orderCategories) {
    if (category.id == id) return category;
  }
  return null;
}
