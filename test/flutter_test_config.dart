// test/flutter_test_config.dart
//
// Auto-loaded by `flutter test`. Initializes an in-memory sqflite implementation
// (FFI) so repositories that use sqflite (legacy offline cache) work in the
// headless test environment without a device.
import 'dart:async';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await testMain();
}
