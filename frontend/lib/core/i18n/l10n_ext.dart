// lib/core/i18n/l10n_ext.dart
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'strings.dart';

/// `context.tr('key')` — reads the active locale and rebuilds on language change.
extension L10nX on BuildContext {
  String tr(String key) => watch<LocaleController>().tr(key);
}
