// lib/data/models/category.dart
import 'package:flutter/material.dart';

class ServiceCategory {
  final String id;
  final String key;
  final String name;
  final String icon;
  final int sortOrder;
  final List<String> helperTypes;

  ServiceCategory({
    required this.id,
    required this.key,
    required this.name,
    required this.icon,
    required this.sortOrder,
    required this.helperTypes,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> j) => ServiceCategory(
        id: j['id'],
        key: j['key'],
        name: j['name'],
        icon: j['icon'] ?? 'build',
        sortOrder: j['sort_order'] ?? 0,
        helperTypes: (j['helper_types'] as List? ?? []).map((e) => e.toString()).toList(),
      );

  /// Maps the backend icon identifier to a Material icon.
  IconData get materialIcon {
    switch (icon) {
      case 'tire_repair':
        return Icons.tire_repair;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'fire_truck':
        return Icons.fire_truck;
      case 'battery_charging_full':
        return Icons.battery_charging_full;
      case 'build':
      default:
        return Icons.build;
    }
  }
}
