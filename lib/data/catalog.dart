import 'package:flutter/material.dart';

import '../models/models.dart';

const categories = <ServiceCategory>[
  ServiceCategory(
    id: 'petrol',
    title: 'ميكانيكي بنزين',
    subtitle: 'محركات البنزين والصيانة الدورية',
    icon: Icons.local_gas_station,
    color: Color(0xFF2563EB),
  ),
  ServiceCategory(
    id: 'diesel',
    title: 'ميكانيكي ديزل',
    subtitle: 'ديزل خفيف وشاصات',
    icon: Icons.car_repair,
    color: Color(0xFFEA580C),
  ),
  ServiceCategory(
    id: 'chinese',
    title: 'ميكانيكي صيني',
    subtitle: 'شانجان، جيلي، ام جي، وشيري',
    icon: Icons.directions_car,
    color: Color(0xFF0F766E),
  ),
  ServiceCategory(
    id: 'equipment',
    title: 'ميكانيكي معدات',
    subtitle: 'مولدات ومعدات المواقع',
    icon: Icons.engineering,
    color: Color(0xFFB45309),
  ),
  ServiceCategory(
    id: 'auto_elec',
    title: 'كهربائي سيارات',
    subtitle: 'بطارية ودينمو وأنظمة التشغيل',
    icon: Icons.bolt,
    color: Color(0xFFDC2626),
  ),
  ServiceCategory(
    id: 'home_elec',
    title: 'كهربائي منازل',
    subtitle: 'قواطع وإضاءة وأعطال البيوت',
    icon: Icons.electrical_services,
    color: Color(0xFF4338CA),
  ),
];

const roadsideIssues = <RoadsideIssue>[
  RoadsideIssue(
    id: 'stall',
    label: 'السيارة لا تعمل',
    icon: Icons.car_repair,
    categoryIds: ['petrol', 'diesel', 'chinese'],
  ),
  RoadsideIssue(
    id: 'battery',
    label: 'بطارية',
    icon: Icons.battery_alert,
    categoryIds: ['auto_elec', 'petrol'],
  ),
  RoadsideIssue(
    id: 'tire',
    label: 'إطار مثقوب',
    icon: Icons.trip_origin,
    categoryIds: ['petrol', 'diesel'],
  ),
  RoadsideIssue(
    id: 'heat',
    label: 'حرارة المحرك',
    icon: Icons.local_fire_department,
    categoryIds: ['petrol', 'diesel'],
  ),
  RoadsideIssue(
    id: 'electrical',
    label: 'عطل كهربائي',
    icon: Icons.bolt,
    categoryIds: ['auto_elec'],
  ),
  RoadsideIssue(
    id: 'other',
    label: 'عطل آخر على الطريق',
    icon: Icons.more_horiz,
    categoryIds: ['petrol', 'diesel', 'chinese', 'auto_elec'],
  ),
];

Technician? lookupTechnician(String? id, List<Technician> people) {
  if (id == null) return null;
  for (final technician in people) {
    if (technician.id == id) return technician;
  }
  return null;
}

ServiceCategory categoryById(String id) {
  return categories.firstWhere((category) => category.id == id);
}

RoadsideIssue issueById(String id) {
  return roadsideIssues.firstWhere((issue) => issue.id == id);
}
