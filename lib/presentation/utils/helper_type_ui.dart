import 'package:flutter/material.dart';
import 'package:roadside_help/domain/entities/helper.dart';

String helperTypeTitle(HelperType type) {
  return switch (type) {
    HelperType.PUNCTURE_SHOP => 'Tyre repair',
    HelperType.PETROL_PUMP => 'Fuel delivery',
    HelperType.MECHANIC => 'Mechanic',
  };
}

IconData helperTypeIcon(HelperType type) {
  return switch (type) {
    HelperType.PUNCTURE_SHOP => Icons.tire_repair,
    HelperType.PETROL_PUMP => Icons.local_gas_station,
    HelperType.MECHANIC => Icons.build,
  };
}

Color helperTypeColor(HelperType type) {
  return switch (type) {
    HelperType.PUNCTURE_SHOP => const Color(0xFFF4C430),
    HelperType.PETROL_PUMP => const Color(0xFF18A957),
    HelperType.MECHANIC => const Color(0xFF2C6BED),
  };
}
