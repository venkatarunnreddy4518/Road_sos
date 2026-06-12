import 'package:flutter/material.dart';
import 'package:roadside_help/core/i18n/l10n_ext.dart';
import 'package:roadside_help/domain/entities/helper.dart';

String helperTypeTitle(BuildContext context, HelperType type) {
  return switch (type) {
    HelperType.PUNCTURE_SHOP => context.tr('type_tyre_repair'),
    HelperType.PETROL_PUMP => context.tr('type_fuel_delivery'),
    HelperType.MECHANIC => context.tr('type_mechanic'),
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
    HelperType.PUNCTURE_SHOP => const Color(0xFF111111),
    HelperType.PETROL_PUMP => const Color(0xFF555555),
    HelperType.MECHANIC => const Color(0xFF888888),
  };
}
