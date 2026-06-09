// lib/core/i18n/app_localization.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalization {
  // This is a mock of how localization would be handled.
  // In a real project, this would be generated from .arb files using flutter_gen.

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'problem_puncture': 'Puncture / Flat Tyre',
      'problem_fuel': 'Out of Fuel',
      'problem_breakdown': 'Breakdown',
      'nearest_helpers': 'Nearest Helpers',
      'call_now': 'Call Now',
      'directions': 'Directions',
      'far_away': 'Far Away',
      'hours_unknown': 'Hours Unknown',
      'last_updated': 'Last updated: {time}',
    },
    'hi': {
      'problem_puncture': 'पंचर / टायर फ्लैट',
      'problem_fuel': 'ईंधन खत्म',
      'problem_breakdown': 'ब्रेकडाउन',
      'nearest_helpers': 'निकटतम सहायक',
      'call_now': 'अभी कॉल करें',
      'directions': 'दिशा-निर्देश',
      'far_away': 'बहुत दूर',
      'hours_unknown': 'समय अज्ञात',
      'last_updated': 'अंतिम अपडेट: {time}',
    },
  };

  static String translate(String key, String locale) {
    return _localizedValues[locale]?[key] ?? key;
  }
}
